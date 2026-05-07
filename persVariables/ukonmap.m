function E = ukonmap(flag)
% ukonmap - the letter that maps the drive connected to raw data
% for IAN this should be UKON100-spezial

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


