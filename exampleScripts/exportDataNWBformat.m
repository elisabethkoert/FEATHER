%% example script explaining how to export data from FEATHER into the NWB format
%% still in development

%% 1) Select one animal experiment
ExpID = "GEK030";
experimenterID = "test";

enablecache on
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);

%% Create NWB file
sessionStart = ee.ExpMetaData.DateOfExperiment;
nwb = NwbFile( ...
    'session_description', sprintf('Evaluating Optogenetic Stimulation of Auditory System for %s', ExpID), ...
    'identifier', sprintf('%s', ExpID), ...
    'session_start_time', sessionStart, ...
    'general_experimenter', {char(experimenterID)}, ...
    'general_lab', 'Institute for Auditory Neuroscience', ...
    'general_institution', 'University Medical Center Goettingen');

%% Add info about the animal

if ee.Species=='gerbil'
    species='Meriones unguiculatus';
elseif ee.Species=='mouse'
    species='Mus musculus';
else
    species='unknown';
end

if ee.ExpMetaData.Gender=='female'
    sex='F';
elseif ee.ExpMetaData.Gender=='male'
    sex='M';
else
    sex='unknown';
end

subject = types.core.Subject( ...
    'subject_id', sprintf('%s', ExpID), ...
    'age', sprintf('P%iD', ee.ExpMetaData.AgeDays), ...
    'age_reference','birth',...
    'species', species, ...
    'genotype','WT',...
    'description',sprintf('virus injected with %s at P%iD', ee.ExpMetaData.Construct,days(ee.ExpMetaData.DateOfExperiment-ee.ExpMetaData.DateOfBirth)),...
    'sex', sex ...
);
nwb.general_subject = subject;

%% Add general optogenetics info


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
            'data_unit', 'microvolts', ...
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

nwbtest=nwbRead('C:\Users\koert.GWDG\localData\rawData\GEK030\sub-GEK030_ses-recording1.nwb');
