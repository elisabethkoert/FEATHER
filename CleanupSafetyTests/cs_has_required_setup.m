function ok = cs_has_required_setup(cfg)
% Returns true only when the minimal required config fields are present.
% Tests use this helper to decide whether to run or return a clean "skip".
% This avoids noisy failures when config is intentionally not filled yet.
ok = true;
ok = ok && isfield(cfg, 'expID') && strlength(string(cfg.expID)) > 0;
ok = ok && isfield(cfg, 'regressionDataRoot') && strlength(string(cfg.regressionDataRoot)) > 0;
ok = ok && isfield(cfg, 'rawDataDirParts') && ~isempty(cfg.rawDataDirParts);
end
