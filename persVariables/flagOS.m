function E = flagOS(flag)
% flagOS - the the Operating system flag. 
%   WINDOWS - default
%   LINUX
%   MACOS

persistent Estate
if isempty(Estate)
    Estate = "WINDOWS"; %default is windows 
end

if nargin>0, %set
    flag = upper(flag);
    Estate = flag;
end

if nargout>0 || nargin <1,
    E = Estate;
end
end
