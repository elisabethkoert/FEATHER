classdef FeatherTestCase < matlab.unittest.TestCase
    % FeatherTestCase - shared setup for all automated FEATHER tests.
    % Forces userID to 'TEST' so automated tests always write to
    % .../TESTdata/<ExperimenterID>/f_<ExpID>, never into a real
    % analyst's folder. ExperimenterID is left as the real EK/JG/TH/NA
    % initials so tests exercise the real per-experimenter conventions.

    properties (Access = private)
        OrigUserID
        OrigEnableCache
    end

    methods (TestClassSetup)
        function isolateUser(testCase)
            testCase.OrigUserID = userID();
            testCase.OrigEnableCache = enablecache();
            userID('TEST');
        end
    end

    methods (TestClassTeardown)
        function restoreUser(testCase)
            userID(testCase.OrigUserID);
            enablecache(testCase.OrigEnableCache);
        end
    end
end