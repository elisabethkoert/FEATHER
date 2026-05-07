function cs_prepare_environment(cfg)
addpath(genpath(char(cfg.toolboxRoot)));
ukonmap(char(cfg.regressionDataRoot));

if isfield(cfg, 'processedDataDirPath') && strlength(string(cfg.processedDataDirPath)) > 0
    processedDataDirPath('set', char(cfg.processedDataDirPath));
end

if isfield(cfg, 'userID') && strlength(string(cfg.userID)) > 0
    userID(char(cfg.userID));
end

if isfield(cfg, 'experimenterID') && strlength(string(cfg.experimenterID)) > 0
    experimenterID(char(cfg.experimenterID));
end

enablecache off
end
