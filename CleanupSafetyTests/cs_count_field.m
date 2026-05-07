function n = cs_count_field(L, fieldName)
n = 0;
if isempty(L)
    return
end
if isfield(L, fieldName)
    v = L.(fieldName);
    n = numel(v);
end
end
