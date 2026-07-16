function compareAgainstGolden(testCase, actual, golden, relTol)
import matlab.unittest.constraints.IsEqualTo
import matlab.unittest.constraints.RelativeTolerance
if nargin<4, relTol = 0.01; end
testCase.verifyThat(actual, IsEqualTo(golden, ...
    'Within', RelativeTolerance(relTol)), ...
    'Result differs from golden baseline by more than the allowed tolerance.');
end