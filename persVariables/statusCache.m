function S = statusCache
% statusCache - checks if cache is enabled, and it will break out if not to
% avoid data overwrite. When it is called without an output argument, it
% willbrake thee code, ascting as a safety valve. When called with an output
% argument, the output will be 1 if the status in on and 0 if the  status
% is off.

S = strcmp(enablecache, 'on');

if ~nargout>0 &  S ~= 1
    error('Cache is not enabled. Abort!')
    return
end
end