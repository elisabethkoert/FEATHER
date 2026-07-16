function D = testRawDataRoot(flag)
% testRawDataRoot - path segments (relative to ukonmap) where FEATHER's
% automated-test raw data lives. Same persistent-variable pattern as
% ukonmap.m / processedDataMap.m so it can be overridden per-machine.
persistent Dstate
if isempty(Dstate)
    Dstate = ["archiv","systems","AllDataTypesForAnalysisTests"];
end
if nargin>0
    Dstate = flag;
end
if nargout>0 || nargin<1
    D = Dstate;
end
end