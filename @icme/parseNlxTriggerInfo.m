function Trigger = parseNlxTriggerInfo(IC)
% icme/parseNlxTriggerInfo - parses the Neuralynx .nev event file for one
% IC recording and reconstructs, per stimulus trial, the absolute trigger
% timestamp plus which stimlist row (stim ID) and repetition number it
% corresponds to.
% input:
%   IC (icme) - needs IC.ExpInfo, IC.Stim, IC.D
% output:
%   Trigger (struct):
%     NrTrigger           - number of recorded stimulus trials
%     TrigBeginTime       - 1 x NrTrigger, absolute NLX/posix time [us],
%                           in stimulus-presentation order
%     RecordingBeginTime  - absolute NLX/posix time [us], 'Starting Recording' event
%     RecordingStopTime   - absolute NLX/posix time [us], 'Stopping Recording' event
%     stim_list           - NrTrigger x 2: [stimlist_row_id, repetition_number]
%     stim_n_rep          - n_stim x 1, presentations per stimlist row
%     stim_names          - unique stimlist row ids used
%     n_stim              - number of unique stimlist rows used

p_dat = IC.ExpInfo.RawDataFolder{1}(strfind(IC.ExpInfo.RawDataFolder{1}, IC.ExpInfo.animal_ID)+length(IC.ExpInfo.animal_ID)+1:end);
eventFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat, '*.nev'));
assert(~isempty(eventFiles), 'parseNlxTriggerInfo: no .nev file found for %s', IC.SeriesID);
filename_evt = fullfile(eventFiles(1).folder, eventFiles(1).name);

[evt.TimeStamps, evt.EventIDs, evt.TTLs, evt.Extras, evt.EventStrings] = ...
    Nlx2MatEV(filename_evt, [1 1 1 1 1], 0, 1, 0);

% --- sort in case of misordered events ---
[~, sortIdx] = sort(evt.TimeStamps);
evt.TimeStamps   = evt.TimeStamps(sortIdx);
evt.EventIDs     = evt.EventIDs(sortIdx);
evt.TTLs         = evt.TTLs(sortIdx);
evt.Extras       = evt.Extras(:,sortIdx);
evt.EventStrings = evt.EventStrings(sortIdx);

IdxStartRecording = find(contains([evt.EventStrings(:)], 'Starting Recording'));
IdxStopRecording  = find(contains([evt.EventStrings(:)], 'Stopping Recording'));
if numel(IdxStartRecording) > 1
    % accidental double-recording: cut everything before the last start
    evt.TimeStamps   = evt.TimeStamps(IdxStartRecording(end):end);
    evt.EventIDs     = evt.EventIDs(IdxStartRecording(end):end);
    evt.TTLs         = evt.TTLs(IdxStartRecording(end):end);
    evt.Extras       = evt.Extras(:,IdxStartRecording(end):end);
    evt.EventStrings = evt.EventStrings(IdxStartRecording(end):end);
    IdxStartRecording = find(contains([evt.EventStrings(:)], 'Starting Recording'));
    IdxStopRecording  = find(contains([evt.EventStrings(:)], 'Stopping Recording'));
end

stim_descriptor_Idx = find(cellfun(@(x) contains(x, 'Trial = '), evt.EventStrings, 'UniformOutput', true));
stim_names2 = evt.EventStrings(stim_descriptor_Idx);
vals = cellfun(@(s) sscanf(s, 'Trial = %d; Stim = %d;').', stim_names2, 'UniformOutput', false);
M = vertcat(vals{:});
TrialIDs = M(:,1);
StimListID = M(:,2);
num_of_trials = length(TrialIDs);
names_applied_stimuli = unique(StimListID);
num_applied_stimuli = numel(names_applied_stimuli);

if num_applied_stimuli ~= size(IC.Stim.stimlist,1)
    error('parseNlxTriggerInfo: num of found stimuli in raw data not same as IC.Stim.stimlist for %s', IC.SeriesID)
end
if num_of_trials ~= num_applied_stimuli*IC.Stim.n_rep
    error('parseNlxTriggerInfo: not all repetitions found in data for %s', IC.SeriesID)
end

if any(diff(TrialIDs) ~= 1)
    % re-read once unsorted, matching the fallback previously duplicated
    % in generateSLfromRawNlxData_baseline_global
    [evt.TimeStamps, evt.EventIDs, evt.TTLs, evt.Extras, evt.EventStrings] = ...
        Nlx2MatEV(filename_evt, [1 1 1 1 1], 0, 1, 0);
    stim_descriptor_Idx = find(cellfun(@(x) contains(x, 'Trial = '), evt.EventStrings, 'UniformOutput', true));
    stim_names2 = evt.EventStrings(stim_descriptor_Idx);
    vals = cellfun(@(s) sscanf(s, 'Trial = %d; Stim = %d;').', stim_names2, 'UniformOutput', false);
    M = vertcat(vals{:});
    TrialIDs = M(:,1);
    StimListID = M(:,2);
    if any(diff(TrialIDs) ~= 1)
        error('parseNlxTriggerInfo: trial numbers of triggers are not constantly counting up for %s', IC.SeriesID)
    end
end

idx_triggers = find(contains([evt.EventStrings(:)], '(0x0001)'));
if numel(idx_triggers) ~= num_of_trials
    error('parseNlxTriggerInfo: did not find the right number of triggers for stimulus presentations for %s', IC.SeriesID)
end

stim_list = zeros(num_of_trials,2);
stim_list(:,1) = StimListID;
stim_n_rep = zeros(num_applied_stimuli,1);
for iUnStim = names_applied_stimuli'
    iCurStim = find(stim_list(:,1) == iUnStim);
    stim_list(iCurStim,2) = 1:numel(iCurStim);
    stim_n_rep(names_applied_stimuli == iUnStim) = numel(iCurStim);
end

Trigger.NrTrigger = num_of_trials;
Trigger.TrigBeginTime = evt.TimeStamps(idx_triggers);
Trigger.RecordingBeginTime = evt.TimeStamps(IdxStartRecording);
Trigger.RecordingStopTime = evt.TimeStamps(IdxStopRecording);
Trigger.stim_list = stim_list;
Trigger.stim_n_rep = stim_n_rep;
Trigger.stim_names = names_applied_stimuli;
Trigger.n_stim = num_applied_stimuli;

end