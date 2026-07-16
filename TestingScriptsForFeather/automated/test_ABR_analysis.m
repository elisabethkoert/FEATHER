classdef test_ABR_analysis < FeatherTestCase

    properties (TestParameter)
        ExpID = TestExperimentRegistry('ABR');
    end

    methods (Test)
        function testPipelineAgainstGolden(testCase, ExpID)
            testCase.assumeTrue(hasRawData(ExpID,'ABR'), sprintf(...
                'No ABR raw data found for %s - check TestExperimentRegistry.m entry.', ExpID));

            result = runABRPipeline(ExpID);

            testCase.assumeTrue(result.hasODui, sprintf(...
                'No ODui/W_ fixture found for %s under UserInputCopies/. Skipping.', ExpID));

            testCase.verifyClass(result.ThrOptical, 'struct');
            testCase.verifyClass(result.ThrAcoustic, 'struct');

            goldenFile = fullfile(goldenResultsDir('ABR'), sprintf('%s_golden.mat', ExpID));
            testCase.assumeTrue(isfile(goldenFile), sprintf(...
                ['No golden result found for %s. After manually verifying this output, run ' ...
                 'regenerateGoldenResults(''ABR'',''%s'') and commit the result.'], ExpID, ExpID));

            golden = load(goldenFile);
            compareAgainstGolden(testCase, result, golden.result, 0.01);
        end
    end
end