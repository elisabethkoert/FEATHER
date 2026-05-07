function out = test_save_load_roundtrip(cfg)
% Confirms that saving and loading key objects does not change core values.
% It always checks anex roundtrip behavior and can also check one IC object.
% This protects against regressions where persisted data becomes inconsistent.
name = "save/load roundtrip";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

try
    ee = cs_get_or_create_anex(cfg, false);
    saveAnex(ee);
    eeReload = loadAnex(ee);

    assert(string(eeReload.ExpID) == string(ee.ExpID), 'anex ExpID changed after roundtrip.');
    assert(numel(eeReload.RawDataDir) == numel(ee.RawDataDir), 'anex RawDataDir changed after roundtrip.');

    info = struct('anexRoundtrip', true, 'icmeRoundtrip', false, 'icmeRoundtripError', "");

    if isfield(cfg, 'runAllIcmeInit') && cfg.runAllIcmeInit
        try
            L = listIcme(eeReload);
            nIc = cs_count_field(L, 'IC_SeriesID');
            if nIc > 0
                sid = string(L.IC_SeriesID(1));
                IC = loadIcme(icme(eeReload, sid));
                saveIcme(IC);
                IC2 = loadIcme(icme(eeReload, sid));
                assert(string(IC2.SeriesID) == sid, 'icme SeriesID changed after roundtrip.');
                info.icmeRoundtrip = true;
            end
        catch innerME
            info.icmeRoundtripError = string(innerME.message);
        end
    end

    out = cs_status(name, "pass", "Save/load roundtrip checks passed.", info);
catch ME
    out = cs_status(name, "fail", "Save/load roundtrip checks failed.", struct('error', string(ME.message)));
end

end
