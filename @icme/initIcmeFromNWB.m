function IC = initIcmeFromNWB(IC, nwb, icModule, recordingID, sessionStart)
% icme/initIcmeFromNWB  Reconstruct one icme object from the NWB file
% produced by exportDataNWBformat.m.
%
% Inputs:
%   IC          – icme object pre-constructed with correct ExpID/SeriesID
%   nwb         – NwbFile (nwbRead output)
%   icModule    – nwb.processing('ic_metadata')
%   recordingID – char SeriesID string (e.g. 'GEK030_0004')
%   sessionStart– datetime, nwb.session_start_time
%
% Output:
%   IC – fully populated icme (IC.SL, IC.Stim, IC.ExpInfo populated;
%        IC.C empty; IC.R empty)
%
% Confirmed lossy fields (accepted):
%   IC.SL.Trigger.RecordingBeginTime / RecordingStopTime  – left NaN
%   (stim_id,rep) combos with zero spikes across all 32 channels get NaN
%   trigger time with a warning
%   Spikelist columns 3 & 5 – set to NaN (confirmed unused)
%   IC.C – left empty

safeName = matlab.lang.makeValidName(recordingID);

% =========================================================================
% 1. STIMLIST TABLE
% =========================================================================
stimKey = sprintf('%s_stimlist', safeName);
if ~icModule.dynamictable.isKey(stimKey)
    error('FEATHER:NWBImport:missingKey', ...
        'Stimlist table "%s" not found in ic_metadata module.', stimKey);
end
stimTable = icModule.dynamictable.get(stimKey);

% Recover original stimheader names from each column's description field
colNames_sanitized = stimTable.colnames;
% Remove stim_duration_s – that is not part of the original stimheader
isDuraCol  = strcmp(colNames_sanitized, 'stim_duration_s');
stimCols   = colNames_sanitized(~isDuraCol);
nCols      = numel(stimCols);
nCond      = numel(stimTable.id.data.load());

stimheader  = cell(1, nCols);
stimlist    = zeros(nCond, nCols);

for iCol = 1:nCols
    vd = stimTable.vectordata.get(stimCols{iCol});
    % Recover original name from description:
    %   'Stimulus parameter "<origName>" (raw ExpControl stimheader column N)'
    tok = regexp(vd.description, 'Stimulus parameter "([^"]+)"', 'tokens', 'once');
    if ~isempty(tok)
        stimheader{iCol} = tok{1};
    else
        stimheader{iCol} = stimCols{iCol};   % sanitized fallback
    end
    stimlist(:, iCol) = double(vd.data(:));
end

% stim_duration_s column -> IC.Stim.dura
duraCold = stimTable.vectordata.get('stim_duration_s').data(:);

% =========================================================================
% 2. ANALYSIS-PARAMETERS TABLE (one row per recording)
% =========================================================================
if ~icModule.dynamictable.isKey('analysis_parameters')
    error('FEATHER:NWBImport:missingKey', ...
        'analysis_parameters table not found in ic_metadata module.');
end
apTable = icModule.dynamictable.get('analysis_parameters');

% Find row index for this recording
recIDcol   = apTable.vectordata.get('recording_id').data.load();
if iscell(recIDcol)
    recIDcol = cellfun(@char, recIDcol, 'UniformOutput', false);
else
    recIDcol = cellstr(recIDcol);
end
apRow = find(strcmp(recIDcol, recordingID), 1);
if isempty(apRow)
    error('FEATHER:NWBImport:missingRow', ...
        'No analysis_parameters row found for recording "%s".', recordingID);
end

local_ap = @(colname) local_apVal(apTable, colname, apRow);

ap.threshold            = local_ap('threshold');
ap.pre_time             = local_ap('pre_time');
ap.post_time            = local_ap('post_time');
ap.ref_time             = local_ap('ref_time');
ap.low_filt             = local_ap('low_filt');
ap.high_filt            = local_ap('high_filt');
ap.filt_ord             = local_ap('filt_ord');
ap.prestimrectime       = local_ap('prestimrectime');
ap.poststimrectime      = local_ap('poststimrectime');
ap.use_artefact_removal = logical(local_ap('use_artefact_removal'));
ap.MUEdate              = local_apStr(apTable, 'MUEdate', apRow);
ap.GitHash              = local_apStr(apTable, 'GitHash', apRow);
ap.GitBranch            = local_apStr(apTable, 'GitBranch', apRow);

% waveform_threshold_low: stored as nRecordings x 32 matrix
waveThreshRaw = apTable.vectordata.get('waveform_threshold_low').data.load();
ap.waveform_threshold_low = double(waveThreshRaw(apRow, :));   % 1x32

% exp_type from this same table (the clean exported column)
expTypeCell = apTable.vectordata.get('exp_type').data.load();
if iscell(expTypeCell)
    expType = char(expTypeCell{apRow});
else
    expType = char(expTypeCell(apRow));
end

% =========================================================================
% 3. EXTRACT ROWS FROM nwb.units FOR THIS RECORDING
% =========================================================================
units = nwb.units;

% Non-ragged scalar columns
recIDunits = units.vectordata.get('recording_id').data.load();
if iscell(recIDunits)
    recIDunits = cellfun(@char, recIDunits, 'UniformOutput', false);
else
    recIDunits = cellstr(recIDunits);
end
stimIDcol    = int64(units.vectordata.get('stim_id').data(:));
electrodeCol = int64(units.electrodes.data(:));

% Row mask for this recording
rowMask = strcmp(recIDunits, recordingID);
rowIdxs = find(rowMask);

if isempty(rowIdxs)
    error('FEATHER:NWBImport:noUnitsRows', ...
        'No Units rows found for recording "%s".', recordingID);
end

% Ragged columns
spikeTimesCell   = readRaggedNWBColumn(units, 'spike_times');
relTriggerCell   = readRaggedNWBColumn(units, 'spike_time_rel_trigger');
spikeRepCell     = readRaggedNWBColumn(units, 'spike_rep');

% IC electrode offset (ABR uses rows 0,1,2 -> IC starts at row 3)
IC_ELEC_OFFSET = 3;

% =========================================================================
% 4. RECONSTRUCT TRIGGER TIMING (SL.Trigger)
% =========================================================================
% For each (stim_id, rep) trial, trigger_time_session_relative =
%   spike_times - spike_time_rel_trigger
% We then collect all unique triggers, compute their session-relative
% datetime, and convert back to posix-µs (the NLX convention parseNlxTriggerInfo
% uses) so the format is exactly what downstream functions expect.
%
% nStim is recovered from the stimlist (nCond rows).
nStim = nCond;

% Determine n_rep from max observed spike_rep across all rows for this recording
maxRepObserved = 0;
for idx = rowIdxs'
    reps = spikeRepCell{idx};
    if ~isempty(reps)
        maxRepObserved = max(maxRepObserved, max(double(reps(:))));
    end
end
nRep = maxRepObserved;
if nRep == 0
    nRep = 30;   % pathological fallback: zero spikes in all rows
    warning('FEATHER:NWBImport:noSpikesForNRep', ...
        '%s: could not determine n_rep from spikes (all rows empty). Defaulting to 30.', ...
        recordingID);
end
if nRep ~= 30
    warning('FEATHER:NWBImport:unexpectedNRep', ...
        '%s: reconstructed n_rep = %d (expected 30 per FEATHER convention).', ...
        recordingID, nRep);
end

% trigTimeLUT_dt(stim_id, rep) = session-relative datetime of trigger
% (NaN where no spikes observed for that trial)
trigTimeLUT_s   = nan(nStim, nRep);   % seconds rel session_start

for idx = rowIdxs'
    sTimes  = double(spikeTimesCell{idx}(:));   % session-relative s
    relT    = double(relTriggerCell{idx}(:));   % s after trigger
    repNums = double(spikeRepCell{idx}(:));
    curStimID = double(stimIDcol(idx));

    if isempty(sTimes)
        continue
    end

    % trigger_session_rel = spike_session_rel - spike_rel_trigger
    trigTimes_s = sTimes - relT;

    % Group by rep, keep one representative per (stimID, rep)
    for iSpk = 1:numel(trigTimes_s)
        r = repNums(iSpk);
        if r < 1 || r > nRep; continue; end
        if isnan(trigTimeLUT_s(curStimID, r))
            trigTimeLUT_s(curStimID, r) = trigTimes_s(iSpk);
        end
    end
end

% Build stim_list: NrTrigger x 2 [stim_id, rep], ordered by trial order
% We reconstruct trial order as the sort of trigger times across all cells
trialStimID  = [];
trialRep     = [];
trialTrigS   = [];

for sID = 1:nStim
    for r = 1:nRep
        if ~isnan(trigTimeLUT_s(sID, r))
            trialStimID(end+1)  = sID;   %#ok<AGROW>
            trialRep(end+1)     = r;     %#ok<AGROW>
            trialTrigS(end+1)   = trigTimeLUT_s(sID, r); %#ok<AGROW>
        end
    end
end

% Sort by trigger time to recover presentation order
[trialTrigS_sorted, sortIdx] = sort(trialTrigS);
trialStimID = trialStimID(sortIdx);
trialRep    = trialRep(sortIdx);

NrTrigger    = numel(trialTrigS_sorted);
stim_list    = [trialStimID(:), trialRep(:)];

% Convert session-relative seconds back to posix-µs (NLX convention)
% sessionStart is a datetime; posixtime() gives seconds since 1970 epoch
sessionStart_posix_s = posixtime(sessionStart);
TrigBeginTime_posix_us = (trialTrigS_sorted + sessionStart_posix_s) * 1e6;

% Warn on (stim_id, rep) combos with no observed spikes (trigger time = NaN)
nExpectedTrials = nStim * nRep;
nFoundTrials    = NrTrigger;
if nFoundTrials < nExpectedTrials
    warning('FEATHER:NWBImport:missingTriggerTimes', ...
        ['%s: %d / %d (stim_id,rep) trial combinations had zero spikes ' ...
         'on all 32 electrodes; their trigger times are unrecoverable (NaN). ' ...
         'These trials are omitted from SL.Trigger.stim_list.'], ...
        recordingID, nExpectedTrials - nFoundTrials, nExpectedTrials);
end

% stim_n_rep, stim_names, n_stim
names_applied = unique(stim_list(:,1));
nStimApplied  = numel(names_applied);
stim_n_rep    = zeros(nStimApplied, 1);
for k = 1:nStimApplied
    stim_n_rep(k) = sum(stim_list(:,1) == names_applied(k));
end

Trigger.NrTrigger          = NrTrigger;
Trigger.TrigBeginTime      = TrigBeginTime_posix_us;
Trigger.RecordingBeginTime = NaN;   % not exported – confirmed acceptable
Trigger.RecordingStopTime  = NaN;   % not exported – confirmed acceptable
Trigger.stim_list          = stim_list;
Trigger.stim_n_rep         = stim_n_rep;
Trigger.stim_names         = names_applied;
Trigger.n_stim             = nStimApplied;

% IC.ExpInfo.datetime: earliest trigger time, for listIcme date-sorting
if ~isempty(trialTrigS_sorted)
    firstTrigDT = sessionStart + seconds(trialTrigS_sorted(1));
    IC.ExpInfo(1).datetime = char(firstTrigDT);
else
    IC.ExpInfo.datetime = '';
end

% =========================================================================
% 5. RECONSTRUCT SPIKELIST (SL.spik_list_all)
% =========================================================================
% Standard electrode names elec0..elec31 (0-based numbering)
all_electrode_names = cell(1, 32);
for e = 0:31
    all_electrode_names{e+1} = sprintf('elec%d', e);
end
all_electrodes = (0:31)';

spik_list_all = struct();
for e = 0:31
    spik_list_all.(all_electrode_names{e+1}) = zeros(0, 6);
end

for idx = rowIdxs'
    % electrode index (0-based) from the combined electrode table row
    elecTableRow = double(electrodeCol(idx));   % 0-based row in combinedElecTable
    elecNum      = elecTableRow - IC_ELEC_OFFSET;   % 0-based electrode number

    if elecNum < 0 || elecNum > 31
        warning('FEATHER:NWBImport:unexpectedElectrode', ...
            '%s row %d: electrode table row %d maps to elecNum %d (out of range 0-31), skipping.', ...
            recordingID, idx, elecTableRow, elecNum);
        continue
    end

    curStimID = double(stimIDcol(idx));

    % Pull ragged spike data; apply (:) defensively (orientation quirk)
    sTimes  = double(spikeTimesCell{idx}(:));
    relT    = double(relTriggerCell{idx}(:));
    repNums = double(spikeRepCell{idx}(:));

    if isempty(sTimes)
        continue
    end

    nSpk = numel(sTimes);

    % FEATHER Spik_list columns:
    %  1: stim_id   2: n_rep   3: ypos (NaN)   4: chan (elecNum)
    %  5: unit_id (NaN)        6: time_after_trigger [s]
    spkBlock = [
        repmat(curStimID, nSpk, 1), ...   col 1
        double(repNums),            ...   col 2
        nan(nSpk, 1),               ...   col 3 (confirmed unused)
        repmat(double(elecNum), nSpk, 1), ... col 4
        nan(nSpk, 1),               ...   col 5 (confirmed unused)
        double(relT)                ...   col 6
    ];

    fname = all_electrode_names{elecNum + 1};
    spik_list_all.(fname) = [spik_list_all.(fname); spkBlock];
end

% =========================================================================
% 6. ASSEMBLE IC.SL
% =========================================================================
IC.SL(1).spik_list_all     = spik_list_all;
IC.SL.all_electrode_names = all_electrode_names;
IC.SL.all_electrodes    = all_electrodes;
IC.SL.analysis_parameters = ap;
IC.SL.Trigger           = Trigger;

% =========================================================================
% 7. ASSEMBLE IC.Stim
% =========================================================================
IC.Stim(1).exp_type   = expType;
IC.Stim.stimlist   = stimlist;
IC.Stim.stimheader = stimheader;
IC.Stim.dura       = duraCold;   % seconds (from stim_duration_s column)
IC.Stim.n_rep      = nRep;




% =========================================================================
% 8. ASSEMBLE IC.ExpInfo (minimal – matches what downstream functions read)
% =========================================================================
IC.ExpInfo.exp_type = expType;   % duplicated on both structs per FEATHER convention

% =========================================================================
% 9. IC.C (calibration not stored separately) but the loaded stimlist
% should be the calibrated one, since that is what gets saved when it exist
% =========================================================================
IC.C(1).stimlistCal=stimlist;   

% =========================================================================
% 10. IC.R stays empty
% =========================================================================
IC.R = struct();

% note that the data was loaded from NWB
IC.D(1).('type')="fromNWB";


end

% =========================================================================
% Local helpers
% =========================================================================
function val = local_apVal(tbl, colname, rowIdx)
val = double(tbl.vectordata.get(colname).data(rowIdx));
end

function s = local_apStr(tbl, colname, rowIdx)
raw = tbl.vectordata.get(colname).data;
if iscell(raw)
    s = char(raw{rowIdx});
elseif ischar(raw) || isstring(raw)
    s = char(raw(rowIdx));
else
    s = '';
end
end