function out = cs_status(name, status, details, data)
if nargin < 4 || isempty(data)
    data = struct();
end
out = struct('name', string(name), 'status', string(status), 'details', string(details), 'data', data);
end
