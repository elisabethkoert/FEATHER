function results = runCleanupSafetySuite(cfg)
% Runs cleanup safety tests before deleting FEATHER code.

if nargin < 1 || isempty(cfg)
    cfg = cleanupSafetyDefaultConfig();
end

addpath(genpath(char(cfg.toolboxRoot)));

tests = {
    @test_object_session_creation
    @test_raw_data_listing_loading
    @test_key_processing_steps
    @test_save_load_roundtrip
    @test_api_contracts
    @test_manuscript_smoke
    @test_dependency_guard
    };

results = repmat(struct('name',"",'status',"",'details',"",'data',struct()), numel(tests), 1);

fprintf('\n=== FEATHER Cleanup Safety Suite ===\n');
for ii = 1:numel(tests)
    f = tests{ii};
    try
        results(ii) = f(cfg);
    catch ME
        results(ii) = cs_status(func2str(f), "fail", "Unhandled exception", struct('error', getReport(ME, 'extended', 'hyperlinks', 'off')));
    end
    fprintf('[%s] %s - %s\n', upper(char(results(ii).status)), char(results(ii).name), char(results(ii).details));
end

nPass = sum([results.status] == "pass");
nFail = sum([results.status] == "fail");
nSkip = sum([results.status] == "skip");
fprintf('Summary: %d pass, %d fail, %d skip\n', nPass, nFail, nSkip);

if nFail > 0
    error('CleanupSafetySuite:Failure', 'One or more cleanup safety tests failed.');
end

end
