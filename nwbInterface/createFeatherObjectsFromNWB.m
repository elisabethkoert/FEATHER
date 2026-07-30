function ee = createFeatherObjectsFromNWB(nwb_filename, nwb_file_dir, varargin)
% createFeatherObjectsFromNWB  Top-level importer: reconstructs all FEATHER
% objects from one NWB file produced by exportDataNWBformat.m.
%
% Usage:
%   ee = createFeatherObjectsFromNWB('GEK030.nwb', 'C:\NWBdata')
%   ee = createFeatherObjectsFromNWB('GEK030.nwb', 'C:\NWBdata', ...
%           'overwrite', true, 'importIC', false)
%
% Name-value options:
%   'overwrite'    (logical, default false) – if false, hard-errors when any
%                  target file already exists (guards against wrong proc-dir /
%                  wrong userID slip-ups).
%   'importABR'    (logical, default true)
%   'importIC'     (logical, default true)
%   'importHisto'  (logical, default true)
%
% Output:
%   ee  – fully reconstructed anex object (RawDataDir intentionally unset;
%         call setRawDataDir manually if raw-data workflows are needed).

% ---- parse options -------------------------------------------------------
p = inputParser;
p.addParameter('overwrite',   false, @islogical);
p.addParameter('importABR',   true,  @islogical);
p.addParameter('importIC',    true,  @islogical);
p.addParameter('importHisto', true,  @islogical);
p.parse(varargin{:});
opt = p.Results;

overwrite   = opt.overwrite;
doABR       = opt.importABR;
doIC        = opt.importIC;
doHisto     = opt.importHisto;

% ---- force cache off for the entire import pipeline ---------------------
% (prevents stale on-disk objects being silently loaded mid-construction,
% and ensures listBerabr/listIcme/listHistImg always rescan disk at the end)
prevCache = enablecache();
enablecache('off');
restoreCacheOnCleanup = onCleanup(@() enablecache(prevCache));

% ---- read NWB file -------------------------------------------------------
nwbPath = fullfile(nwb_file_dir, nwb_filename);
if ~isfile(nwbPath)
    error('FEATHER:NWBImport:fileNotFound', 'NWB file not found: %s', nwbPath);
end
fprintf('Reading NWB file: %s\n', nwbPath);
nwb = nwbRead(nwbPath);

% =========================================================================
% STEP 1: RECONSTRUCT anex
% =========================================================================
fprintf('Reconstructing anex...\n');

ExpID          = char(nwb.identifier);
ExperimenterID = char(nwb.general_experimenter{1});
sessionStart   = local_nwbDatetime(nwb.session_start_time);

% Guard: E_<ExpID>.mat
procDir = expProcDataDir(ExperimenterID, ExpID);
guardExistingFile(fullfile(procDir, sprintf('E_%s.mat', ExpID)), overwrite, ...
    sprintf('anex %s', ExpID));

% Create the anex (3-arg,  RawDataDir explaining it is from NWB, cache off -> clean construction)
D(1).dir =nwb_file_dir;
D(1).type ="fromNWB";
ee = anex(ExpID, ExperimenterID, D);

% Species reverse-map (NWB controlled vocabulary -> FEATHER string)
subject = nwb.general_subject;
switch char(subject.species)
    case 'Meriones unguiculatus';  ee = setAnimalSpecies(ee, 'gerbil');
    case 'Mus musculus';           ee = setAnimalSpecies(ee, 'mouse');
    % 'unknown' -> leave unset (confirmed acceptable)
end

% ExperimenterID is stored verbatim (already uppercase in export)
ee = setExperimenterID(ee, ExperimenterID);

% ExpMetaData reconstruction
meta = struct();

% Age: parse P%iD
ageStr = char(subject.age);
ageTok = regexp(ageStr, '^P(\d+)D$', 'tokens', 'once');
if ~isempty(ageTok)
    meta.AgeDays = str2double(ageTok{1});
end

% DateOfBirth
if ~isempty(subject.date_of_birth)
    meta.DateOfBirth = local_nwbDatetime(subject.date_of_birth);
end

% Construct / injection info from Subject.description
descStr = char(subject.description);
if ~contains(descStr, 'no virus injection recorded')
    % Pattern: "virus injected with <Construct> at P<N>D" optionally "(titer: <T>)"
    tok = regexp(descStr, ...
        'virus injected with (.+?) at P(\d+)D', 'tokens', 'once');
    if ~isempty(tok)
        meta.Construct = strtrim(tok{1});
        injAgeDays     = str2double(tok{2});
        if isfield(meta,'DateOfBirth') && ~isempty(meta.DateOfBirth)
            meta.DateOfInjection = meta.DateOfBirth + days(injAgeDays);
        end
    end
    % Titer (optional suffix)
    titTok  = regexp(descStr, '\(titer: ([^)]+)\)', 'tokens', 'once')
    if ~isempty(titTok)
        meta.Titer = strtrim(titTok{1});
    end
end
% VirusBatch / TickAtLabID: permanently unrecoverable, left unset

% Gender: reverse-map sex field
switch char(subject.sex)
    case 'F'; meta.Gender = 'female';
    case 'M'; meta.Gender = 'male';
end

ee = setExpMetaData(ee, meta);

% UserID: set to current session's userID (not any reconstructed value)
ee = setUserID(ee);

% Create the processed-data folder if it doesn't exist yet
if ~isfolder(procDir)
    mkdir(procDir);
end
saveAnex(ee);
fprintf('  anex saved: %s\n', fullfile(procDir, sprintf('E_%s.mat', ExpID)));

% =========================================================================
% STEP 2: ABR RECORDINGS
% =========================================================================
if doABR && nwb.processing.isKey('abr')
    fprintf('Importing ABR recordings...\n');
    abrModule = nwb.processing.get('abr');
    Bs        = listBerabr(ee);   % will be empty first time, used to avoid duplicates
    abrKeys   = abrModule.nwbdatainterface.keys();

    % Collect waveform keys (end in _waveforms)
    waveKeys = abrKeys(cellfun(@(k) endsWith(k,'_waveforms'), abrKeys));

    for kk = 1:numel(waveKeys)
        wKey     = waveKeys{kk};
        safeName = wKey(1:end-length('_waveforms'));

        % Recover original SeriesID from the ElectricalSeries description
        es       = abrModule.nwbdatainterface.get(wKey);
        seriesID = local_recoverABRSeriesID(es.description, safeName);

        bFile = fullfile(procDir, sprintf('B_%s_%s.mat', ExpID, seriesID));
        guardExistingFile(bFile, overwrite, sprintf('berabr %s', seriesID));

        fprintf('  %s ... ', seriesID);

        % Construct a shell berabr
        B = berabr(ee, seriesID);
        % Populate from NWB
        B = initBerabrFromNWB(B,abrModule, safeName, sessionStart);

        saveBerabr(B);
        fprintf('saved.\n');
    end
end

% =========================================================================
% STEP 3: IC RECORDINGS
% =========================================================================
if doIC && nwb.processing.isKey('ic_metadata')
    fprintf('Importing IC recordings...\n');

    icModule = nwb.processing.get('ic_metadata');

    % Create ICME subfolder structure if needed (no saveAnex side-effect)
    icDir = fullfile(procDir, 'ICME', 'IC');
    if ~isfolder(icDir); mkdir(icDir); end

    % Discover unique recording IDs from _stimlist table names
    icTableKeys   = icModule.dynamictable.keys();
    stimlistKeys  = icTableKeys(cellfun(@(k) endsWith(k,'_stimlist'), icTableKeys));

    for kk = 1:numel(stimlistKeys)
        sKey     = stimlistKeys{kk};
        safeName = sKey(1:end-length('_stimlist'));

        % Recover original SeriesID from stimlist table description
        stimTbl  = icModule.dynamictable.get(sKey);
        seriesID = local_recoverICSeriesID(stimTbl.description, safeName, ExpID);

        icFile = fullfile(icDir, sprintf('IC_%s_%s.mat', ExpID, seriesID));
        guardExistingFile(icFile, overwrite, sprintf('icme %s', seriesID));

        fprintf('  %s ... ', seriesID);

        % Shell icme (2-arg – RawDataDir set to IC from anex is irrelevant
        % since we never touch raw data, but icme constructor tries ee.RawDataDir;
        % ee.RawDataDir is empty so no IC type entry exists -> D left empty)
        IC = icme(ee, seriesID);
        IC = initIcmeFromNWB(IC, nwb, icModule, seriesID, sessionStart);

        saveIcme(IC);
        fprintf('saved.\n');
    end
end

% =========================================================================
% STEP 4: HISTOLOGY
% =========================================================================
if doHisto && nwb.processing.isKey('histology')
    fprintf('Importing histology...\n');

    histoModule = nwb.processing.get('histology');
    if ~histoModule.dynamictable.isKey('histology_results')
        warning('FEATHER:NWBImport:missingHistoTable', ...
            'histology processing module found but no histology_results table.');
    else
        histoTable = histoModule.dynamictable.get('histology_results');
        nImg       = numel(histoTable.id.data.load());

        histoDir = fullfile(procDir, 'HISTO');
        if ~isfolder(histoDir); mkdir(histoDir); end

        seriesIDcol = histoTable.vectordata.get('series_id').data.load();
        if ~iscell(seriesIDcol); seriesIDcol = cellstr(seriesIDcol); end

        for iImg = 1:nImg
            seriesID = char(seriesIDcol{iImg});

            hFile = fullfile(histoDir, sprintf('H_%s_%s.mat', ExpID, seriesID));
            guardExistingFile(hFile, overwrite, sprintf('histimg %s', seriesID));

            fprintf('  %s ... ', seriesID);

            H = histimg(ee, seriesID);
            H = initHistImgFromNWB(H, histoTable, iImg);

            saveHistimg(H);
            fprintf('saved.\n');
        end
    end
end

% =========================================================================
% STEP 5: USER-INPUT / ANNOTATION FILES
% =========================================================================
if nwb.processing.isKey('feather_annotations')
    fprintf('Writing companion user-input files...\n');
    annotModule = nwb.processing.get('feather_annotations');
    icDir       = fullfile(procDir, 'ICME');
    histoDir    = fullfile(procDir, 'HISTO');

    % ---- ABR wave annotations -> W_<ExpID>_<SeriesID>.mat ---------------
    if annotModule.dynamictable.isKey('abr_wave_annotations')
        waveAnnotTable = annotModule.dynamictable.get('abr_wave_annotations');
        waveFile = local_writeWaveAnnotations(waveAnnotTable, ExpID, procDir, overwrite);
        fprintf('  Wave annotation files written (%d recordings).\n', numel(waveFile));
    end

    % ---- IC user input -> ICME/ICUserInput_<ExpID>.mat ------------------
    if annotModule.dynamictable.isKey('ic_user_input') && doIC
        icUITable = annotModule.dynamictable.get('ic_user_input');
        UT = local_UTTableToStruct(icUITable);
        icUIfile = fullfile(icDir, sprintf('ICUserInput_%s.mat', ExpID));
        guardExistingFile(icUIfile, overwrite, sprintf('ICUserInput_%s', ExpID));
        if ~isfolder(icDir); mkdir(icDir); end
        % also get electrode information to add in the file
        IC_MEA=nwb.general_devices.get('IC_MEA');
        
        Electrode=struct();
        Electrode.depth=0;
        Electrode.name=IC_MEA.serial_number;
        % nwb format should always only save the calibrated stimlists
        CalibrationDone=true;
        save(icUIfile, 'UT','CalibrationDone','Electrode');
        fprintf('  ICUserInput_%s.mat written.\n', ExpID);
    end

    % ---- Histo user input -> HISTO/HistoUserInput_<ExpID>.mat -----------
    if annotModule.dynamictable.isKey('histo_user_input') && doHisto
        histoUITable = annotModule.dynamictable.get('histo_user_input');
        HistoTable   = local_UTTableToStruct(histoUITable);
        % getHistoResults / chooseHistImgToUse expect variable name 'HistoTable'
        histoUIfile  = fullfile(histoDir, sprintf('HistoUserInput_%s.mat', ExpID));
        guardExistingFile(histoUIfile, overwrite, sprintf('HistoUserInput_%s', ExpID));
        if ~isfolder(histoDir); mkdir(histoDir); end
        save(histoUIfile, 'HistoTable');
        fprintf('  HistoUserInput_%s.mat written.\n', ExpID);
    end

    % ---- ABR OD user input -> ODui_<ExpID>.mat (optional, provenance) ---
    if annotModule.dynamictable.isKey('abr_user_input')
        abrUITable = annotModule.dynamictable.get('abr_user_input');
        UT         = local_UTTableToStruct(abrUITable);
        odFile     = fullfile(procDir, sprintf('ODui_%s.mat', ExpID));
        guardExistingFile(odFile, overwrite, sprintf('ODui_%s', ExpID));
        save(odFile, 'UT');
        fprintf('  ODui_%s.mat written.\n', ExpID);
    end
end

% =========================================================================
% STEP 6: REFRESH CACHED LISTS
% =========================================================================
fprintf('Refreshing lists...\n');
if doABR;   listBerabr(ee);   end
if doIC;    listIcme(ee);     end
if doHisto; listHistImg(ee);  end

fprintf('Import complete for %s.\n', ExpID);
end

% =========================================================================
% LOCAL HELPERS
% =========================================================================

function seriesID = local_recoverABRSeriesID(description, safeName)
% Try to recover the original SeriesID from the ElectricalSeries description:
%   'Averaged, filtered ABR waveforms for recording <SeriesID>. ...'
tok = regexp(description, 'waveforms for recording ([^\. ]+)', 'tokens', 'once');
if ~isempty(tok)
    seriesID = strtrim(tok{1});
else
    % Fallback: invert makeValidName as best we can (heuristic only)
    % Most SeriesIDs are of the form YYYYMMDD_HHMMSS_BERA or similar
    % with underscores; makeValidName just adds 'x' prefix for digit-starts
    seriesID = safeName;
    if startsWith(safeName, 'x') && ~isempty(regexp(safeName(2), '\d', 'once'))
        seriesID = safeName(2:end);
    end
    seriesID = strrep(seriesID, '_', '-');   % crude heuristic only
    warning('FEATHER:NWBImport:seriesIDFallback', ...
        'Could not recover ABR SeriesID from description; using heuristic: %s', seriesID);
end
end

function seriesID = local_recoverICSeriesID(description, safeName, ExpID)
% Try to recover SeriesID from stimlist table description:
%   'Stimulus conditions for IC recording <SeriesID> (exp_type: ...)'
tok = regexp(description, 'for IC recording ([^\s(]+)', 'tokens', 'once');
if ~isempty(tok)
    seriesID = strtrim(tok{1});
else
    seriesID = safeName;
    warning('FEATHER:NWBImport:seriesIDFallback', ...
        'Could not recover IC SeriesID from description; using: %s', seriesID);
end
end

function writtenFiles = local_writeWaveAnnotations(waveAnnotTable, ExpID, procDir, overwrite)
% Reconstruct W_<ExpID>_<SeriesID>.mat files from the abr_wave_annotations
% DynamicTable.  One file per unique recording_id that has annotation rows.
%
% W struct array convention (per berabrWaveGUI2 / importWaves.m):
%   W(jj).A   [2 x 5] amplitudes   (squeezed from [1 x 2 x 5])
%   W(jj).t   [2 x 5] latencies
%   W(jj).ii  [2 x 5] sample indices
%   W(jj).ExpID    char
%   W(jj).SeriesID char
%   jj = trace index (1-based)

writtenFiles = {};

nRows = numel(waveAnnotTable.id.data);
if nRows == 0; return; end

recIDcol     = waveAnnotTable.vectordata.get('recording_id').data.load();
traceIdxCol  = int64(waveAnnotTable.vectordata.get('trace_index').data(:));
amplData     = waveAnnotTable.vectordata.get('amplitude').data.load();    % [nRows x 2 x 5]
latData      = waveAnnotTable.vectordata.get('latency').data.load();      % [nRows x 2 x 5]
sampData     = waveAnnotTable.vectordata.get('sample_index').data.load(); % [nRows x 2 x 5]

if iscell(recIDcol)
    recIDcol = cellfun(@char, recIDcol, 'UniformOutput', false);
else
    recIDcol = cellstr(recIDcol);
end

uniqueRecs = unique(recIDcol, 'stable');

for uIdx = 1:numel(uniqueRecs)
    curSeries = uniqueRecs{uIdx};
    rowsThis  = find(strcmp(recIDcol, curSeries));

    % Determine how many traces this recording had
    % (trace indices are 1-based, continuous from 1 to nTraces)
    maxTrace = max(double(traceIdxCol(rowsThis)));

    % Pre-allocate W with NaN so un-annotated traces remain NaN
    W = struct();
    for jj = 1:maxTrace
        W(jj).A        = NaN(2, 5);
        W(jj).t        = NaN(2, 5);
        W(jj).ii       = NaN(2, 5);
        W(jj).ExpID    = ExpID;
        W(jj).SeriesID = curSeries;
    end

    for rIdx = rowsThis'
        jj = double(traceIdxCol(rIdx));
        % amplData is [nRows x 2 x 5] – squeeze row dimension
        W(jj).A  = squeeze(amplData(rIdx, :, :));
        W(jj).t  = squeeze(latData(rIdx, :, :));
        W(jj).ii = squeeze(sampData(rIdx, :, :));
    end

    wFile = fullfile(procDir, sprintf('W_%s_%s.mat', ExpID, curSeries));
    guardExistingFile(wFile, overwrite, sprintf('W_%s_%s', ExpID, curSeries));
    save(wFile, 'W');
    writtenFiles{end+1} = wFile; %#ok<AGROW>
end
end

function tf = endsWith(str, suffix)
% Simple suffix check compatible with pre-R2016b MATLAB
tf = numel(str) >= numel(suffix) && strcmp(str(end-numel(suffix)+1:end), suffix);
end