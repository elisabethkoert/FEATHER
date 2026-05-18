function [P1N1MaxAmplitude,P1Latency,indexBeraTrace] = findMaxWave(B)
% berabr\findMaxWave finds the max Intensity with a user annotation and
% returns the P1N1 amplitude and P1 latency
% input: 
%   B (berabr): berabr object from which to get the strongest wave response
% output:
%   P1N1MaxAmplitude (float): largest P1N1 amplitude of this recording
%   P1Latency (float): latency of the highest amplitude P1
%   indexBeraTrace (int) the bera trace that corresponds to max Peak

%import the waves
W = importWaves (B);
if isempty(W)
    P1N1MaxAmplitude =nan;
    P1Latency=nan;
    indexBeraTrace =nan;
    return
end
% calculate the P1N1 amplitude for all waves:
all_P1N1Ampl=[];
all_P1Latencies=[];
for jj=1:length(W)
    curP1N1Ampl=W(jj).A(1,1)-W(jj).A(2,1);
    all_P1N1Ampl=curP1N1Ampl;
    all_P1Latencies=W(jj).t(1);
end
[P1N1MaxAmplitude,indexBeraTrace]=max(all_P1N1Ampl);
P1Latency=all_P1Latencies(indexBeraTrace);

if isnan(P1N1MaxAmplitude)
    P1N1MaxAmplitude =nan;
    P1Latency=nan;
    indexBeraTrace =nan;
end

end
