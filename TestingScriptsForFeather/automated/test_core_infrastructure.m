classdef test_core_infrastructure < FeatherTestCase
    % test_core_infrastructure - unit tests for small, deterministic
    % dirManagement/persVariables functions and for ROCAna_03. None of
    % these require raw data or any registry entry, so this test class
    % has no TestParameter and runs standalone.

    methods (Test)

        function testTestSafeDirBlocksArchivPaths(testCase)
            try
                testSafeDir('Z:\archiv\systems\foo');
                testCase.verifyFail('testSafeDir did not throw an error for a path containing "archiv"');
            catch ME
                testCase.verifySubstring(ME.message, 'ARCHIV', ...
                    'testSafeDir threw an error, but not the expected ARCHIV safety message.');
            end
        end

        function testTestSafeDirAllowsNonArchivPaths(testCase)
            % should NOT throw
            testSafeDir('Z:\public\Data\invivoelectrophysiologyFEATHER\foo');
            testCase.verifyTrue(true);  % reaching here means no error was thrown
        end

        function testGetExperimenterFromExpIDKnownPrefixes(testCase)
            testCase.verifyEqual(getExperimenterFromExpID('gjg131644'), 'JG');
            testCase.verifyEqual(getExperimenterFromExpID('GEK030'),    'EK');
            testCase.verifyEqual(getExperimenterFromExpID('gth212308'), 'TH');
            testCase.verifyEqual(getExperimenterFromExpID('gfe999999'), 'FE');
            testCase.verifyEqual(getExperimenterFromExpID('mav181065'), 'AV');
        end

        function testEnableCacheRoundTrip(testCase)
            orig = enablecache();
            enablecache('off');
            testCase.verifyEqual(enablecache(), 'off');
            enablecache('on');
            testCase.verifyEqual(enablecache(), 'on');
            enablecache(orig);  % restore
        end

        function testROCAna03_IdenticalDistributionsGiveNullResult(testCase)
            % Per the function's own docstring: "if N == P than AUC
            % equals 0.5 and Dprime is 0" - this is an explicit,
            % documented invariant, safe to hardcode as an exact
            % expected value (unlike arbitrary numeric outputs, which we
            % deliberately avoid guessing - see golden-file approach
            % used elsewhere in this suite).
            x = [0.3, 0.4, 0.5, 0.5, 0.6, 0.7, 0.8];
            [~, AUC, Dprime, ~] = ROCAna_03([], x, x, 0);
            testCase.verifyEqual(AUC, 0.5, 'AbsTol', 1e-9);
            testCase.verifyEqual(Dprime, 0, 'AbsTol', 1e-9);
        end

        function testROCAna03_SeparatedDistributionsGivePositiveDprime(testCase)
            % Values taken directly from the function's own docstring
            % example. We deliberately do NOT hardcode the exact AUC/
            % Dprime the docstring quotes (0.815 / 1.2678), since those
            % numbers are documented against ROCAna_01, not ROCAna_03,
            % and the two versions differ in their extreme-value bias
            % correction (see ROCAna_03.m's own header comment on this).
            % Instead we test the invariant that must hold regardless of
            % which version's correction is used: P stochastically
            % greater than N must give AUC > 0.5 and Dprime > 0.
            N = [0.3, 0.4, 0.5, 0.5, 0.5, 0.6, 0.7, 0.7, 0.8, 0.9];
            P = [0.5, 0.6, 0.6, 0.8, 0.9, 0.9, 0.9, 1.0, 1.2, 1.4];
            [~, AUC, Dprime, ~] = ROCAna_03([], N, P, 0);
            testCase.verifyGreaterThan(AUC, 0.5);
            testCase.verifyGreaterThan(Dprime, 0);
        end

    end
end