function summary = cleanupSafetyPipeline(cfg)
% Core non-interactive pipeline used by smoke and dependency checks.

cs_prepare_environment(cfg);
ee = cs_get_or_create_anex(cfg, false);

summary = struct();
summary.expID = string(cfg.expID);
summary.experimenterID = string(cfg.experimenterID);
summary.timestamp = string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
summary.rawABRCount = 0;
summary.rawICCount = 0;
summary.processedABRCount = 0;
summary.processedICCount = 0;
summary.processedABRError = "";
summary.processedICError = "";

enablecache off

rawTypes = string(cfg.requiredRawDataTypes);
if any(rawTypes == "ABR")
    Lb = listBerabrRaw(ee);
    summary.rawABRCount = cs_count_field(Lb, 'ABR_SeriesID');
end
if any(rawTypes == "IC")
    Li = listIcRaw(ee);
    summary.rawICCount = cs_count_field(Li, 'IC_SeriesID');
end

if isfield(cfg, 'runAllBerabrInit') && cfg.runAllBerabrInit
    allBerabr(ee);
end
if isfield(cfg, 'runAllIcmeInit') && cfg.runAllIcmeInit
    allIcme(ee);
end

enablecache off
try
    Lbp = listBerabr(ee);
    summary.processedABRCount = cs_count_field(Lbp, 'ABR_SeriesID');
catch ME
    summary.processedABRError = string(ME.message);
end
try
    Lip = listIcme(ee);
    summary.processedICCount = cs_count_field(Lip, 'IC_SeriesID');
catch ME
    summary.processedICError = string(ME.message);
end

if ~isfolder(cfg.outputDir)
    mkdir(cfg.outputDir);
end
save(fullfile(char(cfg.outputDir), 'latest_smoke_summary.mat'), 'summary');

end
