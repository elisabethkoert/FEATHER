function E = enablecache(flag)
% enablecache - enable/disable caching
%   enablecache('on') enables getcache
%   enablecache('off') disables getcache (it will always return [])
%   S=enablecache returns current cache state S
%
%   The cache state is remembered (using a global variable) during the
%   current matlab session, but not across sessions.
%
%   see also: get cache, putcache

persistent Estate
if isempty(Estate)
    Estate = 'on'; %default is on
end

if nargin>0, %set
    flag = lower(flag);
    if ~ismember(flag, {'off','on'}), error('Invalid flag.'); end
    Estate = flag;
end
if nargout>0 || nargin <1,
    E = Estate;
end
end


