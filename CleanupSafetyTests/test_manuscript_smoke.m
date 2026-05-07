function out = test_manuscript_smoke(cfg)
name = "manuscript smoke";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

try
    summary = cleanupSafetyPipeline(cfg);

    if cfg.generateGolden
        generateGoldenOutputs(summary, cfg);
        details = "Smoke run passed and golden outputs were generated.";
    else
        [ok, msg] = compareGoldenOutputs(summary, cfg);
        if ~ok
            out = cs_status(name, "fail", msg, summary);
            return
        end
        details = "Smoke run passed and matched golden outputs.";
    end

    out = cs_status(name, "pass", details, summary);
catch ME
    out = cs_status(name, "fail", "Manuscript smoke test failed.", struct('error', string(ME.message)));
end

end
