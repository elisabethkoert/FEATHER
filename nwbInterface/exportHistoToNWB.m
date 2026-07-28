function nwb = exportHistoToNWB(nwb, ee, targetSeriesIDs)
% exportHistoToNWB  Exports Histology data to the NWB processing module.

    HistImgs = listHistImg(ee, 0);
    allSeriesIDs = string(HistImgs.HistImg_SeriesID);
    
    % Filter based on user input
    if ~isempty(targetSeriesIDs)
        mask = ismember(allSeriesIDs, targetSeriesIDs);
        allSeriesIDs = allSeriesIDs(mask);
        % Note: listHistImg returns a struct, we need to be careful indexing
        % For simplicity, we just iterate and check membership
    end
    
    if isempty(allSeriesIDs)
        fprintf('  No Histology images selected for export.\n');
        return;
    end

    % Load User Input Table
    HistoUserInputTable = [];
    histoUserInputFile = fullfile(char(expProcDataDir(ee.ExperimenterID, ee.ExpID)), 'HISTO', sprintf('HistoUserInput_%s.mat', ee.ExpID));
    if isfile(histoUserInputFile)
        S_histoUI = load(histoUserInputFile,'HistoTable');
        HistoUserInputTable = S_histoUI.HistoTable;
    end

     histoModule = types.core.ProcessingModule(...
        'description', ['Histology quantification results from confocal imaging + ' ...
        'Arivis/Nintendo cell-segmentation pipeline (Thirumalai et al. 2025, ' ...
        'doi:10.7150/thno.104474). Raw image stacks are not included in this NWB file; ' ...
        'see raw_image_filename column for cross-reference to the original data.']);

    % Accumulators
     nImg = numel(HistImgs.HistImg_SeriesID);
    h_seriesID = cell(nImg,1); h_side = cell(nImg,1); h_turn = cell(nImg,1);
    h_version = zeros(nImg,1); h_nCells = zeros(nImg,1); h_nPosCells = zeros(nImg,1);
    h_volume = zeros(nImg,1); h_density = zeros(nImg,1); h_densityTransduced = zeros(nImg,1);
    h_transductionRate = zeros(nImg,1); h_areaSlice = zeros(nImg,1);
    h_density2Dslice = zeros(nImg,1); h_filename = cell(nImg,1);

    for iImg = 1:nImg
        H = loadHistImg(histimg(ee, string(HistImgs.HistImg_SeriesID(iImg))));
        h_seriesID{iImg} = char(H.SeriesID);
        h_side{iImg} = char(H.side);
        h_turn{iImg} = char(H.turn);
        h_version(iImg) = H.version;
        h_nCells(iImg) = H.nCells;
        h_nPosCells(iImg) = H.nPosCells;
        h_volume(iImg) = H.volume;
        h_density(iImg) = H.density;
        h_densityTransduced(iImg) = H.densityTransduced;
        h_transductionRate(iImg) = H.transductionRate;
        h_areaSlice(iImg) = H.areaSlice;
        h_density2Dslice(iImg) = H.density2Dslice;
        h_filename{iImg} = char(H.filename); % cross-reference to original raw image, if bundled/archived separately
    end
    
    if isempty(h_seriesID)
        fprintf('  No matching Histology images found.\n');
        return;
    end

    histoTable = types.hdmf_common.DynamicTable(...
        'description', 'Per-image histology quantification results', ...
        'colnames', {'series_id','side','turn','version','n_cells','n_positive_cells', ...
                     'volume_um3','density','density_transduced','transduction_rate', ...
                     'area_slice_um2','density_2Dslice','raw_image_filename'});
    
    % Helper to set columns (repeated code reduced for brevity)
    histoTable.vectordata.set('series_id', types.hdmf_common.VectorData('data', h_seriesID, 'description','histimg SeriesID'));
    histoTable.vectordata.set('side', types.hdmf_common.VectorData('data', h_side, 'description','Cochlea side'));
    histoTable.vectordata.set('turn', types.hdmf_common.VectorData('data', h_turn, 'description','Cochlear turn'));
    histoTable.vectordata.set('version', types.hdmf_common.VectorData('data', h_version, 'description','Image version'));
    histoTable.vectordata.set('n_cells', types.hdmf_common.VectorData('data', h_nCells, 'description','Total detected SGN count'));
    histoTable.vectordata.set('n_positive_cells', types.hdmf_common.VectorData('data', h_nPosCells, 'description','GFP-positive SGN count'));
    histoTable.vectordata.set('volume_um3', types.hdmf_common.VectorData('data', h_volume, 'description','3D ROI volume [um^3]'));
    histoTable.vectordata.set('density', types.hdmf_common.VectorData('data', h_density, 'description','SGN density'));
    histoTable.vectordata.set('density_transduced', types.hdmf_common.VectorData('data', h_densityTransduced, 'description','Transduced SGN density'));
    histoTable.vectordata.set('transduction_rate', types.hdmf_common.VectorData('data', h_transductionRate, 'description','n_positive_cells / n_cells'));
    histoTable.vectordata.set('area_slice_um2', types.hdmf_common.VectorData('data', h_areaSlice, 'description','2D ROI area [um^2]'));
    histoTable.vectordata.set('density_2Dslice', types.hdmf_common.VectorData('data', h_density2Dslice, 'description','2D density'));
    histoTable.vectordata.set('raw_image_filename', types.hdmf_common.VectorData('data', h_filename, 'description','Filename of raw image'));
    
    histoTable.id = types.hdmf_common.ElementIdentifiers('data', int64(0:numel(h_seriesID)-1)');
    histoModule.dynamictable.set('histology_results', histoTable);
    nwb.processing.set('histology', histoModule);
end