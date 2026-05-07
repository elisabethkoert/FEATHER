function D = cs_build_raw_data_dir(cfg)
rawParts = string(cfg.rawDataDirParts);
types = string(cfg.requiredRawDataTypes);

if isempty(rawParts)
    error('cs_build_raw_data_dir:MissingRawDataDirParts', 'cfg.rawDataDirParts must contain path parts to one experiment raw-data folder.');
end

D = repmat(struct('dir', rawParts, 'type', ""), 1, numel(types));
for ii = 1:numel(types)
    D(ii).type = types(ii);
end
end
