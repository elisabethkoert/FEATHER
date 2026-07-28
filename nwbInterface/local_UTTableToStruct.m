function UT = local_UTTableToStruct(dynamicTable)
% local_UTTableToStruct  Reverse of local_buildUTTable in exportDataNWBformat.m.
%
% Reconstructs a FEATHER UT struct (fields: data [nRows x nCols cell],
% fieldNames [1 x nCols cell of original column-name strings]) from an NWB
% DynamicTable that was written by local_buildUTTable.
%
% Key design decision: the *original*, pre-sanitization column names are
% recovered from each VectorData column's 'description' field, which
% local_buildUTTable stores as:
%   sprintf('Original UT column "%s"', rawNames{iCol})
%
% This allows exact round-trip of names like 'd fiber [µm]' or 'pos cochlea',
% which downstream FEATHER functions (e.g. calculateDynamicRangeAnex.m) rely
% on via contains(UT.fieldNames,'d fiber') lookups.
%
% If no embedded original name is found in the description, the sanitized
% colname is used as a fallback.
%
% Values are stored as-is (cell array of doubles or chars/strings) since
% calculateDynamicRangeAnex.m and friends already handle mixed types via
% explicit ischar + str2num checks.

colNames = dynamicTable.colnames;   % sanitized names
nCols    = numel(colNames);

% Read number of rows from the id field
nRows    = numel(dynamicTable.id.data.load());

UT.fieldNames = cell(1, nCols);
UT.data       = cell(nRows, nCols);

for iCol = 1:nCols
    vd = dynamicTable.vectordata.get(colNames{iCol});

    % ---- recover original fieldName from description ----
    origName = local_extractOriginalName(vd.description, colNames{iCol});
    UT.fieldNames{iCol} = origName;

    % ---- copy data as-is ----
    colData = vd.data.load();
    if isnumeric(colData)
        % Numeric column: put each scalar into its own cell
        colData = colData(:);
        for iRow = 1:nRows
            UT.data{iRow, iCol} = colData(iRow);
        end
    elseif iscell(colData)
        for iRow = 1:nRows
            UT.data{iRow, iCol} = colData{iRow};
        end
    else
        % char / string array from HDF5 – convert to cell of chars
        colData = cellstr(colData);
        for iRow = 1:nRows
            UT.data{iRow, iCol} = colData{iRow};
        end
    end
end
end

% -----------------------------------------------------------------------
function origName = local_extractOriginalName(descStr, fallback)
% Parses 'Original UT column "<name>"' out of a VectorData description.
tok = regexp(descStr, 'Original UT column "([^"]+)"', 'tokens', 'once');
if ~isempty(tok)
    origName = tok{1};
else
    origName = fallback;
end
end