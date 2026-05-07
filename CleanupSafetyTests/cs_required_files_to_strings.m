function reqFiles = cs_required_files_to_strings(req)
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
