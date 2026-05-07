function out = test_object_session_creation(cfg)
name = "object/session creation";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

try
    ee = cs_get_or_create_anex(cfg, true);
    eeLoaded = loadAnex(anex(cfg.expID, cfg.experimenterID, cs_build_raw_data_dir(cfg)));

    assert(isa(ee, 'anex'), 'Expected anex object after creation.');
    assert(isa(eeLoaded, 'anex'), 'Expected anex object after loading.');
    assert(string(eeLoaded.ExpID) == string(cfg.expID), 'ExpID mismatch after roundtrip.');
    assert(string(eeLoaded.ExperimenterID) == upper(string(cfg.experimenterID)), 'ExperimenterID mismatch after roundtrip.');
    assert(numel(eeLoaded.RawDataDir) == numel(cfg.requiredRawDataTypes), 'RawDataDir length mismatch.');

    data = struct('processedDir', string(expProcDataDir()));
    out = cs_status(name, "pass", "anex create/load checks passed.", data);
catch ME
    out = cs_status(name, "fail", "anex create/load checks failed.", struct('error', string(ME.message)));
end

end
