function [ok, msg] = compareGoldenOutputs(summary, cfg)
% Compares selected smoke-summary fields against the stored golden baseline.
% Returns ok=false with a concise message at the first mismatch.
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
        expectedVal = cs_value_to_text(golden.(char(f)));
        actualVal = cs_value_to_text(summary.(char(f)));
        msg = "Golden mismatch at field: " + f + " (expected: " + expectedVal + ", got: " + actualVal + ")";
        return
    end
end

end

function txt = cs_value_to_text(v)
% Converts values to readable text for mismatch messages.
if isstring(v) || ischar(v)
    txt = string(v);
elseif isnumeric(v) || islogical(v)
    txt = string(mat2str(v));
else
    txt = string(class(v));
end
end
