function generateGoldenOutputs(summary, cfg)
if ~isfolder(cfg.goldenDir)
    mkdir(cfg.goldenDir);
end
save(fullfile(char(cfg.goldenDir), char(cfg.goldenFile)), 'summary');
end
