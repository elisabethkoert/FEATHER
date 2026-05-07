function ok = cs_has_required_setup(cfg)
ok = true;
ok = ok && isfield(cfg, 'expID') && strlength(string(cfg.expID)) > 0;
ok = ok && isfield(cfg, 'regressionDataRoot') && strlength(string(cfg.regressionDataRoot)) > 0;
ok = ok && isfield(cfg, 'rawDataDirParts') && ~isempty(cfg.rawDataDirParts);
end
