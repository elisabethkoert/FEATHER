function  [spik_lists_all,used_analysis_parameters,all_electrode_names]=generateSLfromRawNlxData(IC,threshold,pre_time,post_time,ref_time,low_filt,high_filt,filt_ord,prestimrectime,poststimrectime)
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
%       are extracted from [ms]
% output:
% spik_list_all (struct with fields named after each electrode containing
% the Spik_list for each of these electrodes. Spik_list has for each
% detected spike one row with the collumns  (1 stim, 2 n_rep, 3 ypos ( (stim-1)+1/max(Header.n_rep)*n_rep for easier raster plot generation 4
% chan 5 unit ID (only with spike sorting so not implemented) 6 time after
% trigger
% used_analysis_parameters (struct) used analysis parameters including
%       threshold; % treshold [V?] to detect multiunit activity as spike
%       pre_time; post_time;  % waveform-window around a detected spike
%       ref_time;    % refractory period [ms]?
%       low_filt, high_filt;filt_ord; %bandpass filter in beginning of data processing
%       prestimrectime; poststimrectime % time around trigger that spikes are
%       extracteed
% all_electrode_names (struct with names elec0 -elec31 )

%% initialize sorting parameters
if nargin==1
    threshold = 3; % threshold for waveform extraction (in MAD)
    pre_time = 0.5;
    post_time = 1; % waveform-window
    ref_time = 1; % refractory period
    low_filt = 600;
    high_filt = 6000;
    filt_ord = 4; % filter settings
    % time in ms around trigger that the spikes are extracted
    prestimrectime = 150;
    poststimrectime= 150;
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
infoFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat, 'CheetahLostADRecords.txt'));
spikeFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat,'*.nse'));
eventFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat,'*.nev'));
% get event info
filename_evt = fullfile(eventFiles.folder,eventFiles.name);
[evt.TimeStamps, evt.EventIDs, evt.TTLs, evt.Extras, evt.EventStrings] = ...
    Nlx2MatEV(filename_evt, [1 1 1 1 1], 0, 1, 0 );

%% prepare the basic stim_list
% convert event info and create a stim_list
stim_Idx = strmatch('Trial = ',evt.EventStrings);
stim_names = unique(evt.TTLs(stim_Idx)');
n_stim = length(stim_names); n_pres = length(stim_Idx);
stim_list = evt.TTLs(stim_Idx)'; stim_list(:,2) = NaN;
stim_n_rep = zeros(n_stim,1);
for iUnStim = stim_names'
    iCurStim = find(stim_list(:,1) == iUnStim);
    stim_list(iCurStim,2) = [1:length(iCurStim)];
    stim_n_rep(stim_names == iUnStim) = length(iCurStim);
end

% here we have following variables:
% stim_names and n_stim the individual StimulusIDs and the total number
% stim_list is an n_Stim*n_repx2 double with stim_list(:,1) being the order
% in which the stim_IDs were presented and stim_list(:,1) being the
% rep. of the presentation
% stim_n_rep the numebr of repetitions each individual stimulus has
% been represented

%% match the trial numebers to the stimulus IDs
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

%par
parfor idx_channel = 1: size(rawFiles, 1)

    % start event extraction
    strToFind = '-DspFilterDelay';
    filedIndexUTF8 =  strmatch(strToFind,channel(idx_channel).data.Header);
    channel(idx_channel).data.Header(filedIndexUTF8) = strrep(channel(idx_channel).data.Header(filedIndexUTF8), '�s', 'μs'); % Replace '�s' with 'μs' to ensure cross matlab version functionality

    DspDelay = 0; strToFind = '-DspDelayCompensation Disabled';
    if  ~isempty(strmatch(strToFind,channel(idx_channel).data.Header));
        strToFind = '-DspFilterDelay_µs '; DspDelay = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')))/10^6; % delay in seconds
    end

    strToFind = '-ADBitVolts';
    ADBitVolts = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')));

    strToFind = '-InputInverted '; InputInversion = 1;
    if isequal(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')), 'True')
        InputInversion = -1;
    end

    ADBitVolts = ADBitVolts * InputInversion;

    % define size wveform window in datapoints
    samples_pre = (pre_time*channel(idx_channel).data.SampleFrequencies(1))/1000;
    samples_post = (post_time*channel(idx_channel).data.SampleFrequencies(1))/1000;
    samples_ref = (ref_time*channel(idx_channel).data.SampleFrequencies(1))/1000;

    %% put potential artefact removal here!

    %% end artefact removal start filtering

    % band pass filter
    datafilt = [];
    datafilt = bandfilt(channel(idx_channel).data.Samples(:), low_filt, high_filt, channel(idx_channel).data.SampleFrequencies(1), filt_ord )*ADBitVolts;

    % noise estimate to decide if there is a MUA
    MAD_noise_estimate = median(abs(datafilt-mean(datafilt)))/0.675;
    waveform_threshold_low = mean(datafilt)-threshold*MAD_noise_estimate;
    channel(idx_channel).waveform_threshold_low=waveform_threshold_low;

    if waveform_threshold_low > 0
        i_thresh = 1;
    elseif waveform_threshold_low < 0
        i_thresh = -1;
    end

    wave_idcs = find(i_thresh.*datafilt(1:end-1) < i_thresh*waveform_threshold_low & i_thresh.*datafilt(2:end) > i_thresh*waveform_threshold_low);
    wave_idcs = wave_idcs(diff(wave_idcs, 1, 1) > samples_ref); % Difference must be bigger than samples_ref
    wave_idcs = wave_idcs(wave_idcs > samples_pre); %Must be after samples pre 0.5ms
    channel(idx_channel).wave_windows(1, :) = wave_idcs-samples_pre;
    channel(idx_channel).wave_windows(2, :) = wave_idcs+samples_post;
    wave_idcs_full = eval(['[',sprintf('%i:%i, ', (channel(idx_channel).wave_windows(:))),']']); % eindeces to look at for each spike

    channel(idx_channel).waveforms = datafilt(wave_idcs_full);
    channel(idx_channel).waveforms = reshape(channel(idx_channel).waveforms, samples_pre+samples_post+1, []); % no wit is the actual trace saved for each spike
    [maxval, maxloc] = max(i_thresh.*channel(idx_channel).waveforms); % location changes from threshold crossing point to peak after threshold
    %        maxval is peak voltage (V) detected for each waveform, maxloc is the
    %        id

    wave_idcs_aligned = wave_idcs+((maxloc-samples_pre))'; % align waves by peak

    channel(idx_channel).wave_windows_aligned(1, :) = wave_idcs_aligned-samples_pre;
    channel(idx_channel).wave_windows_aligned(2, :) = wave_idcs_aligned+samples_post;
    wave_idcs_full_aligned = eval(['[',sprintf('%i:%i, ', (channel(idx_channel).wave_windows_aligned(:))),']']);


    channels_full = repmat(channel(idx_channel).data.ChannelNumbers, 512, 1); %what is  512
    channels_full = channels_full(:);
    channels = channels_full(wave_idcs_aligned);

    ChunkIdxOfWave     = ceil(wave_idcs_aligned'/ 512); % For correct timestamping only first 512 are timestamped and because some will not have timestamp but be corrected by modulo (rest)
    remWaveIdcsInChunk = mod(wave_idcs_aligned'-1,512);
    DetectTimes        = channel(idx_channel).data.Timestamps(1,ChunkIdxOfWave)/10^6+(remWaveIdcsInChunk)./channel(idx_channel).data.SampleFrequencies(1,ChunkIdxOfWave) - DspDelay;

    n_pres =  Trigger.NrTrigger; stim_list = Trigger.stim_list; stim_n_rep = Trigger.stim_n_rep;

    t_pre = (prestimrectime/1000);
    dur = t_pre+(poststimrectime/1000);
    %% start going through all stimulus presentations and collect APs
    channel(idx_channel).AP  = [];
    for r = 1 : n_pres
        % get time window for this stim presentation
        t1 = Trigger.TrigBeginTime(r)-t_pre*10^6;
        %             datafiltsaved(idx_channel,n_pres,:)=datafilt(:);
        t2 = t1 + dur*10^6;
        spik_ind     = find(DetectTimes(:)*10^6 >= t1 & DetectTimes(:)*10^6 <= t2); % find all detected spikes in this timeframe

        n_spik_ind   = length(spik_ind);
        dummy_spik   = [];
        if ~isempty(n_spik_ind)
            %                 dummy_spik   = [repmat([r, stim_list(r,1)],[n_spik_ind,1]), channels(spik_ind), zeros(size(spik_ind)), DetectTimes(spik_ind)',...
            %                 DetectTimes(spik_ind)' - Trigger.TrigBeginTime(r)'/10^6, waveforms_aligned(:,spik_ind)'];
            dummy_spik   = [repmat([r, stim_list(r,1)],[n_spik_ind,1]), channels(spik_ind), zeros(size(spik_ind)), DetectTimes(spik_ind)',...
                DetectTimes(spik_ind)' - Trigger.TrigBeginTime(r)'/10^6];

            channel(idx_channel).AP = [channel(idx_channel).AP; dummy_spik];
        end
    end

    channel(idx_channel).Spik_list = []; %add a number of nan and a condition in case it is longer than the nan - and then denan it
    if ~isempty(channel(idx_channel).AP)
        % CONVERT THIS FORMAT (channel(idx_channel).AP): r: occurence; c: 1 - trial, 2 - stimulus, 3 - ID-channel, 4 - ID-unit, 5 - ts according to file start, 6 - ts according to stimulus-onset,
        % INTO THIS FORMAT (Spik_list); (1 stim, 2 n_rep, 3 ypos ( (stim-1)+1/max(Header.n_rep)*n_rep 4 chan 5 un 6 time
        channel(idx_channel).Spik_list = zeros(size(channel(idx_channel).AP));
        channel(idx_channel).Spik_list(:,[1, 4, 5, 6:end])  = channel(idx_channel).AP(:,[2,3,4,6:end]);
        channel(idx_channel).Spik_list(:,2) =[stim_list(channel(idx_channel).AP(:,1),2)];
        channel(idx_channel).Spik_list(:,[3]) =  (channel(idx_channel).AP(:,2)-1)+(1./stim_n_rep(stim_list(channel(idx_channel).AP(:,1)))).*stim_list(channel(idx_channel).AP(:,1),2);
    end

    disp([num2str(idx_channel), '/' num2str(size(rawFiles, 1)) ' channels done'])

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






% %test if there is alreadz a directory for SR, otherwise make it
% if  ~isfolder(fullfile(expProcDataDir,'ICME','RESORT'))
%     mkdir(fullfile(expProcDataDir,'ICME','RESORT'));
%     save(fullfile(expProcDataDir,'ICME','RESORT',save_name), 'spik_lists_all','used_analysis_parameters','all_electrode_names','Trigger');
% elseif  isfolder(fullfile(expProcDataDir,'ICME','RESORT')) == 1
%     save(fullfile(expProcDataDir,'ICME','RESORT',save_name), 'spik_lists_all','used_analysis_parameters','all_electrode_names','Trigger');
% end

end