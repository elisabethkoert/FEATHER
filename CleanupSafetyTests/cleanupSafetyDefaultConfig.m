function cfg = cleanupSafetyDefaultConfig()
% Default config for CleanupSafetyTests.
% This function creates one central settings struct used by all cleanup tests.
% Fill in dataset-specific values (such as expID and paths) before running.
% If you are unsure what to edit first, start with expID, regressionDataRoot,
% and rawDataDirParts, then keep other defaults as they are.

thisFile = mfilename('fullpath');
thisDir = fileparts(thisFile);
toolboxRoot = fileparts(thisDir);

cfg.toolboxRoot = string(toolboxRoot);
cfg.expID = "";
cfg.experimenterID = "test";
cfg.userID = "EK";
cfg.species = "";

% Root folder mapped through ukonmap(), e.g. "W" or "C:".
cfg.regressionDataRoot = "";

% Path parts from cfg.regressionDataRoot to raw experiment folder.
cfg.rawDataDirParts = strings(1,0);

% Optional override of processed data location relative to ukonmap.
cfg.processedDataDirPath = "";

% Data types used to initialize anex in the suite.
cfg.requiredRawDataTypes = ["ABR", "IC"];

% Processing toggles.
cfg.runAllBerabrInit = false;
cfg.runAllIcmeInit = true;

% Golden outputs.
cfg.goldenDir = string(fullfile(thisDir, 'golden'));
cfg.goldenFile = "manuscript_smoke_summary.mat";
cfg.goldenFields = ["rawABRCount", "rawICCount", "processedABRCount", "processedICCount"];
cfg.generateGolden = false;

% Dependency guard.
% Paths relative to toolbox root that you already deleted or plan to delete in this batch.
cfg.deletedCandidates = strings(1,0);

% Runtime temp output.
cfg.outputDir = string(fullfile(thisDir, 'output'));

end
