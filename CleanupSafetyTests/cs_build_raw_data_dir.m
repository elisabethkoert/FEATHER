function D = cs_build_raw_data_dir(cfg)
rawParts = string(cfg.rawDataDirParts);
types = string(cfg.requiredRawDataTypes);

D = repmat(struct('dir', rawParts, 'type', ""), 1, numel(types));
for ii = 1:numel(types)
    D(ii).type = types(ii);
end
end
