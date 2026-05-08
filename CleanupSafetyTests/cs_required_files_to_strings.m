function reqFiles = cs_required_files_to_strings(req)
% Normalizes required-files output into a unique string array of file paths.
% requiredFilesAndProducts may return different shapes, so this helper
% keeps dependency-guard comparisons simple and consistent.
if isempty(req)
    reqFiles = strings(1,0);
    return
end

if isstruct(req)
    if isfield(req, 'FileName')
        reqFiles = string({req.FileName});
    elseif isfield(req, 'Name')
        reqFiles = string({req.Name});
    else
        reqFiles = strings(1,0);
    end
else
    reqFiles = string(req);
end

reqFiles = unique(reqFiles);
end
