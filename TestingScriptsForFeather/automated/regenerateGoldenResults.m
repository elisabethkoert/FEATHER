function regenerateGoldenResults(testType, ExpIDFilter)
% regenerateGoldenResults - DEVELOPER-RUN ONLY, never called by the test
% suite itself. Recomputes and overwrites the committed golden baseline.
% Only run after manually confirming the new output is correct.
%
% Forces userID to 'TEST' for the duration of this call, mirroring
% FeatherTestCase's isolation - this function calls the pipeline
% functions directly rather than through matlab.unittest, so the test
% framework's TestClassSetup/TestClassTeardown hooks never fire here and
% cannot provide this isolation on their own.
%
%   regenerateGoldenResults('ABR')
%   regenerateGoldenResults('ABR','GEK030')

if nargin<2, ExpIDFilter = []; end

origUserID = userID();
origEnableCache = enablecache();
userID('TEST');
cleanupObj = onCleanup(@() restoreState(origUserID, origEnableCache)); %#ok<NASGU>

paramStruct = TestExperimentRegistry(testType);
animals = struct2cell(paramStruct);
if ~isempty(ExpIDFilter)
    animals = animals(strcmp(animals, ExpIDFilter));
end

outDir = goldenResultsDir(testType);
if ~isfolder(outDir); mkdir(outDir); end

for i = 1:numel(animals)
    ExpID = animals{i};
    switch testType
        case 'ABR',   result = runABRPipeline(ExpID);
        case 'IC',    result = runICPipeline(ExpID);
        case 'Histo', result = runHistoPipeline(ExpID);
        otherwise, error('unknown testType %s', testType);
    end
    save(fullfile(outDir, sprintf('%s_golden.mat', ExpID)), 'result');
    fprintf('Golden result written for %s (%s). REVIEW before committing.\n', ExpID, testType);
end

end

function restoreState(origUserID, origEnableCache)
userID(origUserID);
enablecache(origEnableCache);
end