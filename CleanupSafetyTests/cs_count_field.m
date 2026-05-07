function n = cs_count_field(L, fieldName)
% Safely counts entries in a field of a struct-like listing result.
% If the listing is empty or the field is missing, this returns 0.
% This keeps tests concise and avoids repetitive defensive checks.
n = 0;
if isempty(L)
    return
end
if isfield(L, fieldName)
    v = L.(fieldName);
    n = numel(v);
end
end
