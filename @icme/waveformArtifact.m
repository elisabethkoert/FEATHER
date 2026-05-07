function out=waveformArtifact(IC, electrode, filtFlag, doSave)
% Description:
%   This method of the `icme` class extracts the waveform of an artifact
%   from a specified electrode in the `IC` recording. If filtering is enabled,
%   the function applies a predefined filter to the data.
%
% Inputs:
%   IC        - Instance of the `icme` class containing recorded data.
%   electrode - Index or identifier of the electrode to analyze.
%   filtFlag  - Boolean flag (true/false) indicating whether to apply filtering.
%
% Output:
%   out       - Processed waveform data, either raw or filtered based on `filtFlag`.
%
% Example usage:
%   artifact = IC.waveformArtifact(3, true);
%- DspDelay should be used correctly, I have not one it now
% AV 2025

switch filtFlag
    case 1%remove DC
        low_filt = 1;%600;
        high_filt = 15900;
        filt_ord = 2;%4; % filter settings
        used_analysis_parameters.low_filt = low_filt;
        used_analysis_parameters.high_filt = high_filt;
        used_analysis_parameters.filt_ord = filt_ord; % filter settings
        used_analysis_parameters.filtFlag = filtFlag; %
    case 2% like spike detection
        low_filt = 600;
        high_filt = 6000;
        filt_ord = 4; % filter settings
        used_analysis_parameters.low_filt = low_filt;
        used_analysis_parameters.high_filt = high_filt;
        used_analysis_parameters.filt_ord = filt_ord; % filter settings
        used_analysis_parameters.filtFlag = filtFlag; %
    case 0% no filter
        % used_analysis_parameters.ref_time = ref_time;    % refractory period
        used_analysis_parameters.low_filt = nan;
        used_analysis_parameters.high_filt = nan;
        used_analysis_parameters.filt_ord = nan; % filter settings
        used_analysis_parameters.filtFlag = filtFlag; %
    case 3%ommit 50Hz
        low_filt = 2;
        high_filt = 15900;
        filt_ord = 2; % filter settings
        used_analysis_parameters.low_filt = low_filt;
        used_analysis_parameters.high_filt = high_filt;
        used_analysis_parameters.filt_ord = filt_ord; % filter settings
        used_analysis_parameters.filtFlag = filtFlag; %
end

if nargin==3
    doSave = 0;
end


prestimrectime = 0.05;
poststimrectime= 0.55;

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

% load data
for idx_channel = electrode% 1:size(rawFiles, 1)
    cur_channel = rawFiles(idx_channel).name;
    cur_channelname = char(fullfile(gen_dir_name(IC.D.dir), p_dat, cur_channel));
    [channel(idx_channel).data.Timestamps, channel(idx_channel).data.ChannelNumbers, channel(idx_channel).data.SampleFrequencies, channel(idx_channel).data.NumberOfValidSamples, channel(idx_channel).data.Samples, channel(idx_channel).data.Header] = ...
        Nlx2MatCSC(cur_channelname,[1 1 1 1 1], 1, 1, []);
    fprintf('channel data loaded for %i \n',idx_channel)
end

% filter
% start event extraction
strToFind = '-DspFilterDelay';
filedIndexUTF8 =  strmatch(strToFind,channel(idx_channel).data.Header);
channel(idx_channel).data.Header(filedIndexUTF8) = strrep(channel(idx_channel).data.Header(filedIndexUTF8), '�s', 'μs'); % Replace '�s' with 'μs' to ensure cross matlab version functionality

DspDelay = 0; strToFind = '-DspDelayCompensation Disabled';
if  ~isempty(strmatch(strToFind,channel(idx_channel).data.Header));
    strToFind = '-DspFilterDelay_μs'; DspDelay = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')))/10^6; % delay in seconds
end

strToFind = '-ADBitVolts';
ADBitVolts = str2num(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')));

strToFind = '-InputInverted '; InputInversion = 1;
if isequal(deblank(strrep(channel(idx_channel).data.Header{strmatch(strToFind,channel(idx_channel).data.Header),:},strToFind,'')), 'True')
    InputInversion = -1;
end

ADBitVolts = ADBitVolts * InputInversion;

% band pass filter
datafilt = [];
if filtFlag > 0
    datafilt = bandfilt(channel(idx_channel).data.Samples(:), low_filt, high_filt, channel(idx_channel).data.SampleFrequencies(1), filt_ord )*ADBitVolts;
else
    datafilt = channel(idx_channel).data.Samples(:)*ADBitVolts;
end
% align trigger and data timepoints in ms range
time_vec_data=(1/32000:1/32000:(size(datafilt,1))*1/32000);%/1e6;
trigger_time_seconds_aligned=(Trigger.TrigBeginTime-channel(idx_channel).data.Timestamps(1))/1e6;

indices = zeros(3,length(trigger_time_seconds_aligned));
baseline_datafilt=[];
baseline_timevec=[];
out=struct();

% Loop over each element in trigger_time_seconds_aligned
for i = 1:length(trigger_time_seconds_aligned)
    % trigger timepoint
    [~, idx2] = min(abs(time_vec_data - trigger_time_seconds_aligned(i)));
    indices(2,i) = idx2;
    % time s before trigger
    [~, idx1] = min(abs(time_vec_data - (trigger_time_seconds_aligned(i)-prestimrectime)));
    indices(1,i) = idx1;
    % time after  trigger
    [~, idx3] = min(abs(time_vec_data - (trigger_time_seconds_aligned(i)+poststimrectime)));
    indices(3,i) = idx3;
    baseline_datafilt=[baseline_datafilt;datafilt(idx1:idx2)];
    baseline_timevec=[baseline_timevec, time_vec_data(1,idx1:idx2)];

    out(i).waveform = (datafilt(idx2:idx3));
    out(i).time = (time_vec_data(1,idx2:idx3));
    out(i).stim_list = stim_list(i,:);
    out(i).used_analysis_parameters = used_analysis_parameters;
end

if doSave ==1
    artWav = out
    save_name = strcat(IC.SeriesID,"_filt",num2str(filtFlag),'.mat');
    save(fullfile(expProcDataDir,save_name), 'artWav');
end



end