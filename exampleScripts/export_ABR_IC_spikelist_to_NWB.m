%% Example: export ABR + IC spikelist of one animal to NWB (matnwb)
% Required matnwb/NWB functions used below:
%   - NwbFile
%   - types.core.TimeSeries
%   - types.core.ProcessingModule
%   - nwbExport
% Optional for verification:
%   - nwbRead
%
% Notes:
%   - ABR traces are exported as acquisition TimeSeries (one per ABR recording)
%   - IC spikelist data are exported as TimeSeries in a processing module
%     (one per electrode, timestamps = spike times after trigger in seconds)

clearvars; close all;

%% 0) Make sure FEATHER + matnwb are on your MATLAB path before running
% addpath(genpath('<path-to-FEATHER>'));
% addpath(genpath('<path-to-matnwb>'));
% If needed once per matnwb install:
% generateCore();

%% 1) Select one animal experiment
ExpID = "GEK030";
experimenterID = "test";

enablecache on
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);

%% 2) Create NWB file
sessionStart = datetime('now', 'TimeZone', 'local');
nwb = NwbFile( ...
    'session_description', sprintf('FEATHER export for %s', ExpID), ...
    'identifier', sprintf('%s_%s', ExpID, datestr(now, 'yyyymmddTHHMMSS')), ...
    'session_start_time', sessionStart, ...
    'general_experimenter', {char(experimenterID)}, ...
    'general_lab', 'Institute for Auditory Neuroscience', ...
    'general_institution', 'University Medical Center Goettingen');

%% 3) Export ABR data (processed FEATHER traces)
enablecache on
LABR = listBerabr(ee);
if ~isempty(LABR.ABR_SeriesID) && ~all(ismissing(LABR.ABR_SeriesID))
    abrSeries = string(LABR.ABR_SeriesID);
    abrSeries = abrSeries(~ismissing(abrSeries));

    for iA = 1:numel(abrSeries)
        B = loadBerabr(berabr(ee, abrSeries(iA)));
        if isempty(B.F)
            continue
        end

        traceData = nan(numel(B.F(1).t), numel(B.F));
        for iTrace = 1:numel(B.F)
            y = B.F(iTrace).ABR(:);
            if numel(y) == size(traceData, 1)
                traceData(:, iTrace) = y;
            end
        end

        tsName = matlab.lang.makeValidName(sprintf('ABR_%s', B.SeriesID));
        ts = types.core.TimeSeries( ...
            'data', traceData, ...
            'data_unit', 'volts', ...
            'timestamps', B.F(1).t(:), ...
            'description', sprintf('ABR traces (columns) for %s', B.SeriesID));
        nwb.acquisition.set(tsName, ts);
    end
end

%% 4) Export IC spikelists (per electrode)
LIC = listIcme(ee);
if ~isempty(LIC.IC_SeriesID) && ~all(ismissing(LIC.IC_SeriesID))
    icModule = types.core.ProcessingModule( ...
        'description', 'IC multi-unit spikelists exported from FEATHER');
    nwb.processing.set('ic_spikelists', icModule);

    icSeries = string(LIC.IC_SeriesID);
    icSeries = icSeries(~ismissing(icSeries));

    for iIC = 1:numel(icSeries)
        IC = loadIcme(icme(ee, icSeries(iIC)));
        if ~isfield(IC, 'SL') || ~isfield(IC.SL, 'all_electrode_names') || ~isfield(IC.SL, 'spik_list_all')
            continue
        end

        elecNames = IC.SL.all_electrode_names;
        for iE = 1:numel(elecNames)
            elecName = elecNames{iE};
            if ~isfield(IC.SL.spik_list_all, elecName)
                continue
            end

            spk = IC.SL.spik_list_all.(elecName);
            if isempty(spk) || size(spk, 2) < 6
                continue
            end

            % FEATHER spikelist column 6 = time after trigger in ms
            spikeTimeAfterTrigger_s = spk(:, 6) ./ 1000;
            if isempty(spikeTimeAfterTrigger_s)
                continue
            end

            tsName = matlab.lang.makeValidName(sprintf('%s_%s', IC.SeriesID, elecName));
            spikeEvents = ones(size(spikeTimeAfterTrigger_s));
            ts = types.core.TimeSeries( ...
                'data', spikeEvents, ...
                'data_unit', 'event', ...
                'timestamps', spikeTimeAfterTrigger_s(:), ...
                'description', sprintf(['Spike events for %s (%s). ' ...
                'Timestamps are FEATHER spikelist times after trigger.'], IC.SeriesID, elecName));
            icModule.nwbdatainterface.set(tsName, ts);
        end
    end
end

%% 5) Write NWB file
outDir = expProcDataDir(ee.ExperimenterID, ee.ExpID);
outFile = fullfile(outDir, sprintf('%s_ABR_IC_spikelist.nwb', ExpID));
nwbExport(nwb, outFile);
fprintf('NWB export finished: %s\n', outFile);

%% 6) Optional quick readback check
% nwbIn = nwbRead(outFile);
% disp(nwbIn.acquisition.keys)
