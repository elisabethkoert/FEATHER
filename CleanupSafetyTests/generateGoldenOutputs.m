function generateGoldenOutputs(summary, cfg)
% Writes the smoke summary as the golden baseline for future comparisons.
% Run this only on a trusted baseline before deletion batches.
if ~isfolder(cfg.goldenDir)
    mkdir(cfg.goldenDir);
end
save(fullfile(char(cfg.goldenDir), char(cfg.goldenFile)), 'summary');
end
