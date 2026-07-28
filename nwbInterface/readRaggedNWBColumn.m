function cellOut = readRaggedNWBColumn(parentObj, dataName)
% readRaggedNWBColumn  Reads one ragged (variable-length) column from an NWB
% Units table or other DynamicTable into a cell array, one element per row.
%
% matNWB stores ragged columns as a pair:
%   <name>           – types.hdmf_common.VectorData  (flat concatenated data)
%   <name>_index     – types.hdmf_common.VectorIndex (cumulative end-indices)
%
% The VectorIndex object lives in the *same* vectordata container as the
% VectorData object (not in a separate "vectorindex" container) and is
% identified by the _index suffix.  This function handles both the ragged
% case and the degenerate case where no index exists (scalar / non-ragged).
%
% Inputs:
%   parentObj  – the NWB Units or DynamicTable object (e.g. nwb.units)
%   dataName   – char name of the data column (e.g. 'spike_times')
%
% Output:
%   cellOut    – nRows-by-1 cell array; each cell contains the data for
%                that row as a column vector.

indexName = [dataName '_index'];

% Locate the flat data vector
if strcmp(dataName, 'spike_times')
    % spike_times is a typed property on Units, not inside vectordata
    flatData = parentObj.spike_times.data.load();
    hasIndex = ~isempty(parentObj.spike_times_index);
    if hasIndex
        cumEnds = int64(parentObj.spike_times_index.data(:));
    end
else
    if ~parentObj.vectordata.isKey(dataName)
        error('FEATHER:NWBImport:missingColumn', ...
            'Column "%s" not found in NWB object.', dataName);
    end
    vd = parentObj.vectordata.get(dataName);
    flatData = vd.data.load();

    hasIndex = parentObj.vectordata.isKey(indexName);
    if hasIndex
        vi = parentObj.vectordata.get(indexName);
        % Confirm it really is a VectorIndex and not another VectorData
        if ~isa(vi, 'types.hdmf_common.VectorIndex')
            hasIndex = false;
        else
            cumEnds = int64(vi.data(:));
        end
    end
end

flatData = flatData(:);   % ensure column

if ~hasIndex
    % Non-ragged: every row is a scalar (or the whole column is one row)
    nRows = numel(flatData);
    cellOut = num2cell(flatData);
    return
end

nRows = numel(cumEnds);
cellOut = cell(nRows, 1);
starts = [int64(1); cumEnds(1:end-1) + int64(1)];

for iRow = 1:nRows
    s = starts(iRow);
    e = cumEnds(iRow);
    if e >= s
        cellOut{iRow} = flatData(s:e);
    else
        cellOut{iRow} = zeros(0,1,'like',flatData);
    end
end
end