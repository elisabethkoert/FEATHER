function [fig, dtAcqFailChunk]  = evaluateDataAndSpikes_EK(IC,electrodes, threshold,pre_time,post_time,ref_time,low_filt,high_filt,filt_ord,prestimrectime,poststimrectime,use_artefact_removal)
% evaluateDataAndSpikes - Inspects waveforms and assesses spike detection
%
% This function allows the user to evaluate raw data and inspect waveforms
% for spike detection analysis. It performs a series of preprocessing steps
% such as filtering and thresholding, enabling users to visualize and
% assess detected spikes. Additionally, the function checks for data
% acquisition failure by evaluating if the difference in the raw data is zero,
% indicating a potential data freeze or malfunction.
%
% Usage:
%   [SL, fig, acqFailureFlag] = evaluateDataAndSpikes(IC, electrodes, threshold, ...
%                                                    pre_time, post_time, ref_time, ...
%                                                    low_filt, high_filt, filt_ord, ...
%                                                    prestimrectime, poststimrectime)
%
% Input Parameters:
%   IC              - An instance of the `icme` object (inferior colliculus
%                     measurement) from the Feather toolbox, representing the
%                     input data for analysis.
%   electrodes      - Vector specifying electrode channels to be analyzed.
%   threshold       - Threshold for waveform extraction (in MAD units).
%   pre_time        - Time (in ms) before the spike peak to include in the window.
%   post_time       - Time (in ms) after the spike peak to include in the window.
%   ref_time        - Refractory period (in ms) to prevent multiple detections.
%   low_filt        - Low-pass filter cutoff frequency.
%   high_filt       - High-pass filter cutoff frequency.
%   filt_ord        - Order of the filter applied to the signal.
%   prestimrectime  - Time (in ms) before the stimulus onset for spike extraction.
%   poststimrectime - Time (in ms) after the stimulus onset for spike extraction.
%       use_artefact_removal (bool) if stimuli deteected over all electrodes 
%           simultaneously should get removed as artefact default true

%
% Output Parameters:
%   SL              - A structure containing:
%                     * Spike list (detected spikes)
%                     * Raw waveform data for each detected spike
%   fig             - Figure displaying the following visualizations:
%                     * Trigger timestamps
%                     * Raw waveform
%                     * MUA (multi-unit activity) peaks
%                     * MUA segments of the waveform
%   acqFailureFlag  - Index of data chunks where acquisition failure was detected:
%                     * Contains indices of failed data chunks (where data points are constant).
%                     * If empty, no acquisition failure was detected.
%
% Flexible Input:
%   - The function allows for flexible input, where you can provide only the
%     IC parameter or the IC and electrodes parameters, and the remaining parameters
%     will be prefilled with default values.
%
% Default Behavior:
%   If only the IC parameter is provided, default values are assigned to the
%   electrodes, threshold, filtering, and time window parameters for spike extraction.
%   If IC and electrodes are provided, other parameters use default settings.
%
% Example:
%   [SL, fig, acqFailureFlag] = evaluateDataAndSpikes(data, [1, 2, 5], 4, 0.3, 1.2, ...
%                                                     0.8, 500, 6000, 4, 100, 200)
%
% Notes:
%   - This function is useful for visualizing the extracted spikes around trigger events.
%   - The function automatically checks for data acquisition failures by detecting sections
%     of raw data where the difference is zero, suggesting a freeze or error in acquisition.
%   - Users can adjust the filtering and thresholding parameters to customize spike detection.
%
% Author:
%   A. Vavakou, November 2024





if nargin==2
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
    use_artefact_removal=1;

end

if nargin==1
    electrodes = 1:32;
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
    use_artefact_removal=1;

end

dtAcqFailChunk = 0;
chunkSS  = 512;

% find the raw data files
p_dat =   IC.ExpInfo.RawDataFolder{1}(strfind( IC.ExpInfo.RawDataFolder{1}, IC.ExpInfo.animal_ID)+length(IC.ExpInfo.animal_ID)+1:end);
rawFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat, '*.ncs'));
eventFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat,'*.nev'));

% get event info
filename_evt = fullfile(eventFiles.folder,eventFiles.name);
[evt.TimeStamps, evt.EventIDs, evt.TTLs, evt.Extras, evt.EventStrings] = ...
    Nlx2MatEV(filename_evt, [1 1 1 1 1], 0, 1, 0 );


%% prepare the basic stim_list/event IDs and triggers (AV style)

% in case there are missorted timestamps/triggers, resort
[sortedTimeStamps, sortIdx] = sort(evt.TimeStamps);
% Apply the same sorting to EventIDs, TTLs, EventStrings
evt.TimeStamps = evt.TimeStamps (sortIdx);
evt.EventIDs = evt.EventIDs (sortIdx);
evt.TTLs = evt.TTLs (sortIdx);
evt.Extras = evt.Extras (:,sortIdx);
evt.EventStrings = evt.EventStrings(sortIdx);

% get all timepoints of Trial info
stim__descriptor_Idx = find(cellfun(@(x) contains(x, 'Trial = '), evt.EventStrings, 'UniformOutput', true));
stim_names2  =  [evt.EventStrings(stim__descriptor_Idx)]; %EventString
vals = cellfun(@(s) sscanf(s, 'Trial = %d; Stim = %d;').', stim_names2, 'UniformOutput', false);
M = vertcat(vals{:});
TrialIDs=M(:,1);
StimListID=M(:,2);
num_of_trials=length(TrialIDs);
num_applied_stimuli=length(unique(StimListID));
names_applied_stimuli=unique(StimListID);
% do some sanity checks
if num_applied_stimuli ~= size(IC.Stim.stimlist,1)
        error(sprintf('num of found stimuli in raw data not same as IC.stimlist for %s',IC.SeriesID))
end
if (num_of_trials~=num_applied_stimuli*IC.Stim.n_rep)
    error(sprintf('not all repetitions found in data for %s',IC.SeriesID))
end
if any(diff(TrialIDs)~=1)
    error(sprintf('trial nubers of triggers are not constantly counting up for %s',IC.SeriesID))
end

% find all the trigger timepoints
IdxStartRecording =  find(contains( [evt.EventStrings(:)], 'Starting Recording')); %includes     {'Stopping Recording'} or     {'Starting Recording'}, so it is not just the 109th presentation of the stimuls
IdxStopRecording =  find(contains( [evt.EventStrings(:)], 'Stopping Recording')); %includes     {'Stopping Recording'} or     {'Starting Recording'}, so it is not just the 109th presentation of the stimuls

idx_triggers= find(contains( [evt.EventStrings(:)], '(0x0001)')); %includes     {'Stopping Recording'} or     {'Starting Recording'}, so it is not just the 109th presentation of the stimuls
num_of_triggers=length(idx_triggers);
if num_of_triggers~=num_of_trials
        error(sprintf('did not find the right number of tirggers for stimulus presentations for %s',IC.SeriesID))
end


% make the stimlist old way: first collumn: ID of the Applied stimulus (row
% in IC.Stim.Stimlist) second collumn: rep of this sitmulus
stim_list=zeros(num_of_triggers,2);
stim_list(:,1) = StimListID; 
stim_n_rep = zeros(num_applied_stimuli,1); % how often each type of applied stimulus got applied
for iUnStim = names_applied_stimuli'
    iCurStim = find(stim_list(:,1) == iUnStim);
    stim_list(iCurStim,2) = 1:length(iCurStim);
    stim_n_rep(names_applied_stimuli == iUnStim) = length(iCurStim);
end


Trigger.NrTrigger = num_of_trials; % number of recorded triggers
Trigger.TrigBeginTime = evt.TimeStamps(idx_triggers); %within each stimulus
Trigger.RecordingBeginTime = evt.TimeStamps(IdxStartRecording); %within each stimulus
Trigger.RecordingStopTime = evt.TimeStamps(IdxStopRecording); %within each stimulus
Trigger.stim_list = stim_list;
Trigger.stim_n_rep = stim_n_rep;
Trigger.stim_names = names_applied_stimuli;
Trigger.n_stim = num_applied_stimuli;

%% extraction of raw data from files, filtering and global mean calulation
% for extract the first channel
idx_channel=electrodes(1);
cur_channel =     sprintf('CSC%i.ncs',idx_channel);
cur_channelname = char(fullfile(gen_dir_name(IC.D.dir), p_dat, cur_channel));
[channel(idx_channel).data.Timestamps, channel(idx_channel).data.ChannelNumbers, channel(idx_channel).data.SampleFrequencies, channel(idx_channel).data.NumberOfValidSamples, channel(idx_channel).data.Samples, channel(idx_channel).data.Header] = ...
    Nlx2MatCSC(cur_channelname,[1 1 1 1 1], 1, 1, []);
fprintf('channel data loaded for %i \n',idx_channel)

% check for possibele things effecting the data that are stored within the
% neuralynx files
strToFind = '-ADBitVolts';
ADBitVolts = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')));
% failed data chunks?
dataInspect = mean(channel(idx_channel).data.Samples).*ADBitVolts;
failureChunks = find(dataInspect>9.9991e-04|dataInspect<-9.9991e-04);
dtAcqFailChunk = numel(failureChunks);
channel(idx_channel).data.failureChunks=failureChunks;
% input inversion
strToFind = '-InputInverted '; InputInversion = 1;
if isequal(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')), 'True')
    InputInversion = -1;
end
ADBitVolts = ADBitVolts * InputInversion;
% check for dspdelay
strToFind = '-DspFilterDelay';
filedIndexUTF8 =  find(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true));
channel(idx_channel).data.Header(filedIndexUTF8) = strrep(channel(idx_channel).data.Header(filedIndexUTF8), '�s', 'μs'); % Replace '�s' with 'μs' to ensure cross matlab version functionality
DspDelay = 0;
strToFind = '-DspDelayCompensation Disabled'; % zhe filter compensation is already enabled, so non jeed to apply additional correction
if  ~isempty(find(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)))
    strToFind = '-DspFilterDelay_µs ';
    DspDelay = str2num(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')))/10^6; % delay in seconds
end
% apply the DspDelay
channel(idx_channel).data.Timestamps = channel(idx_channel).data.Timestamps-DspDelay;


%%  global time vector by going through all chunks
num_data_chunks=length(channel(idx_channel).data.Timestamps);
sample_freq=channel(idx_channel).data.SampleFrequencies(1);
gl_time_vec=zeros(size (channel(idx_channel).data.Samples(:)))';
ix_in_vector=1;
chunkSize = [];
idxValidSamplesCollapsed = zeros(size(channel(idx_channel).data.Samples(:)));
dtPosix = 1/sample_freq * 1e6 ;

for datachunk_ix=1:num_data_chunks
    chunkSize = channel(idx_channel).data.NumberOfValidSamples(datachunk_ix);
    cur_start_time=(channel(idx_channel).data.Timestamps(datachunk_ix)); % this already includes the DspDelay compensation, that is retrieved from the first channel
    cur_time_vector=(cur_start_time:dtPosix:cur_start_time+(chunkSize-1)*dtPosix);
    gl_time_vec(ix_in_vector:ix_in_vector+chunkSize-1)=cur_time_vector;
    idxValidSamplesCollapsed(ix_in_vector:ix_in_vector+chunkSize-1) = 1;
    ix_in_vector=ix_in_vector+chunkSize;
    datachunk_ix;
end
gl_time_vec = gl_time_vec(logical(idxValidSamplesCollapsed));


gl_time_vec_dt=datetime(gl_time_vec/1e6, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
gl_time_vec_s=seconds(gl_time_vec_dt - gl_time_vec_dt(1));



trigger_timepoints_dt=datetime(Trigger.TrigBeginTime/1e6, 'ConvertFrom', 'posixtime', 'TimeZone', 'UTC');
trigger_timepoints_aligned_s=seconds(trigger_timepoints_dt-gl_time_vec_dt(1));
% align trigger in the recording domain
trigger_indices_in_data = interp1(gl_time_vec, 1:length(gl_time_vec),Trigger.TrigBeginTime, 'nearest');


% now preallocate the double for all channels
all_samples_all_channels=zeros(size(electrodes, 1),sum(idxValidSamplesCollapsed));
tmpCollapsedSamples = channel(idx_channel).data.Samples(:);
tmpCollapsedSamples = tmpCollapsedSamples (logical(idxValidSamplesCollapsed));

all_samples_all_channels(idx_channel,:)= bandfilt(tmpCollapsedSamples, low_filt, high_filt, channel(idx_channel).data.SampleFrequencies(1), filt_ord )*ADBitVolts;
channel(idx_channel).datafilt= (all_samples_all_channels(idx_channel,:))';

% now extract the rest of the channels
for idx_channel = electrodes(2:end)

    cur_channel =sprintf('CSC%i.ncs',idx_channel);% rawFiles(idx_channel).name;
     cur_channelname = char(fullfile(gen_dir_name(IC.D.dir), p_dat, cur_channel));
    [channel(idx_channel).data.Timestamps, channel(idx_channel).data.ChannelNumbers, channel(idx_channel).data.SampleFrequencies, channel(idx_channel).data.NumberOfValidSamples, channel(idx_channel).data.Samples, channel(idx_channel).data.Header] = ...
        Nlx2MatCSC(cur_channelname,[1 1 1 1 1], 1, 1, []);
    fprintf('channel data loaded for %i \n',idx_channel)
    % check for possibele things effecting the data that are stored within the
    % neuralynx files
    strToFind = '-ADBitVolts';
    ADBitVolts = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')));
    % failed data chunks?
    dataInspect = mean(channel(idx_channel).data.Samples).*ADBitVolts;
    failureChunks = find(dataInspect>9.9991e-04|dataInspect<-9.9991e-04);
    dtAcqFailChunk = numel(failureChunks);
    channel(idx_channel).data.failureChunks=failureChunks;
    % input inversion
    strToFind = '-InputInverted '; InputInversion = 1;
    if isequal(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')), 'True')
        InputInversion = -1;
    end
    ADBitVolts = ADBitVolts * InputInversion;
    % check for dspdelay
    strToFind = '-DspFilterDelay';
    filedIndexUTF8 =  find(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true));
    channel(idx_channel).data.Header(filedIndexUTF8) = strrep(channel(idx_channel).data.Header(filedIndexUTF8), '�s', 'μs'); % Replace '�s' with 'μs' to ensure cross matlab version functionality
    DspDelay = 0;
    strToFind = '-DspDelayCompensation Disabled'; % zhe filter compensation is already enabled, so non jeed to apply additional correction
    if  ~isempty(find(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)))
        strToFind = '-DspFilterDelay_µs ';
        DspDelay = str2num(deblank(strrep(channel(idx_channel).data.Header{(cellfun(@(x) contains(x, strToFind), channel(idx_channel).data.Header, 'UniformOutput', true)),:},strToFind,'')))/10^6; % delay in seconds
    end
    % apply the DspDelay
    channel(idx_channel).data.Timestamps = channel(idx_channel).data.Timestamps-DspDelay;
    % actually filter the data and save
    tmpCollapsedSamples = channel(idx_channel).data.Samples(:);
    tmpCollapsedSamples = tmpCollapsedSamples (logical(idxValidSamplesCollapsed));
    all_samples_all_channels(idx_channel,:)= bandfilt(tmpCollapsedSamples, low_filt, high_filt, channel(idx_channel).data.SampleFrequencies(1), filt_ord )*ADBitVolts;
   
    channel(idx_channel).datafilt= (all_samples_all_channels(idx_channel,:))';
end
global_mean_estimate=mean(all_samples_all_channels,1);
clear all_samples_all_channels

for idx_channel = electrodes%1: size(rawFiles, 1)
    %% define size wveform window in datapoints
    samples_pre = (pre_time*channel(idx_channel).data.SampleFrequencies(1))/1000;
    samples_post = (post_time*channel(idx_channel).data.SampleFrequencies(1))/1000;
    samples_ref = (ref_time*channel(idx_channel).data.SampleFrequencies(1))/1000;



    %% get bandpass filtered data
    datafilt=[];
    datafilt =  channel(idx_channel).datafilt;
    %% artefact removal if wanted

    if use_artefact_removal==1
            datafilt = datafilt-global_mean_estimate';
    end
     
    %% extract baseline from the timewindow before triggers
    num_samples_baseline=channel(idx_channel).data.SampleFrequencies(1)*0.098; % pick -100 ms to -2 ms before trigger for baseline
    num_samples_beforeTrigger=channel(idx_channel).data.SampleFrequencies(1)*0.002;
    baseline_datafilt= zeros(num_samples_baseline*(Trigger.NrTrigger+1),1);
    baseline_timevec = zeros(num_samples_baseline*(Trigger.NrTrigger+1),1);
    baseline_timevec_s = zeros(num_samples_baseline*(Trigger.NrTrigger+1),1);

    ix_helper=1;
    % Loop over each trigger
    for i = 1:Trigger.NrTrigger
        % trigger timepoint
        idx_trigger=trigger_indices_in_data(i)-num_samples_beforeTrigger; % go 2 ms before trigger to avoid any stimultation artefacts
%         if ~isnan(idx_trigger)
             baseline_datafilt(ix_helper:ix_helper+num_samples_baseline)=datafilt(idx_trigger-num_samples_baseline:idx_trigger);
%         end
       baseline_timevec(ix_helper:ix_helper+num_samples_baseline)=gl_time_vec(1,idx_trigger-num_samples_baseline:idx_trigger);
       baseline_timevec_s(ix_helper:ix_helper+num_samples_baseline)=gl_time_vec_s(1,idx_trigger-num_samples_baseline:idx_trigger);
        ix_helper=ix_helper+num_samples_baseline+1;
    end
    
%       % make sure the triggers and data and baseline are correctly
%       aligned
%     figure()
%     hold on
%     plot(gl_time_vec_s,datafilt,'b')
%     plot(baseline_timevec_s,baseline_datafilt,'r')
%     scatter(trigger_timepoints_aligned_s,mean(global_mean_estimate),'k','filled')
%     xlabel('time [s]')
%     ylabel('meaured voltage [mV]')
    


  
  
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
    channel(idx_channel).wave_windows_aligned(1, :) = wave_idcs_aligned-samples_pre;
    channel(idx_channel).wave_windows_aligned(2, :) = wave_idcs_aligned+samples_post;
    waveformsAlligned=zeros(num_samples_wave,length(channel(idx_channel).wave_windows));
    for wave_ix=1:length(channel(idx_channel).wave_windows)
        waveformsAlligned(:,wave_ix)=datafilt(channel(idx_channel).wave_windows_aligned(1,wave_ix):channel(idx_channel).wave_windows_aligned(2,wave_ix));
    end
    channel(idx_channel).waveformsAlligned = waveformsAlligned;
    channels_full = repmat(channel(idx_channel).data.ChannelNumbers, 512, 1); %what is  512, the size of how data gets stored in neuralynx
    channels_full = channels_full(:);
    channels = channels_full(wave_idcs_aligned);
    ChunkIdxOfWave     = ceil(wave_idcs_aligned'/ 512); % For correct timestamping only first 512 are timestamped and because some will not have timestamp but be corrected by modulo (rest)
    remWaveIdcsInChunk = mod(wave_idcs_aligned'-1,512);
    DetectTimes        = channel(idx_channel).data.Timestamps(1,ChunkIdxOfWave)/10^6+(remWaveIdcsInChunk)./channel(idx_channel).data.SampleFrequencies(1,ChunkIdxOfWave) - DspDelay;
    DetectTimes_seconds=gl_time_vec_s(wave_idcs_aligned);%(DetectTimes-DetectTimes(1))*1/32000;


     %% save detected APs in channel structure
    channel(idx_channel).DetectTimes=DetectTimes;
    channel(idx_channel).DetectTimes_seconds=DetectTimes_seconds;
    channel(idx_channel).channels=channels;
    channel(idx_channel).wave_idcs_aligned=wave_idcs_aligned;
%     channel(idx_channel).datafilt=datafilt;
    channel(idx_channel).MAD_noise_estimate=MAD_noise_estimate;
    disp([num2str(idx_channel), '/' num2str(size(rawFiles, 1)) ' detection done'])
end
% remove artefacts based on spikes that appear over all electrodes
% % simultanously
% num_removed_spikes=0;
% if use_artefact_removal==1
% 
%     if length(electrodes)>1
%         % find common timepoints
%         precision=4;%0.1 ms 
%         time_vec1=round(channel(electrodes(1)).DetectTimes_seconds,precision);
%         time_vec2=round(channel(electrodes(2)).DetectTimes_seconds,precision);
%         common_timepoints=intersect(time_vec1,time_vec2);
%         if length(electrodes)>2
%             for i = electrodes(3:end)
%                common_timepoints=intersect(common_timepoints,round(channel(i).DetectTimes_seconds,precision));
%             end     
%         end
%         %
%         fprintf('removing %i simultaneous spikes\n',length(common_timepoints))
%         num_removed_spikes=num_removed_spikes+length(common_timepoints);
% 
%         % remove entries
%         for i =electrodes
%             idcs_spikes_to_exclude=ismember(round(channel(i).DetectTimes_seconds,precision),common_timepoints);
%             channel(i).channels=channel(i).channels(~idcs_spikes_to_exclude);
%             channel(i).DetectTimes=channel(i).DetectTimes(~idcs_spikes_to_exclude);
%             channel(i).wave_idcs_aligned = channel(i).wave_idcs_aligned(~idcs_spikes_to_exclude);
%             channel(i).waveforms    = channel(i).waveforms(:,~idcs_spikes_to_exclude);
%             channel(i).waveformsAlligned = channel(i).waveformsAlligned(:,~idcs_spikes_to_exclude);
%             channel(i).DetectTimes_seconds=channel(i).DetectTimes_seconds(~idcs_spikes_to_exclude);
%         end
%     end
%     % sort out with a higher margin of error around the trigger (+- 2 ms
%     if length(electrodes)>1
%         % find common timepoints
%         precision=3;%0.1 ms 
%         time_vec1=round(channel(electrodes(1)).DetectTimes_seconds,precision);
%         time_vec2=round(channel(electrodes(2)).DetectTimes_seconds,precision);
%         common_timepoints=intersect(time_vec1,time_vec2);
%         if length(electrodes)>2
%             for i = electrodes(3:end)
%                common_timepoints=intersect(common_timepoints,round(channel(i).DetectTimes_seconds,precision));
%             end     
%         end
%         % kick out all timepoints that are not round the trigger, not yet
%         % working
%         tolerance = 2e-3;  % 2 ms
%         diff_matrix = repmat(common_timepoints,length(trigger_timepoints_aligned_s),1) - repmat(trigger_timepoints_aligned_s, length(common_timepoints), 1)';
%         common_timepoints=common_timepoints((any(abs(diff_matrix) < tolerance)));
%         num_removed_spikes=num_removed_spikes+length(common_timepoints);
% 
%         fprintf('removing %i simultaneous spikes\n',length(common_timepoints))
%         % remove entries
%          for i =electrodes
%             idcs_spikes_to_exclude=ismember(round(channel(i).DetectTimes_seconds,precision),common_timepoints);
%             channel(i).channels=channel(i).channels(~idcs_spikes_to_exclude);
%             channel(i).DetectTimes=channel(i).DetectTimes(~idcs_spikes_to_exclude);
%             channel(i).wave_idcs_aligned = channel(i).wave_idcs_aligned(~idcs_spikes_to_exclude);
%             channel(i).waveforms    = channel(i).waveforms(:,~idcs_spikes_to_exclude);
%             channel(i).waveformsAlligned = channel(i).waveformsAlligned(:,~idcs_spikes_to_exclude);
%             channel(i).DetectTimes_seconds=channel(i).DetectTimes_seconds(~idcs_spikes_to_exclude);
%         end
%     end
% end
% % 

%% get APS 
% values before loop
n_pres =  Trigger.NrTrigger; stim_list = Trigger.stim_list; stim_n_rep = Trigger.stim_n_rep;
t_pre = (prestimrectime/1000);
dur = t_pre+(poststimrectime/1000);

for idx_channel = electrodes
    % get detected times for this channel
    DetectTimes=channel(idx_channel).DetectTimes;
    wave_idcs_aligned=channel(idx_channel).wave_idcs_aligned;
    datafilt=channel(idx_channel).datafilt;
    MAD_noise_estimate=channel(idx_channel).MAD_noise_estimate;
    channels=channel(idx_channel).channels;


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


    disp([num2str(idx_channel), '/' num2str(size(rawFiles, 1)) ' channels done'])

    %% plotting 
    % plot raw data for different stimulus presentations
    fig(idx_channel).a = figure();
    rep=1;
    indices_this_rep=find(Trigger.stim_list(:,2)==rep);
    subplot(4,1,1)
    hold on
    plot(gl_time_vec_s,channel(idx_channel).data.Samples(logical(idxValidSamplesCollapsed)))
    xlabel('time [s]')
    xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
    ylabel('voltage [mu V]',Interpreter='latex')
    scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)','k','filled')
    title(sprintf('stimulus presentation nr. %i',rep))
    scatter(gl_time_vec_s(wave_idcs_aligned),channel(idx_channel).data.Samples(wave_idcs_aligned))



    
    subplot(4,1,2)
    hold on
    plot(gl_time_vec_s,datafilt,'DisplayName','filtered Data')
    xlabel('time [s]')
    ylabel('voltage [mu V]',Interpreter='latex')
    scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)'/1E6,'k','filled','DisplayName','trigger timepoints&ID')
    title(sprintf('%i: %.1f mW ',[1:1:length(IC.Stim.stimlist)],IC.Stim.stimlist(:,1)))
    xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
    plot([1:numel(datafilt)]',[(MAD_noise_estimate*ones(numel(datafilt),1,1))],'r','DisplayName','noise estimate')
%     plot([1:numel(datafilt)]',[(MAD_noise_estimate_alldata*ones(numel(datafilt),1,1))],'r--','DisplayName','noise estimate all data')
    plot(1:numel(datafilt),waveform_threshold_low*ones(numel(datafilt),1,1),'g','DisplayName','threshold')
     plot(1:numel(datafilt),4*waveform_threshold_low*ones(numel(datafilt),1,1),'k--','DisplayName','threshold')
    scatter(gl_time_vec_s(wave_idcs_aligned),datafilt(wave_idcs_aligned),'DisplayName','detected spikes')

    rep=30;
    indices_this_rep=find(Trigger.stim_list(:,2)==rep);
    subplot(4,1,3)
    hold on
    plot(gl_time_vec_s,channel(idx_channel).data.Samples(logical(idxValidSamplesCollapsed)))
    xlabel('time [s]')
    xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
    ylabel('voltage [mu V]',Interpreter='latex')
    scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)','k','filled')
    title(sprintf('stimulus presentation nr. %i',rep))
    scatter(gl_time_vec_s(wave_idcs_aligned),channel(idx_channel).data.Samples(wave_idcs_aligned))

    
    subplot(4,1,4)
    hold on
    plot(gl_time_vec_s,datafilt,'DisplayName','filtered Data')
    xlabel('time [s]')
    ylabel('voltage [mu V]',Interpreter='latex')
    scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)'/1E6,'k','filled','DisplayName','trigger timepoints&ID')
%     title(sprintf('%i: %.1f mW ',[1:1:length(IC.Stim.stimlist)],IC.Stim.stimlist(:,1)))
    xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
     plot([1:numel(datafilt)]',[(MAD_noise_estimate*ones(numel(datafilt),1,1))],'r','DisplayName','noise estimate')
    plot(1:numel(datafilt),waveform_threshold_low*ones(numel(datafilt),1,1),'g','DisplayName','threshold')
    scatter(gl_time_vec_s(wave_idcs_aligned),datafilt(wave_idcs_aligned),'DisplayName','detected spikes')
    fig_zoom(idx_channel).a.Position=[  652         209        1197         769];
    lg=legend();
     lg.Position=[    0.8115    0.2252    0.1270    0.0988];


%        fig(idx_channel).b = figure();
%     rep=10;
%     indices_this_rep=find(Trigger.stim_list(:,2)==rep);
%     subplot(4,1,1)
%     hold on
%     plot(gl_time_vec_s,channel(idx_channel).data.Samples(:))
%     xlabel('time [s]')
%     xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
%     ylabel('voltage [\mu V]',Interpreter='latex')
%     scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)','k','filled')
%     title(sprintf('stimulus presentation nr. %i',rep))
%     scatter(gl_time_vec_s(wave_idcs_aligned),channel(idx_channel).data.Samples(wave_idcs_aligned))
% 
%     
%     subplot(4,1,2)
%     hold on
%     plot(gl_time_vec_s,datafilt,'DisplayName','filtered Data')
%     xlabel('time [s]')
%     ylabel('voltage [\mu V]',Interpreter='latex')
%     scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)'/1E6,'k','filled','DisplayName','trigger timepoints&ID')
%     title(sprintf('%i: %.1f mW ',[1:1:length(IC.Stim.stimlist)],IC.Stim.stimlist(:,1)))
%     xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
%     plot([1:numel(datafilt)]',[(MAD_noise_estimate*ones(numel(datafilt),1,1))],'r','DisplayName','noise estimate')
% %     plot([1:numel(datafilt)]',[(MAD_noise_estimate_alldata*ones(numel(datafilt),1,1))],'r--','DisplayName','noise estimate all data')
%     plot(1:numel(datafilt),waveform_threshold_low*ones(numel(datafilt),1,1),'g','DisplayName','threshold')
%     scatter(gl_time_vec_s(wave_idcs_aligned),datafilt(wave_idcs_aligned),'DisplayName','detected spikes')
% 
%     rep=20;
%     indices_this_rep=find(Trigger.stim_list(:,2)==rep);
%     subplot(4,1,3)
%     hold on
%     plot(gl_time_vec_s,channel(idx_channel).data.Samples(:))
%     xlabel('time [s]')
%     xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
%     ylabel('voltage [\mu V]',Interpreter='latex')
%     scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)','k','filled')
%     title(sprintf('stimulus presentation nr. %i',rep))
%     scatter(gl_time_vec_s(wave_idcs_aligned),channel(idx_channel).data.Samples(wave_idcs_aligned))
% 
%     
%     subplot(4,1,4)
%     hold on
%     plot(gl_time_vec_s,datafilt,'DisplayName','filtered Data')
%     xlabel('time [s]')
%     ylabel('voltage [\mu V]',Interpreter='latex')
%     scatter(trigger_timepoints_aligned_s,Trigger.stim_list(:,1)'/1E6,'k','filled','DisplayName','trigger timepoints&ID')
% %     title(sprintf('%i: %.1f mW ',[1:1:length(IC.Stim.stimlist)],IC.Stim.stimlist(:,1)))
%     xlim([trigger_timepoints_aligned_s(indices_this_rep(1))-0.1,trigger_timepoints_aligned_s(indices_this_rep(end))+0.2])
%      plot([1:numel(datafilt)]',[(MAD_noise_estimate*ones(numel(datafilt),1,1))],'r','DisplayName','noise estimate')
%     plot(1:numel(datafilt),waveform_threshold_low*ones(numel(datafilt),1,1),'g','DisplayName','threshold')
%     scatter(gl_time_vec_s(wave_idcs_aligned),datafilt(wave_idcs_aligned),'DisplayName','detected spikes')
%     fig_zoom(idx_channel).a.Position=[  652         209        1197         769];
%     lg=legend();
%      lg.Position=[    0.8115    0.2252    0.1270    0.0988];

   
    % figure2 - waveforms of all the accepted threshold crossings .- alligned and not alligned in the same figure
    fig(idx_channel).c = figure();
    subplot(2,1,1)
    hold all
    plot(channel(idx_channel).waveforms)
    title('not - alligned waveforms')
    subplot(2,1,2)
    plot(channel(idx_channel).waveformsAlligned)
    title('alligned waveforms')

%     % figure3 - diff criterion - overlay with raw waveform - also the boxplot
%     fig(idx_channel).d = figure();
%     hold on
% %     for kk = 1 : numel(xVector)
% %         ll = plot(xVector(kk)*ones(2,1,1), tmpYlim','b');
% %     end
%     plot(channel(idx_channel).data.Samples(:),'k');
%     plot([1:numel(dataInspect)].*chunkSS,dataInspect/100,'g.')
%     plot(failureChunks.*chunkSS,dataInspect(failureChunks)/100,'.r')
%     legend('raw data','avgChunkAmplitude','chunkDataAcqFailes')

%     % figure4 - waveform with data acquisition triggers and also spikes and
%     % stimuli
%     %conversion is timestamp(1)/1e6 + 1/32000*nsamp
%     f(idx_channel).d = figure();
%     timeVector = channel(idx_channel).data.Timestamps(1)/1e6:1/32000:channel(idx_channel).data.Timestamps(end)/1e6+chunkSS*1/32000+1*1/32000;% look into the sample sizes. I am not sure why ut fails and I need to add 1 or 2. perhaps there are nire than 512 in the last chunk? i can figure that out somehow from te data?
%    
%     hold all
%     tmpYlim =    1.0e-03 * [ -0.1500    0.1500];
%     % % % for kk = 1 : size(channel(idx_channel).data.Samples,2)
%     % % %     ll = plot( timeVector(kk*chunkSS-chunkSS+1)* ones(2,1,1), tmpYlim','b');
%     % % % end
%     plot(timeVector,datafilt,'k')
% 
%     trigger_time_seconds=(Trigger.TrigBeginTime-Trigger.TrigBeginTime(1))/1e6;
%     gl_time_vec_s=1/32000:1/32000:(size(datafilt,1))*1/32000;%/1e6
%     channel(idx_channel).data.Timestamps(1)-Trigger.TrigBeginTime(1)
% 
%     trigger_timepoints_aligned_s=(Trigger.TrigBeginTime-channel(idx_channel).data.Timestamps(1))/1e6;
% 
%     figure
%     hold on
%     plot(gl_time_vec_s,datafilt)
%     scatter(trigger_timepoints_aligned_s,1)


end

end


