function H = initHistImgFromNWB(H, histoTable, rowIdx)
% histimg/initHistImgFromNWB  Populate a histimg object from one row of
% the histology_results DynamicTable in an NWB file produced by
% exportDataNWBformat.m.
%
% Inputs:
%   H          – histimg object pre-constructed with correct ExpID/SeriesID
%   histoTable – nwb.processing('histology').dynamictable('histology_results')
%   rowIdx     – 1-based row index into histoTable
%
% Output:
%   H  – fully populated histimg
%
% Confirmed unrecoverable fields (left unset / empty):
%   H.gfpThreshhold   – not exported
%   H.numPlanesVolume  – not exported
%   H.D                – raw dir left empty

% ---- direct 1:1 column mappings ----------------------------------------
H.side       = local_strVal(histoTable, 'side',       rowIdx);
H.turn       = local_strVal(histoTable, 'turn',       rowIdx);
H.version    = local_numVal(histoTable, 'version',    rowIdx);
H.nCells     = local_numVal(histoTable, 'n_cells',    rowIdx);
H.nPosCells  = local_numVal(histoTable, 'n_positive_cells', rowIdx);
H.volume     = local_numVal(histoTable, 'volume_um3', rowIdx);
H.density    = local_numVal(histoTable, 'density',    rowIdx);
H.densityTransduced  = local_numVal(histoTable, 'density_transduced',  rowIdx);
H.transductionRate   = local_numVal(histoTable, 'transduction_rate',   rowIdx);
H.areaSlice  = local_numVal(histoTable, 'area_slice_um2', rowIdx);
H.density2Dslice     = local_numVal(histoTable, 'density_2Dslice',     rowIdx);
H.filename   = local_strVal(histoTable, 'raw_image_filename', rowIdx);

% ---- fields not exported – leave unset (not placeholder values) ---------
% H.gfpThreshhold  – intentionally absent
% H.numPlanesVolume – intentionally absent

% ---- raw data dir left empty (no raw access from NWB) -------------------
H.D = struct();
H.D.('type')="fromNWB";
end

% =========================================================================
function v = local_numVal(tbl, colname, rowIdx)
v = double(tbl.vectordata.get(colname).data(rowIdx));
end

function s = local_strVal(tbl, colname, rowIdx)
raw = tbl.vectordata.get(colname).data.load();
if iscell(raw)
    s = char(raw{rowIdx});
elseif ischar(raw)
    s = raw(rowIdx, :);
    s = strtrim(s);
elseif isstring(raw)
    s = char(raw(rowIdx));
else
    s = '';
end
end