function nwb = exportFeatherToNWB(ee, varargin)
% exportFeatherToNWB  Exports FEATHER data to NWB format.
%
%   nwb = exportFeatherToNWB(ee) exports all available ABR, IC, and Histology
%   data for the given animal experiment (anex object).
%
%   nwb = exportFeatherToNWB(ee, 'exportABR', false) skips ABR export.
%
%   nwb = exportFeatherToNWB(ee, 'abrSeriesIDs', {'ID1', 'ID2'}) exports only
%   the specified ABR recordings.
%
%   Name-Value Arguments:
%       'exportABR'   (logical, default true)  - Export ABR data
%       'exportIC'    (logical, default true)  - Export IC data
%       'exportHisto' (logical, default true)  - Export Histology data
%       'abrSeriesIDs' (cell/string, default []) - Specific ABR SeriesIDs to export
%       'icSeriesIDs'  (cell/string, default []) - Specific IC SeriesIDs to export
%       'histoSeriesIDs' (cell/string, default []) - Specific Histo SeriesIDs to export
%       'outputDir'   (char, default current) - Directory to save .nwb file
%       'filename'    (char, default <ExpID>.nwb) - Filename

    %% Parse Inputs
    p = inputParser;
    addRequired(p, 'ee', @(x) isa(x, 'anex'));
    addParameter(p, 'exportABR', true, @islogical);
    addParameter(p, 'exportIC', true, @islogical);
    addParameter(p, 'exportHisto', true, @islogical);
    addParameter(p, 'abrSeriesIDs', {}, @(x) ischar(x) || isstring(x) || iscellstr(x));
    addParameter(p, 'icSeriesIDs', {}, @(x) ischar(x) || isstring(x) || iscellstr(x));
    addParameter(p, 'histoSeriesIDs', {}, @(x) ischar(x) || iscellstr(x));
    addParameter(p, 'outputDir', pwd, @ischar);
    addParameter(p, 'filename', '', @ischar);
    parse(p, ee, varargin{:});
    
    opt = p.Results;
    ee = opt.ee;
    
    % Normalize SeriesIDs to string arrays for easier comparison
    if ischar(opt.abrSeriesIDs) || isstring(opt.abrSeriesIDs)
        opt.abrSeriesIDs = string(opt.abrSeriesIDs);
    elseif iscell(opt.abrSeriesIDs)
        opt.abrSeriesIDs = string(opt.abrSeriesIDs);
    end
    
    if ischar(opt.icSeriesIDs) || isstring(opt.icSeriesIDs)
        opt.icSeriesIDs = string(opt.icSeriesIDs);
    elseif iscell(opt.icSeriesIDs)
        opt.icSeriesIDs = string(opt.icSeriesIDs);
    end
    
    if ischar(opt.histoSeriesIDs) || isstring(opt.histoSeriesIDs)
        opt.histoSeriesIDs = string(opt.histoSeriesIDs);
    elseif iscell(opt.histoSeriesIDs)
        opt.histoSeriesIDs = string(opt.histoSeriesIDs);
    end

    % Determine default filename
    if isempty(opt.filename)
        opt.filename = sprintf('%s.nwb', ee.ExpID);
    end

    fprintf('--- Starting NWB Export for %s ---\n', ee.ExpID);

    %% 1. Initialize NWB File & Subject Metadata
    [nwb, sessionStart] = initNWBFile(ee);

    %% 2. Setup Electrodes (Required for ABR and IC)
    % We need to know if IC exists to size the electrode table correctly
    hasIC = opt.exportIC && ~isempty(listIcme(ee).IC_SeriesID);
    
    [nwb, abrElecRegion, icElecTableOffset] = setupElectrodes(nwb, ee, hasIC);

    %% 3. Export ABR Data
    wave_annotations = struct();
    if opt.exportABR
        fprintf('Exporting ABR data...\n');
        [nwb, wave_annotations] = exportABRtoNWB(nwb, ee, sessionStart, abrElecRegion, opt.abrSeriesIDs);
    end

    %% 4. Export IC Data
    if opt.exportIC
        fprintf('Exporting IC data...\n');
        nwb = exportICtoNWB(nwb, ee, sessionStart, icElecTableOffset, opt.icSeriesIDs);
    end

    %% 5. Export Histology Data
    if opt.exportHisto
        fprintf('Exporting Histology data...\n');
        nwb = exportHistoToNWB(nwb, ee, opt.histoSeriesIDs);
    end

    %% 6. Export Annotations (User Input & Wave Peaks)
    fprintf('Exporting Annotations...\n');
    nwb = exportAnnotationsToNWB(nwb, ee, wave_annotations,opt.abrSeriesIDs,opt.icSeriesIDs,opt.histoSeriesIDs);

    %% 7. Save to Disk
    %  This is where all ObjectView/DynamicTableRegion references get resolved
    %  and written into the actual HDF5 file structure. Any dangling/orphaned
    %  references (e.g., a table that was built but never attached to nwb)
    %  will cause export to fail with a "could not be created" error.
    %  IMPORTANT: matNWB does NOT cleanly overwrite existing datasets in place
    %  if their size has changed since the file was last written (HDF5
    %  datasets are non-resizable by default) - it silently SKIPS the write
    %  with only a warning, leaving stale data from the previous run mixed in
    %  with newly-written data. Always delete any existing output file before
    %  re-exporting, rather than trusting nwbExport to overwrite it correctly.


    outPath = fullfile(opt.outputDir, opt.filename);
    if isfile(outPath)
        delete(outPath);
    end
    
    nwbExport(nwb, outPath);
    fprintf('--- Export Complete: %s ---\n', outPath);
end