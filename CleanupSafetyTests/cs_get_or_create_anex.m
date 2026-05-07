function ee = cs_get_or_create_anex(cfg, forceNew)
if nargin < 2
    forceNew = false;
end

cs_prepare_environment(cfg);
D = cs_build_raw_data_dir(cfg);

if forceNew
    ee = anex(cfg.expID, cfg.experimenterID, D);
    if isfield(cfg, 'species') && strlength(string(cfg.species)) > 0
        ee = setAnimalSpecies(ee, cfg.species);
    end
    initProcessedExp(ee);
    saveAnex(ee);
    return
end

try
    ee = anex(cfg.expID, cfg.experimenterID, D);
    ee = loadAnex(ee);
catch ME
    %#ok<NASGU> % fallback to create a new anex when load fails
    ee = anex(cfg.expID, cfg.experimenterID, D);
    if isfield(cfg, 'species') && strlength(string(cfg.species)) > 0
        ee = setAnimalSpecies(ee, cfg.species);
    end
    initProcessedExp(ee);
    saveAnex(ee);
end

end
