function  [spik_lists_all,used_analysis_parameters,all_electrode_names]=generateSLfromRawNlxData_BackgroundNoise(IC,threshold,pre_time,post_time,ref_time,...
    low_filt,high_filt,filt_ord,prestimrectime,poststimrectime,use_artefact_removal)
% icme/generateSLfromRawNlxData extracts the multiunit activity from the NLX raw data
% can be run on a computer with parallel cores, detailed description of
% process missing
% input:
%   IC (ICME) IC recording to be analysed
%   optional:
%       threshold; double (default 3) to adjust spike threshold
%       pre_time; post_time;  % waveform-window around a detected spike [ms]
%       ref_time;    % refractory period [ms]
%       low_filt, high_filt;filt_ord; % bandpass filter properties in beginning of data processing
%       prestimrectime; poststimrectime % time around trigger that spikes
%           are extracted from [ms]
%       use_artefact_removal (bool) if stimuli deteected over all electrodes 
%           simultaneously should get removed as artefact default true
% output:
%   spik_list_all (struct with fields named after each electrode containing
%       the Spik_list for each of these electrodes. Spik_list has for each
%           detected spike one row with the collumns  (1 stim, 2 n_rep, 3 ypos ( (stim-1)+1/max(Header.n_rep)*n_rep for easier raster plot generation 4
%       chan 5 unit ID (only with spike sorting so not implemented) 6 time after trigger
% used_analysis_parameters (struct) used analysis parameters including
%       threshold; % treshold [V?] to detect multiunit activity as spike
%       pre_time; post_time;  % waveform-window around a detected spike
%       ref_time;    % refractory period [ms]?
%       low_filt, high_filt;filt_ord; %bandpass filter in beginning of data processing
%       prestimrectime; poststimrectime % time around trigger that spikes are
%       extracteed
%       num_removed_spikes: number of spieks removed in artefact removal
% all_electrode_names (struct with names elec0 -elec31 )

% EK 04.02.2025: changes compared to old spike extraction: 
%   refactory time removed since mutliunit activity
%   Used only the 100 ms before trigger for threshold estimation not the
%   whole data

%% initialize sorting parameters
if nargin==1
    threshold = 3.5; % threshold for waveform extraction (in MAD)
    pre_time = 0.5;
    post_time = 1; % waveform-window
    ref_time = 0; % refractory period
    low_filt = 600;
    high_filt = 6000;
    filt_ord = 4; % filter settings
    % time in ms around trigger that the spikes are extracted
    prestimrectime = 150;
    poststimrectime= 150;
    use_artefact_removal=1;
end

% %% get stimulation info and raw data files
% mFileData=IC.ExpInfo;
%  % currently MX_tones and f_trains gives the dura in s not ms this line fixes it
% if strcmp(mFileData.exp_type,'MX_tones')||strcmp(mFileData.exp_type,'OBIS_LS594_PulseTrain_f_train')
%     mFileData.dura=mFileData.dura*1000;
% end
%
% poststimrectime=max(mFileData.dura)+50; % always anaylse up to 50 ms after the end of the longest stimulus
% prestimrectime = poststimrectime; % to allow for baseline comparison with
% spikerate before trigger



% find the raw data files
p_dat =   IC.ExpInfo.RawDataFolder{1}(strfind( IC.ExpInfo.RawDataFolder{1}, IC.ExpInfo.animal_ID)+length(IC.ExpInfo.animal_ID)+1:end);
rawFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat, '*.ncs'));
% infoFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat, 'CheetahLostADRecords.txt'));
% spikeFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat,'*.nse'));
eventFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat,'*.nev'));
% get event info
filename_evt = fullfile(eventFiles.folder,eventFiles.name);
[evt.TimeStamps, evt.EventIDs, evt.TTLs, evt.Extras, evt.EventStrings] = ...
    Nlx2MatEV(filename_evt, [1 1 1 1 1], 0, 1, 0 );

%% prepare the basic stim_list
% convert event info and create a stim_list
stim_Idx = find(cellfun(@(x) contains(x, 'Trial = '), evt.EventStrings, 'UniformOutput', true));
stim_names = unique(evt.TTLs(stim_Idx)');
n_stim = length(stim_names); 
% n_pres = length(stim_Idx);
stim_list = evt.TTLs(stim_Idx)'; stim_list(:,2) = NaN;
stim_n_rep = zeros(n_stim,1);
for iUnStim = stim_names'
    iCurStim = find(stim_list(:,1) == iUnStim);
    stim_list(iCurStim,2) = 1:length(iCurStim);
    stim_n_rep(stim_names == iUnStim) = length(iCurStim);
end

% here we have following variables:
% stim_names and n_stim the individual StimulusIDs and the total number
% stim_list is an n_Stim*n_repx2 double with stim_list(:,1) being the order
% in which the stim_IDs were presented and stim_list(:,1) being the
% rep. of the presentation
% stim_n_rep the numebr of repetitions each individual stimulus has
% been represented

%% match the trial numbers to the stimulus IDs
% list of timestamps of stimuli
try
    tts = evt.TimeStamps(stim_Idx+1); % this assumes that the next event posted is the actual trigger
catch
    tts = evt.TimeStamps(stim_Idx);
end
Trigger.NrTrigger = length(tts); % number of recorded triggers
Trigger.TrigBeginTime = tts; %within each stimulus
Trigger.stim_list = stim_list;
Trigger.stim_n_rep = stim_n_rep;
Trigger.stim_names = stim_names;
Trigger.n_stim = n_stim;


%% load the raw data into the channel structure

for idx_channel = 1:size(rawFiles, 1)
    cur_channel = rawFiles(idx_channel).name;
    cur_channelname = char(fullfile(gen_dir_name(IC.D.dir), p_dat, cur_channel));
    [channel(idx_channel).data.Timestamps, channel(idx_channel).data.ChannelNumbers, channel(idx_channel).data.SampleFrequencies, channel(idx_channel).data.NumberOfValidSamples, channel(idx_channel).data.Samples, channel(idx_channel).data.Header] = ...
        Nlx2MatCSC(cur_channelname,[1 1 1 1 1], 1, 1, []);
    fprintf('channel data loaded for %i \n',idx_channel)
end

parfor idx_channel = 1: size(rawFiles, 1)
  
    % start event extraction
    strToFind = '-DspFilterDelay';
    filedIndexUTF8 =  find(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true));
    channel(idx_channel).data.Header(filedIndexUTF8) = strrep(channel(idx_channel).data.Header(filedIndexUTF8), '�s', 'μs'); % Replace '�s' with 'μs' to ensure cross matlab version functionality
    DspDelay = 0; 
    strToFind = '-DspDelayCompensation Disabled';
    if  ~isempty(find(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)))
        strToFind = '-DspFilterDelay_µs '; 
        DspDelay = str2num(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')))/10^6; % delay in seconds
    end

    strToFind = '-ADBitVolts';
    ADBitVolts = str2num(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')));

    strToFind = '-InputInverted '; InputInversion = 1;
    if isequal(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')), 'True')
        InputInversion = -1;
    end

    ADBitVolts = ADBitVolts * InputInversion;

    % define size wveform window in datapoints
    samples_pre = (pre_time*channel(idx_channel).data.SampleFrequencies(1))/1000;
    samples_post = (post_time*channel(idx_channel).data.SampleFrequencies(1))/1000;
    samples_ref = (ref_time*channel(idx_channel).data.SampleFrequencies(1))/1000;

  
    
    % band pass filter
    datafilt = [];
    datafilt = bandfilt(channel(idx_channel).data.Samples(:), low_filt, high_filt, channel(idx_channel).data.SampleFrequencies(1), filt_ord )*ADBitVolts;
    
        % align data timepoints and trigger timepoints in actual
        % ms/timedomain, there are sometimes pauses between aquired data
%     time_vec_data1=(1/32000:1/32000:(size(datafilt,1))*1/32000);%/1e6;
    num_data_chunks=length(channel(idx_channel).data.Timestamps);
    sample_freq=channel(idx_channel).data.SampleFrequencies(1);
    time_vec_data=zeros(size(datafilt))';
    ix_in_vector=1;
    for datachunk_ix=1:num_data_chunks
        cur_start_time=(channel(idx_channel).data.Timestamps(datachunk_ix)-channel(idx_channel).data.Timestamps(1))/1e6;
        cur_time_vector=(cur_start_time:1/32000:cur_start_time+(512-1)*1/32000);
        time_vec_data(ix_in_vector:ix_in_vector+512-1)=cur_time_vector;
       ix_in_vector=ix_in_vector+512;
    end

    trigger_time_seconds_aligned=(Trigger.TrigBeginTime-channel(idx_channel).data.Timestamps(1))/1e6;
%     timepoints_baseline=[trigger_time_seconds_aligned-0.1;trigger_time_seconds_aligned];
    
    num_samples_baseline=channel(idx_channel).data.SampleFrequencies(1)*0.098; % pick -100 ms to -2 ms before trigger for baseline
    num_samples_beforeTrigger=channel(idx_channel).data.SampleFrequencies(1)*0.002;
    baseline_datafilt= zeros(num_samples_baseline*(length(trigger_time_seconds_aligned)+1),1);
%     baseline_timevec= zeros(num_samples_baseline*(length(trigger_time_seconds_aligned)+1),1);
    ix_helper=1;
    trigger_indices = interp1(time_vec_data, 1:length(time_vec_data),trigger_time_seconds_aligned, 'nearest');
    % Loop over each element in trigger_time_seconds_aligned
    for i = 1:length(trigger_time_seconds_aligned)
        % trigger timepoint
        idx_trigger=trigger_indices(i)-num_samples_beforeTrigger; % go 2 ms before trigger to avoid any stimultation artefacts
%         if ~isnan(idx_trigger)
             baseline_datafilt(ix_helper:ix_helper+num_samples_baseline)=datafilt(idx_trigger-num_samples_baseline:idx_trigger);
%         end
             %         baseline_timevec(ix_helper:ix_helper+num_samples_baseline)=time_vec_data(1,idx_trigger-num_samples_baseline:idx_trigger);
        ix_helper=ix_helper+num_samples_baseline+1;
    end

  
  
    % noise estimate to decide if there is a MUA Dieter2019 way
    MAD_noise_estimate = median(abs(baseline_datafilt-mean(baseline_datafilt)))/0.675;
    waveform_threshold_low = mean(baseline_datafilt)-threshold*MAD_noise_estimate;
    channel(idx_channel).waveform_threshold_low=waveform_threshold_low;

    % Sabesan & Lesica 2023 method: 
    % (1) a bandpass filter was applied with cutoff frequencies of 700 and 5000 Hz; 
    % (2) the standard deviation of the background noise in the bandpass-filtered signal
    % was estimated as the median absolute deviation/0.6745 (this estimate is more robust
    % to outlier values, e.g., neural spikes, than direct calculation); 
    % (3) times at which the bandpass-filtered signal made a positive 
    % crossing of a threshold of 3.5 standard deviations were identified 
    % and grouped into bins with a width of 1.3 ms.

    if waveform_threshold_low > 0
        i_thresh = 1;
    elseif waveform_threshold_low < 0
        i_thresh = -1;
    end
    wave_idcs = find(i_thresh.*datafilt(1:end-1) < i_thresh*waveform_threshold_low & i_thresh.*datafilt(2:end) > i_thresh*waveform_threshold_low);
    wave_idcs = wave_idcs(diff(wave_idcs, 1, 1) > samples_ref); % Difference must be bigger than samples_ref
    wave_idcs = wave_idcs(wave_idcs > samples_pre); %Must be after samples pre 0.5ms
    wave_idcs = wave_idcs(wave_idcs < numel(datafilt)-(samples_post+1)); %Must be after samples pre 0.5ms
    channel(idx_channel).wave_windows(1, :) = wave_idcs-samples_pre;
    channel(idx_channel).wave_windows(2, :) = wave_idcs+samples_post;

    num_samples_wave=(samples_pre+samples_post+1);
    waveforms=zeros(num_samples_wave,length(channel(idx_channel).wave_windows));
    for wave_ix=1:length(channel(idx_channel).wave_windows)
        waveforms(:,wave_ix)=datafilt(channel(idx_channel).wave_windows(1,wave_ix):channel(idx_channel).wave_windows(2,wave_ix));
    end
    channel(idx_channel).waveforms = waveforms;
    [maxval, maxloc] = max(i_thresh.*channel(idx_channel).waveforms); % location changes from threshold crossing point to peak after threshold
    %        maxval is peak voltage (V) detected for each waveform, maxloc is the
    %        id

    % remove large nosie in data by filtering responses 4*above threshold
%     noise_ixs=find(maxval>i_thresh*waveform_threshold_low*4);
%     wave_idcs(noise_ixs)=[];
%     maxloc(noise_ixs)=[];

    % align  waveforms by peak
    wave_idcs_aligned = wave_idcs+((maxloc-samples_pre))'; % align waves by peak
%     channel(idx_channel).wave_windows_aligned(1, :) = wave_idcs_aligned-samples_pre;
%     channel(idx_channel).wave_windows_aligned(2, :) = wave_idcs_aligned+samples_post;
%     waveformsAlligned=zeros(num_samples_wave,length(channel(idx_channel).wave_windows));
%     for wave_ix=1:length(channel(idx_channel).wave_windows)
%         waveformsAlligned(:,wave_ix)=datafilt(channel(idx_channel).wave_windows_aligned(1,wave_ix):channel(idx_channel).wave_windows_aligned(2,wave_ix));
%     end
%     channel(idx_channel).waveformsAlligned = waveformsAlligned;
    channels_full = repmat(channel(idx_channel).data.ChannelNumbers, 512, 1); %what is  512, the size of how data gets stored in neuralynx
    channels_full = channels_full(:);
    channels = channels_full(wave_idcs_aligned);
    ChunkIdxOfWave     = ceil(wave_idcs_aligned'/ 512); % For correct timestamping only first 512 are timestamped and because some will not have timestamp but be corrected by modulo (rest)
    remWaveIdcsInChunk = mod(wave_idcs_aligned'-1,512);
    DetectTimes        = channel(idx_channel).data.Timestamps(1,ChunkIdxOfWave)/10^6+(remWaveIdcsInChunk)./channel(idx_channel).data.SampleFrequencies(1,ChunkIdxOfWave) - DspDelay;
    DetectTimes_seconds=time_vec_data(wave_idcs_aligned);%(DetectTimes-DetectTimes(1))*1/32000;


     %% save detected APs in channel structure
    channel(idx_channel).DetectTimes=DetectTimes;
    channel(idx_channel).DetectTimes_seconds=DetectTimes_seconds;
    channel(idx_channel).channels=channels;
    channel(idx_channel).wave_idcs_aligned=wave_idcs_aligned;
%     channel(idx_channel).datafilt=datafilt;
    channel(idx_channel).MAD_noise_estimate=MAD_noise_estimate;
    channel(idx_channel).trigger_time_seconds_aligned=trigger_time_seconds_aligned;

    disp([num2str(idx_channel), '/' num2str(size(rawFiles, 1)) ' detection done'])
    
end


%% remove artefacts 
num_removed_spikes=0;
if use_artefact_removal==1
    % based on spikes that appear over all electrodes
    % simultanously
    % find comon indices
    if size(rawFiles, 1)>1
        % find common timepoints
        precision=4;%0.1 ms 
        time_vec1=round(channel(1).DetectTimes_seconds,precision);
        time_vec2=round(channel(2).DetectTimes_seconds,precision);
        common_timepoints=intersect(time_vec1,time_vec2);
        if size(rawFiles, 1)>2
            for i = 3:size(rawFiles, 1)
               common_timepoints=intersect(common_timepoints,round(channel(i).DetectTimes_seconds,precision));
            end     
        end
        %
        fprintf('removing %i simultaneous spikes\n',length(common_timepoints))
        num_removed_spikes=num_removed_spikes+length(common_timepoints);
        % remove entries
        for i =1: size(rawFiles, 1) 
            idcs_spikes_to_exclude=ismember(round(channel(i).DetectTimes_seconds,precision),common_timepoints);
            channel(i).channels=channel(i).channels(~idcs_spikes_to_exclude);
            channel(i).DetectTimes=channel(i).DetectTimes(~idcs_spikes_to_exclude);
            channel(i).wave_idcs_aligned = channel(i).wave_idcs_aligned(~idcs_spikes_to_exclude);
            channel(i).waveforms    = channel(i).waveforms(:,~idcs_spikes_to_exclude);
    %         channel(i).waveformsAlligned = channel(i).waveformsAlligned(:,~idcs_spikes_to_exclude);
            channel(i).DetectTimes_seconds=channel(i).DetectTimes_seconds(~idcs_spikes_to_exclude);
        end
    end
    % sort out with a higher margin of error around the trigger (+- 2 ms
    if size(rawFiles, 1)>1
        % find common timepoints
        precision=3;%0.1 ms 
        time_vec1=round(channel(1).DetectTimes_seconds,precision);
        time_vec2=round(channel(2).DetectTimes_seconds,precision);
        common_timepoints=intersect(time_vec1,time_vec2);
        if size(rawFiles, 1) >2
            for i = 3:size(rawFiles, 1)
               common_timepoints=intersect(common_timepoints,round(channel(i).DetectTimes_seconds,precision));
            end     
        end
        % kick out all timepoints that are not round the trigger, not yet
        % working
        tolerance = 2e-3;  % 2 ms
        diff_matrix = repmat(common_timepoints,length(channel(1).trigger_time_seconds_aligned),1) - repmat(channel(1).trigger_time_seconds_aligned, length(common_timepoints), 1)';
        common_timepoints=common_timepoints((any(abs(diff_matrix) < tolerance)));
    
        fprintf('removing %i simultaneous spikes\n',length(common_timepoints))
        num_removed_spikes=num_removed_spikes+length(common_timepoints);

        % remove entries
         for i =1: size(rawFiles, 1) 
            idcs_spikes_to_exclude=ismember(round(channel(i).DetectTimes_seconds,precision),common_timepoints);
            channel(i).channels=channel(i).channels(~idcs_spikes_to_exclude);
            channel(i).DetectTimes=channel(i).DetectTimes(~idcs_spikes_to_exclude);
            channel(i).wave_idcs_aligned = channel(i).wave_idcs_aligned(~idcs_spikes_to_exclude);
            channel(i).waveforms    = channel(i).waveforms(:,~idcs_spikes_to_exclude);
    %         channel(i).waveformsAlligned = channel(i).waveformsAlligned(:,~idcs_spikes_to_exclude);
            channel(i).DetectTimes_seconds=channel(i).DetectTimes_seconds(~idcs_spikes_to_exclude);
        end
    end
    
end %artefact removal


%% get APS 
% values before loop
n_pres =  Trigger.NrTrigger; stim_list = Trigger.stim_list; stim_n_rep = Trigger.stim_n_rep;
t_pre = (prestimrectime/1000);
dur = t_pre+(poststimrectime/1000);
parfor idx_channel = 1: size(rawFiles, 1) 
    
    % get detected times for this channel
    DetectTimes=channel(idx_channel).DetectTimes;
    channels=channel(idx_channel).channels;

%     wave_idcs_aligned=channel(idx_channel).wave_idcs_aligned;
%     datafilt=channel(idx_channel).datafilt;
%     MAD_noise_estimate=channel(idx_channel).MAD_noise_estimate;

    %% start going through all stimulus presentations and collect APs
    AP  = [];
    
    for r = 1 : n_pres
        % get time window for this trigger presentation
        t1 = Trigger.TrigBeginTime(r)-t_pre*10^6;
        t2 = t1 + dur*10^6;
        spik_ind     = find(DetectTimes(:)*10^6 >= t1 & DetectTimes(:)*10^6 <= t2); % find all detected spikes in this timeframe

        n_spik_ind   = length(spik_ind);
        dummy_spik   = [];
        if ~isempty(n_spik_ind)
            %                 dummy_spik   = [repmat([r, stim_list(r,1)],[n_spik_ind,1]), channels(spik_ind), zeros(size(spik_ind)), DetectTimes(spik_ind)',...
            %                     DetectTimes(spik_ind)' - Trigger.TrigBeginTime(r)'/10^6, waveforms_aligned(:,spik_ind)'];
            dummy_spik   = [repmat([r, stim_list(r,1)],[n_spik_ind,1]), channels(spik_ind), zeros(size(spik_ind)), DetectTimes(spik_ind)',...
                DetectTimes(spik_ind)' - Trigger.TrigBeginTime(r)'/10^6];

            AP = [AP; dummy_spik];
        end
    end

    channel(idx_channel).Spik_list = []; %add a number of nan and a condition in case it is longer than the nan - and then denan it
    if ~isempty(AP)
        % CONVERT THIS FORMAT (AP): r: occurence; c: 1 - trial, 2 - stimulus, 3 - ID-channel, 4 - ID-unit, 5 - ts according to file start, 6 - ts according to stimulus-onset,
        % INTO THIS FORMAT (Spik_list); (1 stim, 2 n_rep, 3 ypos ( (stim-1)+1/max(Header.n_rep)*n_rep 4 chan 5 un 6 time
        channel(idx_channel).Spik_list = zeros(size(AP));
        channel(idx_channel).Spik_list(:,[1, 4, 5, 6:end])  = AP(:,[2,3,4,6:end]);
        channel(idx_channel).Spik_list(:,2) =[stim_list(AP(:,1),2)];
        channel(idx_channel).Spik_list(:,3) =  (AP(:,2)-1)+(1./stim_n_rep(stim_list(AP(:,1)))).*stim_list(AP(:,1),2);
    end

    disp([num2str(idx_channel), '/' num2str(size(rawFiles, 1)) ' SL done'])
    
end
% add the spikeID -  this cannot be added in the  parfor
% create structure to save all SpikeID
countSp = 1;
for k=1:size(channel, 2)
    channelNsp = size(channel(k).Spik_list,1);
    channel(k).Spik_list(:,5) = [countSp :countSp+channelNsp-1];
    countSp = countSp+channelNsp;
end

%% save data
% make a structure to save the analysis parameters
used_analysis_parameters.threshold=threshold;
used_analysis_parameters.waveform_threshold_low=[channel.waveform_threshold_low];
used_analysis_parameters.pre_time = pre_time;
used_analysis_parameters.post_time = post_time;  % waveform-window
used_analysis_parameters.ref_time = ref_time;    % refractory period
used_analysis_parameters.low_filt = low_filt;
used_analysis_parameters.high_filt = high_filt;
used_analysis_parameters.filt_ord = filt_ord; % filter settings
used_analysis_parameters.prestimrectime = prestimrectime;
used_analysis_parameters.poststimrectime = poststimrectime; %
used_analysis_parameters.num_removed_spikes =num_removed_spikes; % removed spikes in artefact removal


% create structure to save all Spik_lists
all_electrode_names={};
for k=1:size(rawFiles, 1)
    analyzed_elec=channel(k).Spik_list(1,4);
    my_field = strcat('elec',num2str(analyzed_elec));
    spik_lists_all.(my_field) = channel(k).Spik_list;
    all_electrode_names{k}=my_field;
end


%save the spik_lists sorted by electrode, the used analysis parameters, the
%electrode name list (because all other functions need it and the trigger
%info to later check what the time window between triggers was
%min(diff(Trigger.TrigBeginTime))/1000 [s]
save_name = strcat(IC.ExpID,"_",IC.SeriesID,"_ICME_Resort.txt");
if  ~isfolder(fullfile(expProcDataDir,'ICME','RESORT'))
    mkdir(fullfile(expProcDataDir,'ICME','RESORT'));
end
fid = fopen(fullfile(expProcDataDir,'ICME','RESORT',save_name),'w');
fprintf(fid,['%% This file contains the extracted multiunitactivity spikes for all electrodes for one inferior \n' ...
    ' colliculus recording performed using ExpControl and a Neuralynx-Cheetah recording system:\n']);
fprintf(fid,[ ...
    'Experiment:\t%s\n' ...
    'Experimental date:\t%s\n' ...
    'Exp_type:\t %s\n' ], ...
    IC.SeriesID, ...
    eventFiles.date, ...
    IC.Stim.exp_type);
% write down the stimulus information
fprintf(fid,'%% Used Stimulus information:\n');
for i=1:length(IC.Stim.stimheader)
    fprintf(fid,'%s',IC.Stim.stimheader{i});
end
fprintf(fid,'\n');
for ii = 1:size(IC.Stim.stimlist, 1)
    % Find the number of columns in this row
    numCols = size(IC.Stim.stimlist, 2);

    % Generate a format string for this row (e.g., '%f\t%f\t%f\n')
    formatStr = [repmat('%f\t', 1, numCols-1) '%f\n'];

    % Print this row to the file using the format string
    fprintf(fid, formatStr, IC.Stim.stimlist(ii, :));
end


% write down the used analysis parameters
fprintf(fid,'%% Used analysis parameters for MUA extraction:\n');
fieldnames = fields(used_analysis_parameters);
% Loop over each field and write it to the file along with the value
for i = 1:length(fieldnames)
    fprintf(fid, '%s : %s\n', fieldnames{i}, num2str(used_analysis_parameters.(fieldnames{i})));
end



% write down the spikelist
fprintf(fid,'%% Resulting spikelist with detected MUA \n');
fprintf(fid,'stimulus ID \t repetition of stimulus \t  ypos for easy plotting \t channel/electrode \t unitID \t spiketime');
fclose(fid);

fieldnames = fields(spik_lists_all);
for i = 1:length(fieldnames)
    cur_spikelist=spik_lists_all.(fieldnames{i});
    writematrix(cur_spikelist,fullfile(expProcDataDir,'ICME','RESORT',save_name),'WriteMode','append');
end



end