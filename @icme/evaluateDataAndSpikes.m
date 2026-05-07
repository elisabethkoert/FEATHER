function [SL, fig, dtAcqFailChunk]  = evaluateDataAndSpikes (IC,electrodes, threshold,pre_time,post_time,ref_time,low_filt,high_filt,filt_ord,prestimrectime,poststimrectime)
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
end

if nargin==1
    electrodes = [1:32];
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

dtAcqFailChunk = 0;
chunkSS  = 512;

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

for idx_channel = electrodes%1:size(rawFiles, 1)
    cur_channel = rawFiles(idx_channel).name;
    cur_channelname = char(fullfile(gen_dir_name(IC.D.dir), p_dat, cur_channel));
    [channel(idx_channel).data.Timestamps, channel(idx_channel).data.ChannelNumbers, channel(idx_channel).data.SampleFrequencies, channel(idx_channel).data.NumberOfValidSamples, channel(idx_channel).data.Samples, channel(idx_channel).data.Header] = ...
        Nlx2MatCSC(cur_channelname,[1 1 1 1 1], 1, 1, []);
    fprintf('channel data loaded for %i \n',idx_channel)
end

for idx_channel = electrodes%1: size(rawFiles, 1)

    % start event extraction
    DspDelay = 0; strToFind = '-DspDelayCompensation Disabled';
    if  ~isempty(strmatch(strToFind,channel(idx_channel).data.Header))
        strToFind = '-DspFilterDelay_µs '; DspDelay = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')))/10^6; % delay in seconds
    end

    %could be that adbtovolts is common for each probe, or even for the
    %whole syste, then this can happen outside a loop for faster data
    %processing
    strToFind = '-ADBitVolts';
    ADBitVolts = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')));
    dataInspect = mean(channel(idx_channel).data.Samples).*ADBitVolts;
    failureChunks = find(dataInspect>9.9991e-04|dataInspect<-9.9991e-04);
    dtAcqFailChunk = numel(failureChunks);



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

    if waveform_threshold_low > 0
        i_thresh = 1;
    elseif waveform_threshold_low < 0
        i_thresh = -1;
    end
    %DB part

    % assess data acquisition failure: cirterion: diff=0
  % rawDataDiff = diff(datafilt);%;(datafilt(numel(datafilt)/subSampleF1 : numel(datafilt)/subSampleF1 +numel(datafilt)/subSampleF2 )); %that is to kae the

    wave_idcs = find(i_thresh.*datafilt(1:end-1) < i_thresh*waveform_threshold_low & i_thresh.*datafilt(2:end) > i_thresh*waveform_threshold_low);
    wave_idcsA = wave_idcs(diff(wave_idcs, 1, 1) > samples_ref); % Difference must be bigger than samples_ref
    wave_idcsB = wave_idcsA(wave_idcsA > samples_pre); %Must be after samples pre 0.5ms


    channel(idx_channel).wave_windows(1, :) = wave_idcsB-samples_pre;
    channel(idx_channel).wave_windows(2, :) = wave_idcsB+samples_post;
    wave_idcs_full = eval(['[',sprintf('%i:%i, ', (channel(idx_channel).wave_windows(:))),']']); % eindeces to look at for each spike

    channel(idx_channel).waveforms = datafilt(wave_idcs_full);
    channel(idx_channel).waveforms = reshape(channel(idx_channel).waveforms, samples_pre+samples_post+1, []); % no wit is the actual trace saved for each spike

    [~, maxloc] = max(i_thresh.*channel(idx_channel).waveforms); % location changes from threshold crossing point to peak after threshold
    %        maxval is peak voltage (V) detected for each waveform, maxloc is the
    %        id
    wave_idcs_aligned = wave_idcsB+((maxloc-samples_pre))'; % align waves by peak

    channel(idx_channel).wave_windows_aligned(1, :) = wave_idcs_aligned-samples_pre;
    channel(idx_channel).wave_windows_aligned(2, :) = wave_idcs_aligned+samples_post;
    wave_idcs_full_aligned = eval(['[',sprintf('%i:%i, ', (channel(idx_channel).wave_windows_aligned(:))),']']);
    channel(idx_channel).waveformsAlligned = datafilt(wave_idcs_full_aligned);
    channel(idx_channel).waveformsAlligned = reshape(channel(idx_channel).waveformsAlligned, samples_pre+samples_post+1, []); % no wit is the actual trace saved for each spike

    %allignment affects1-3 samples usually

    channels_full = repmat(channel(idx_channel).data.ChannelNumbers, chunkSS, 1); %
    channels_full = channels_full(:);
    channels = channels_full(wave_idcs_aligned);

    ChunkIdxOfWave     = ceil(wave_idcs_aligned'/ chunkSS); % For correct timestamping only first chunkSS are timestamped and because some will not have timestamp but be corrected by modulo (rest)
    remWaveIdcsInChunk = mod(wave_idcs_aligned'-1,chunkSS);
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

    %PLOTTING
     f(idx_channel).a = figure();
    plot(datafilt,'k')
    hold all
    plot([1:numel(datafilt)]',[(MAD_noise_estimate*ones(numel(datafilt),1,1))],'r')
    plot(1:numel(datafilt),waveform_threshold_low*ones(numel(datafilt),1,1),'g')
    plot(wave_idcs_full_aligned,datafilt(wave_idcs_full_aligned),'.b')

    legend('datafilt','MADnoiseEstimate','waveformThresholdLow','lowThresholdCrossingPoint', 'accepetedWaveform')

    % figure2 - waveforms of all the accepted threshold crossings .- alligned and not alligned in the same figure
    f(idx_channel).b = figure();
    subplot(2,1,1)
    hold all
    plot(channel(idx_channel).waveforms)
    title('not - alligned waveforms')
    subplot(2,1,2)
    plot(channel(idx_channel).waveformsAlligned)
    title('alligned waveforms')

    % figure3 - diff criterion - overlay with raw waveform - also the boxplot
    f(idx_channel).c = figure();
    subplot(2,1,1)
    tmpYlim = 1.0e-03 * [-0.1260    0.1191];
    xVector = [1:chunkSS:numel(datafilt)];
    hold all
    for kk = 1 : numel(xVector)
        ll = plot(xVector(kk)*ones(2,1,1), tmpYlim','b');
    end

    plot(datafilt,'k');
    plot([1:numel(dataInspect)].*chunkSS,dataInspect/100,'g.')
    plot(failureChunks.*chunkSS,dataInspect(failureChunks)/100,'.r')
    legend('dataChunkStart','dtafilt','avgChunkAmplitude','chunkDataAcqFailes')
    subplot(2,1,2)
    kk = boxplot(dataInspect, 'Whisker', 1.5);  % 1.5 is the default value for whiskers
    hold on;
    jitterAmount=0.05;
    plot( 1 + jitterAmount * (rand(size(dataInspect)) - 0.5), dataInspect, 'k.', 'MarkerFaceColor', 'k');  % 'ko' for black circles
    legend('boxplot','allChunkavgAmpli')

    % figure4 - waveform with data acquisition triggers and also spikes and
    % stimuli
    %conversion is timestamp(1)/1e6 + 1/32000*nsamp
    f(idx_channel).d = figure();
    timeVector = (1/32000:1/32000:(size(datafilt,1))*1/32000);%channel(idx_channel).data.Timestamps(1)/1e6:1/32000:channel(idx_channel).data.Timestamps(end)/1e6+chunkSS*1/32000+1*1/32000;% look into the sample sizes. I am not sure why ut fails and I need to add 1 or 2. perhaps there are nire than 512 in the last chunk? i can figure that out somehow from te data?
   
    hold all
    tmpYlim =    1.0e-03 * [ -0.1500    0.1500];
    % % % for kk = 1 : size(channel(idx_channel).data.Samples,2)
    % % %     ll = plot( timeVector(kk*chunkSS-chunkSS+1)* ones(2,1,1), tmpYlim','b');
    % % % end

    plot(timeVector,datafilt,'k')
    %plot(time_vec_data,datafilt,'k')

%     time_vec_data=(1/32000:1/32000:(size(datafilt,1))*1/32000);%/1e6;
%     trigger_time_seconds_aligned=(Trigger.TrigBeginTime-channel(idx_channel).data.Timestamps(1))/1e6;
%     timepoints_baseline=[trigger_time_seconds_aligned-0.1;trigger_time_seconds_aligned];
%    


    trigger_time_seconds=(Trigger.TrigBeginTime-Trigger.TrigBeginTime(1))/1e6;
    time_vec_data=1/32000:1/32000:(size(datafilt,1))*1/32000; %/1e6
    channel(idx_channel).data.Timestamps(1)-Trigger.TrigBeginTime(1);

    trigger_time_seconds_aligned=(Trigger.TrigBeginTime-channel(idx_channel).data.Timestamps(1))/1e6;

    figure
    hold on
    plot(time_vec_data,datafilt)
    scatter(trigger_time_seconds_aligned,0, 'ok')




    



    %add stimulus!
    for kk = 1 : numel(Trigger.TrigBeginTime)
        ll = plot(Trigger.TrigBeginTime(kk)/1e6* ones(2,1,1), tmpYlim','r');
    end
    % % % % %
    localSave(f)
end

end

function localSave(~)
for kk = 1

end
end

