function E = processedDataMap(flag)
% processedDataMap - the drive that the processed data is mapped on
% for IAN this is UKON100

persistent Estate
if isempty(Estate)
    Estate = 'W'; %default is on
end

if nargin>0, %set
    flag = upper(flag);
    Estate = flag;
end

if nargout>0 || nargin <1,
    E = Estate;
end
end


