function out = test_raw_data_listing_loading(cfg)
name = "raw-data listing/loading";

if ~cs_has_required_setup(cfg)
    out = cs_status(name, "skip", "Missing config (expID/regressionDataRoot/rawDataDirParts).", struct());
    return
end

try
    ee = cs_get_or_create_anex(cfg, false);
    enablecache off

    info = struct();
    rawTypes = string(cfg.requiredRawDataTypes);

    if any(rawTypes == "ABR")
        Lb = listBerabrRaw(ee);
        info.rawABRCount = cs_count_field(Lb, 'ABR_SeriesID');
    else
        info.rawABRCount = 0;
    end

    if any(rawTypes == "IC")
        [Li, ~] = listIcRaw(ee);
        info.rawICCount = cs_count_field(Li, 'IC_SeriesID');
    else
        info.rawICCount = 0;
    end

    if any(rawTypes == "SU")
        [Ls, ~] = listSuRaw(ee);
        info.rawSUCount = cs_count_field(Ls, 'SU_SeriesID');
    else
        info.rawSUCount = 0;
    end

    out = cs_status(name, "pass", "Raw-data listing checks passed.", info);
catch ME
    out = cs_status(name, "fail", "Raw-data listing checks failed.", struct('error', string(ME.message)));
end

end
