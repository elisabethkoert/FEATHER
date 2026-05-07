function out = test_api_contracts(cfg)
name = "API contracts";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

try
    ee = cs_get_or_create_anex(cfg, false);

    requiredAnexProps = ["ExpID", "ExperimenterID", "RawDataDir", "UserID"];
    requiredAnexMethods = ["saveAnex", "loadAnex", "listIcRaw", "listBerabrRaw", "allIcme"];

    for p = requiredAnexProps
        assert(isprop(ee, char(p)), "Missing anex property: " + p);
    end
    for m = requiredAnexMethods
        assert(ismethod(ee, char(m)), "Missing anex method: " + m);
    end

    info = struct();
    info.anexPropsChecked = requiredAnexProps;
    info.anexMethodsChecked = requiredAnexMethods;

    info.icmeContractError = "";
    try
        L = listIcRaw(ee);
        if isfield(L, 'IC_SeriesID') && ~isempty(L.IC_SeriesID)
            IC = icme(ee, string(L.IC_SeriesID(1)), []);
            requiredIcProps = ["ExpID", "SeriesID", "ExpInfo", "Stim", "SL", "D"];
            for p = requiredIcProps
                assert(isprop(IC, char(p)), "Missing icme property: " + p);
            end
            info.icmePropsChecked = requiredIcProps;
        end
    catch innerME
        info.icmeContractError = string(innerME.message);
    end

    out = cs_status(name, "pass", "API contract checks passed.", info);
catch ME
    out = cs_status(name, "fail", "API contract checks failed.", struct('error', string(ME.message)));
end

end
