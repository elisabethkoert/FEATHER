function out = test_dependency_guard(cfg)
name = "dependency guard";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

if ~isfield(cfg, 'deletedCandidates') || isempty(cfg.deletedCandidates)
    out = cs_status(name, "skip", "No deletedCandidates configured for this deletion batch.", struct());
    return
end

try
    req = requiredFilesAndProducts(@() cleanupSafetyPipeline(cfg));
    reqFiles = cs_required_files_to_strings(req);

    deletedAbs = strings(size(cfg.deletedCandidates));
    for ii = 1:numel(cfg.deletedCandidates)
        deletedAbs(ii) = string(fullfile(cfg.toolboxRoot, char(cfg.deletedCandidates(ii))));
    end

    blocking = strings(1,0);
    for ii = 1:numel(deletedAbs)
        if any(reqFiles == deletedAbs(ii))
            blocking(end+1) = deletedAbs(ii); %#ok<AGROW>
        end
    end

    if ~isempty(blocking)
        out = cs_status(name, "fail", "Deleted candidates are still transitively required.", struct('blockingFiles', blocking));
        return
    end

    out = cs_status(name, "pass", "Dependency guard passed for deleted candidates.", struct('checkedCandidates', deletedAbs));
catch ME
    out = cs_status(name, "fail", "Dependency guard failed.", struct('error', string(ME.message)));
end

end
