function out = cs_status(name, status, details, data)
% Creates one standardized result struct for every suite test.
% Using a common format makes summaries and downstream checks easier.
% Expected status values are typically "pass", "fail", or "skip".
if nargin < 4 || isempty(data)
    data = struct();
end
out = struct('name', string(name), 'status', string(status), 'details', string(details), 'data', data);
end
