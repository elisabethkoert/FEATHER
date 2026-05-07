function D = cs_build_raw_data_dir(cfg)
rawParts = string(cfg.rawDataDirParts);
types = string(cfg.requiredRawDataTypes);

D = repmat(struct('dir', strings(1,0), 'type', ""), 1, numel(types));
for ii = 1:numel(types)
    D(ii).dir = rawParts;
    D(ii).type = types(ii);
end
end
