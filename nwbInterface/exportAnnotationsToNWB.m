function nwb = exportAnnotationsToNWB(nwb, ee, wave_annotations, exportedABRIDs, exportedICIDs, exportedHistoIDs)
% exportAnnotationsToNWB  Bundles manual user-input tables and ABR wave annotations.
%  Bundles copies of the manual annotation tables (ICUserInput,
%  HistoUserInput, ODui) and ABR wave-peak clicks (W_ files) into the same
%  NWB file, so that someone starting only from this NWB file can rerun
%  every FEATHER analysis function that depends on manual curation and get
%  to the same results. Of course users are free to use other 
%   Inputs:
%       nwb             - NWB object
%       ee              - anex object
%       wave_annotations - struct from ABR export
%       exportedABRIDs  - string array of ABR SeriesIDs that were exported
%       exportedICIDs   - string array of IC SeriesIDs that were exported
%       exportedHistoIDs- string array of Histo SeriesIDs that were exported

    feather_annotations_module = types.core.ProcessingModule(...
        'description', ['Copies of FEATHER manual user-input annotation tables' ...
        'and ABR wave-peak click annotations.']);

    % ---- ABR wave-peak annotations ----
    if isfield(wave_annotations, 'recordingID') && ~isempty(wave_annotations.recordingID)
        nWaveRows = numel(wave_annotations.recordingID);
        abrWaveTable = types.hdmf_common.DynamicTable(...
            'description', ['Manual ABR wave-peak annotations W_<ExpID>_<SeriesID>.mat).  ' ...
            'NaN entries mean the user did not annotate that peak.'], ...
            'colnames', {'recording_id','trace_index','amplitude','latency','sample_index'});

        abrWaveTable.vectordata.set('recording_id', types.hdmf_common.VectorData(...
            'data', wave_annotations.recordingID, 'description','berabr SeriesID'));
        abrWaveTable.vectordata.set('trace_index', types.hdmf_common.VectorData(...
            'data', int64(wave_annotations.traceIndex), ...
            'description','1-based trace/stimulus-condition index'));
        abrWaveTable.vectordata.set('amplitude', types.hdmf_common.VectorData(...
            'data', wave_annotations.amplitude, 'description','Flattened copy of W.A (volts)'));
        abrWaveTable.vectordata.set('latency', types.hdmf_common.VectorData(...
            'data', wave_annotations.latency, 'description','Copy of W.t (seconds)'));
        abrWaveTable.vectordata.set('sample_index', types.hdmf_common.VectorData(...
            'data', wave_annotations.sampleIndex, 'description','Copy of W.ii (sample index)'));
        abrWaveTable.id = types.hdmf_common.ElementIdentifiers('data', int64(0:nWaveRows-1)');
        
        feather_annotations_module.dynamictable.set('abr_wave_annotations', abrWaveTable);
    else
         warning(['No W_<ExpID>_<SeriesID>.mat files found for any ABR recording - abr_wave_annotations omitted. ' ...
            'intensityThreshold/ABRMaxWaveValues will not be reproducible from this NWB file.']);
    end

    % ---- IC user input ----
    % Check if IC data exists in the file to decide if we should look for input
    hasIC = nwb.processing.isKey('ic_metadata');
    if hasIC
        icUIfile = fullfile(char(expProcDataDir(ee.ExperimenterID, ee.ExpID)), 'ICME', sprintf('ICUserInput_%s.mat', ee.ExpID));
        
        if isfile(icUIfile)
            load(icUIfile, 'UT');
            % filter which ones to export
             if ~isempty(exportedICIDs)
                UT.data=UT.data(ismember(UT.data(:,strcmp(UT.fieldNames,'SeriesID')),exportedICIDs),:);
             end
             icUserInputTable = local_buildUTTable(UT, ...
                ['Copy of ICUserInput_' char(ee.ExpID) ' (see ICuserInput.mlapp): manual per-recording annotations ']);
            feather_annotations_module.dynamictable.set('ic_user_input', icUserInputTable);
        end
    end

    % ---- Histology user input ----
    if nwb.processing.isKey('histology')
        histoUIfile = fullfile(char(expProcDataDir(ee.ExperimenterID, ee.ExpID)), 'HISTO', sprintf('HistoUserInput_%s.mat', ee.ExpID));
        if isfile(histoUIfile)
            load(histoUIfile, 'HistoTable');
             % filter which ones to export
             if ~isempty(exportedHistoIDs)
                HistoTable.data=HistoTable.data(ismember(HistoTable.data(:,strcmp(HistoTable.fieldNames,'HistImgSeriesID')),exportedHistoIDs),:);
             end

            histoUserInputTable = local_buildUTTable(HistoTable, ...
                ['Copy of HistoUserInput_' char(ee.ExpID) ' per-histimg Use flags and ' ...
                 'side/turn/version bookkeeping']);
            feather_annotations_module.dynamictable.set('histo_user_input', histoUserInputTable);
        end
    end

    % ---- ABR OD user input ----
    odUiFile = fullfile(char(expProcDataDir(ee.ExperimenterID, ee.ExpID)), sprintf('ODui_%s.mat', ee.ExpID));
    if isfile(odUiFile)
        load(odUiFile,'UT');
        % find the ones that are supposed to be exported
        if ~isempty(exportedABRIDs)
            UT.data=UT.data(ismember(UT.data(:,strcmp(UT.fieldNames,'SeriesID')),exportedABRIDs),:);
        end
        abrUserInputTable = local_buildUTTable(UT, ...
            ['Copy of ODui_' char(ee.ExpID) ' (see userberabrOD.mlapp): manually recorded optical density filter / ' ...
             'hardware notes per berabr recording']);
        feather_annotations_module.dynamictable.set('abr_user_input', abrUserInputTable);
    end

    nwb.processing.set('feather_annotations', feather_annotations_module);
end

% --- Local Helper for Annotations ---
function T = local_buildUTTable(UTstruct, tableDescription)
% local_buildUTTable - generic converter from a FEATHER "UT"-style
% user-input struct (fields: data [n-by-m cell]; optionally fieldNames
% [1-by-m cell of column-name strings]) into an NWB DynamicTable, one
% row per UT.data row. Falls back to generic column names col1..colm if
% fieldNames is absent (this is the case for at least ODui - its exact
% column-naming convention isn't guaranteed/documented the way UT for
% ICUserInput is).
    nRows = size(UTstruct.data,1);
    nCols = size(UTstruct.data,2);
    if isfield(UTstruct,'fieldNames') && numel(UTstruct.fieldNames)==nCols
        rawNames = UTstruct.fieldNames;
    else
        rawNames = arrayfun(@(x) sprintf('col%d',x), 1:nCols, 'UniformOutput', false);
    end
    colNames = matlab.lang.makeUniqueStrings(matlab.lang.makeValidName(rawNames));

    T = types.hdmf_common.DynamicTable('description', tableDescription, 'colnames', colNames);
    for iCol = 1:nCols
        colData = local_normalizeUTColumn(UTstruct.data(:,iCol));
        T.vectordata.set(colNames{iCol}, types.hdmf_common.VectorData(...
            'data', colData, 'description', sprintf('Original UT column "%s"', rawNames{iCol})));
    end
    T.id = types.hdmf_common.ElementIdentifiers('data', int64(0:nRows-1)');
end

function col = local_normalizeUTColumn(rawCol)
% local_normalizeUTColumn - UT.data columns are known to sometimes mix
% numeric and char/string entries for the "same" column across
% different recordings (see calculateDynamicRangeAnex.m's handling of
% the "d fiber" column, which explicitly checks ischar and calls
% str2num). Rather than guess, we try to interpret the whole column as
% numeric first; if any entry can't be cleanly converted, we fall back
% to storing the entire column as strings (still fully recoverable via
% str2double on import where needed).
    n = numel(rawCol);
    numericVals = nan(n,1);
    allNumeric = true;
    for i = 1:n
        v = rawCol{i};
        if isempty(v)
            numericVals(i) = NaN;
        elseif isnumeric(v) && isscalar(v)
            numericVals(i) = double(v);
        elseif (ischar(v) || isstring(v)) && ~isnan(str2double(v))
            numericVals(i) = str2double(v);
        else
            allNumeric = false;
            break
        end
    end
    if allNumeric
        col = numericVals;
    else
        col = cell(n,1);
        for i = 1:n
            v = rawCol{i};
            if isempty(v)
                col{i} = '';
            else
                col{i} = char(string(v));
            end
        end
    end
end