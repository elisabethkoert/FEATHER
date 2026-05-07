function out = test_key_processing_steps(cfg)
name = "key processing steps";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

try
    ee = cs_get_or_create_anex(cfg, false);
    info = struct('ranAllBerabrInit', false, 'ranAllIcmeInit', false);

    if isfield(cfg, 'runAllBerabrInit') && cfg.runAllBerabrInit
        enablecache off
        allBerabr(ee);
        info.ranAllBerabrInit = true;
    end

    if isfield(cfg, 'runAllIcmeInit') && cfg.runAllIcmeInit
        enablecache off
        allIcme(ee);
        info.ranAllIcmeInit = true;
    end

    out = cs_status(name, "pass", "Processing-step checks passed.", info);
catch ME
    out = cs_status(name, "fail", "Processing-step checks failed.", struct('error', string(ME.message)));
end

end
