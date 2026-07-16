function results = runAllAutomatedTests()
% runAllAutomatedTests - runs the full FEATHER automated test suite
% (ABR, IC, Histology,SU) using the manually curated experiment list in
% utils/TestExperimentRegistry.m.
here = fileparts(mfilename('fullpath'));
addpath(fullfile(here,'utils'));

suite = matlab.unittest.TestSuite.fromFolder(here);
results = run(suite);
table(results)

% keep a copy on disk too, so results survive even if you forget to
% capture the output, and so you can diff runs over time
runLogDir = fullfile(here,'runLogs');
if ~isfolder(runLogDir); mkdir(runLogDir); end
timestamp = char(datetime('now','Format','yyyyMMdd_HHmmss'));
save(fullfile(runLogDir, sprintf('testRunResults_%s.mat', timestamp)), 'results');
fprintf('Saved full results to %s\n', fullfile(runLogDir, sprintf('testRunResults_%s.mat', timestamp)));

end