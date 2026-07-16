classdef test_IC_analysis < FeatherTestCase
  properties (TestParameter)
        ExpID = TestExperimentRegistry('IC');
    end

    methods (Test)
        function testSpikeExtractionAndProtocolSpecificAnalyses(testCase, ExpID)
            testCase.assumeTrue(hasRawData(ExpID,'IC'), sprintf(...
                'No IC raw data found for %s - check TestExperimentRegistry.m entry.', ExpID));

            result = runICPipeline(ExpID);

            testCase.verifyGreaterThanOrEqual(numel(result.SeriesIDs), 1, ...
                sprintf('No icme recordings found for %s', ExpID));

            if ~result.hasICUserInput
                testCase.assumeTrue(false, sprintf(...
                    'No ICUserInput fixture for %s - skipping calibration/analysis/golden checks.', ExpID));
            end

            % general spike-extraction sanity check (any usable recording)
            testCase.verifyClass(result.meanSpikeRatesFirst, 'double');
            testCase.verifyNotEmpty(result.meanSpikeRatesFirst, sprintf(...
                'calculateSpikeRate produced an empty result for %s (recording used: %s)', ...
                ExpID, result.meanSpikeRatesFirstSeriesID));

            % protocol-specific checks - each only runs if ICRoleRegistry.m
            % defines that role for this animal
            if isfield(result,'tonotopy')
                testCase.verifyClass(result.tonotopy.slope, 'double');
                testCase.verifyNotEmpty(result.tonotopy.slope, sprintf(...
                    'calculateTonotopicSlope returned no slope for %s (%s)', ExpID, result.tonotopy.SeriesID));
            end
            if isfield(result,'repRate')
                testCase.verifyClass(result.repRate.VS_array, 'double');
                testCase.verifyNotEmpty(result.repRate.VS_array, sprintf(...
                    'calculateVS returned no result for %s (%s)', ExpID, result.repRate.SeriesID));
            end
            if isfield(result,'pulseIntensity')
                testCase.verifyClass(result.pulseIntensity.SoE_mm, 'double');
                testCase.verifyNotEmpty(result.pulseIntensity.SoE_mm, sprintf(...
                    'calculateSOE returned no result for %s (%s)', ExpID, result.pulseIntensity.SeriesID));
            end

            if isfield(result,'pulseDuration')
                testCase.verifyGreaterThanOrEqual(result.pulseDuration.numResponsiveElecs, 0, sprintf(...
                    'calculateDprime/getResponsiveUnits failed for pulse-duration protocol on %s (%s)', ...
                    ExpID, result.pulseDuration.SeriesID));
            end
            
            if isfield(result,'pulseIntensity') && isfield(result.pulseIntensity,'psth')
                testCase.verifyClass(result.pulseIntensity.psth.PSTH_norm, 'double');
                testCase.verifyNotEmpty(result.pulseIntensity.psth.PSTH_norm, sprintf(...
                    'calculatePSTH returned no result for %s (%s)', ExpID, result.pulseIntensity.SeriesID));
            end

            testCase.verifyTrue(isfield(result,'icAnexWideThresholds'), sprintf(...
               'intensityThresholdIC was not run for %s', ExpID));

            goldenFile = fullfile(goldenResultsDir('IC'), sprintf('%s_golden.mat', ExpID));
            testCase.assumeTrue(isfile(goldenFile), sprintf(...
                ['No golden result found for %s. After manually verifying this output, run ' ...
                 'regenerateGoldenResults(''IC'',''%s'') and commit the result.'], ExpID, ExpID));

            golden = load(goldenFile);
            compareAgainstGolden(testCase, result, golden.result, 0.01);
        end
    end
end