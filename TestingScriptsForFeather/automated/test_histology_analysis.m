classdef test_histology_analysis < FeatherTestCase

    properties (TestParameter)
        ExpID = TestExperimentRegistry('Histo');
    end

    methods (Test)
        function testImportAndSummary(testCase, ExpID)
            testCase.assumeTrue(hasRawData(ExpID,'Histo'), sprintf(...
                'No histology raw data found for %s - check TestExperimentRegistry.m entry.', ExpID));

            result = runHistoPipeline(ExpID);

            testCase.verifyGreaterThanOrEqual(result.numRawImages, 1, ...
                sprintf('No histology .csv exports found for %s', ExpID));

            testCase.assumeTrue(result.hasHistoUserInput, sprintf(...
                'No HistoUserInput fixture for %s - skipping summary/golden checks.', ExpID));

            goldenFile = fullfile(goldenResultsDir('Histo'), sprintf('%s_golden.mat', ExpID));
            testCase.assumeTrue(isfile(goldenFile), sprintf(...
                ['No golden result found for %s. After manually verifying this output, run ' ...
                 'regenerateGoldenResults(''Histo'',''%s'') and commit the result.'], ExpID, ExpID));

            golden = load(goldenFile);
            compareAgainstGolden(testCase, result, golden.result, 0.01);
        end
    end
end