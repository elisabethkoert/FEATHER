function [ok, msg] = compareGoldenOutputs(summary, cfg)
ok = true;
msg = "Golden comparison passed.";

goldenPath = fullfile(char(cfg.goldenDir), char(cfg.goldenFile));
if ~isfile(goldenPath)
    ok = false;
    msg = "Golden file missing. Run with cfg.generateGolden=true once on baseline before deletions.";
    return
end

S = load(goldenPath, 'summary');
golden = S.summary;

fields = string(cfg.goldenFields);
for ii = 1:numel(fields)
    f = fields(ii);
    if ~isfield(golden, char(f)) || ~isfield(summary, char(f))
        ok = false;
        msg = "Missing golden field: " + f;
        return
    end
    if ~isequal(golden.(char(f)), summary.(char(f)))
        ok = false;
        msg = "Golden mismatch at field: " + f + " (expected: " + string(golden.(char(f))) + ", got: " + string(summary.(char(f))) + ")";
        return
    end
end

end
