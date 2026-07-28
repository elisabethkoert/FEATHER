function B = initBerabrFromNWB(B,abrModule, safeName, sessionStart)
% berabr/initBerabrFromNWB  Reconstruct a berabr object from one
% ElectricalSeries + companion stim table in an NWB file produced by
% exportDataNWBformat.m.
%
% Inputs:
%   B            – berabr object pre-constructed with correct ExpID/SeriesID
%   abrModule    – nwb.processing('abr')  (ProcessingModule)
%   safeName     – matlab.lang.makeValidName(SeriesID), used as NWB key prefix
%   sessionStart – datetime, nwb.session_start_time (for B.ExpInfo.c)
%
% Output:
%   B  – fully populated berabr (B.R is empty; B.F, B.Stim, B.C populated)
%
% Lossy fields (confirmed accepted):
%   B.F(ii) stim / t_stim  – not exported, left unset
%   B.R                                         – always empty (per saveBerabr)

% ---- locate the ElectricalSeries and stim table -------------------------
esKey    = sprintf('%s_waveforms', safeName);
stimKey  = sprintf('%s_stim_table', safeName);

if ~abrModule.nwbdatainterface.isKey(esKey)
    error('FEATHER:NWBImport:missingKey', ...
        'ElectricalSeries "%s" not found in abr processing module.', esKey);
end
if ~abrModule.dynamictable.isKey(stimKey)
    error('FEATHER:NWBImport:missingKey', ...
        'Stim table "%s" not found in abr processing module.', stimKey);
end

es        = abrModule.nwbdatainterface.get(esKey);
stimTable = abrModule.dynamictable.get(stimKey);

% ---- waveform matrix [nSamples x nTraces] --------------------------------
abrTraces = es.data.load();          % matNWB loads as double
[nSamples, nTraces] = size(abrTraces);

% ---- sampling rate & time vector -----------------------------------------
fs = es.starting_time_rate;   % Hz
% Reconstruct t as (0:nSamples-1)/fs - 0.001  (pre-trigger offset convention)
% then verify against starting_time offset which encodes abrOffset_s + t(1)
t_vec = (0:nSamples-1)' / fs - 0.001;   % seconds, relative to stimulus onset

% ---- B.ExpInfo.c: recording datetime for listBerabr date-sorting ---------
% starting_time = abrOffset_s + t_common(1)
% abrOffset_s   = seconds(recordingDatetime - sessionStart)
% => recordingDatetime = sessionStart + seconds(starting_time - t(1))
abrOffset_s      = es.starting_time - t_vec(1);
recordingDatetime = sessionStart + seconds(abrOffset_s);

B.ExpInfo(1).c = char(recordingDatetime);   % datetime->char matches listBerabr's datetime() call

% ---- read stim table columns ---------------------------------------------
nRows = numel(stimTable.id.data.load());
if nRows ~= nTraces
    warning('FEATHER:NWBImport:traceCountMismatch', ...
        '%s: stim table has %d rows but waveform matrix has %d columns.', ...
        B.SeriesID, nRows, nTraces);
    nTraces = min(nRows, nTraces);
end

% Helper: pull a full column from the DynamicTable as a plain array / cellstr
modality_col  = local_getStrCol(stimTable, 'modality');
hardware_col  = local_getStrCol(stimTable, 'stimulus_hardware');
mode_col      = local_getStrCol(stimTable, 'mode');
intensity_col = stimTable.vectordata.get('intensity').data(:);
unit_col      = local_getStrCol(stimTable, 'unit');
duration_col  = stimTable.vectordata.get('duration_s').data(:);   % seconds (fixed in export)
repRate_col   = stimTable.vectordata.get('rep_rate_Hz').data(:);
protocol_col  = local_getStrCol(stimTable, 'protocol');
laser_col     = stimTable.vectordata.get('laser_power_mW').data(:);

% ---- populate B.Stim(ii) per trace ---------------------------------------
S_template = struct('exp_li',[],'stimulusHardware','','anuTag',[], ...
    'modality','','mode','','unit','','duration',[],'intensity',[], ...
    'repRate',[],'protocol','');
B.Stim=S_template;% initialize once to avoid errors with dot indexing
for ii = 1:nTraces
    B.Stim(ii)               = S_template;
    B.Stim(ii).modality         = modality_col{ii};
    B.Stim(ii).stimulusHardware = hardware_col{ii};
    B.Stim(ii).mode             = mode_col{ii};
    B.Stim(ii).intensity        = intensity_col(ii);
    B.Stim(ii).unit             = unit_col{ii};
    B.Stim(ii).duration         = duration_col(ii) * 1000;  % back to ms (FEATHER convention)
    B.Stim(ii).repRate          = repRate_col(ii);
    B.Stim(ii).protocol         = protocol_col{ii};

    % anuTag from modality
    switch B.Stim(ii).modality
        case 'Acoustic';  B.Stim(ii).anuTag = 0;
        case 'Optical';   B.Stim(ii).anuTag = 1;
        case 'Electric';  B.Stim(ii).anuTag = 2;
        otherwise;        B.Stim(ii).anuTag = [];
    end
end

% ---- populate B.C.Ical ---------------------------------------------------
if all(isnan(laser_col))
    B.C = struct();   % acoustic – no calibration
else
    B.C(1).Ical = laser_col(:)';   % 1 x nTraces, matches FEATHER convention
end

% ---- populate B.F(ii) per trace ------------------------------------------
for ii = 1:nTraces
    B.F(ii).ABR    = abrTraces(:, ii)';
    B.F(ii).t      = t_vec';
    % lossy fields – leave as NaN to signal "not reconstructable"
    B.F(ii).stim    = NaN;
    B.F(ii).t_stim  = NaN;
    B.F(ii).filter  = NaN;   % filter info embedded in description only
end

% ---- B.nTraces -----------------------------------------------------------
B.nTraces = nTraces;

% ---- B.R stays empty (matches saveBerabr behaviour) ----------------------
B.R = [];

% note that the data was loaded from NWB
B.D(1).('type')="fromNWB";

end

% =========================================================================
function col = local_getStrCol(tbl, colName)
% Pull a VectorData string column from a DynamicTable as a cell array of char.
vd  = tbl.vectordata.get(colName);
raw = vd.data.load();
if iscell(raw)
    col = cellfun(@char, raw, 'UniformOutput', false);
elseif ischar(raw) || isstring(raw)
    col = cellstr(raw);
else
    col = arrayfun(@char, raw, 'UniformOutput', false);
end
col = col(:);
end