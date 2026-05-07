function [IntMin,indexBeraTrace] = intensityThreshold(B)
% berabr\intensity_threshold finds the lowest intensity for which there is
% a user W1 annotation.
%  [IntMin,indexBeraTrace] = intensity_threshold(B)
% IntMin: the minimum intensity. In case it is optical, this will be the
% radiant flux taking into consideration the calibraiton
% indexBeraTrace: the bera trace that corresponds to minimum intensity

%import the waves
W = importWaves (B);
if isempty(W)
    IntMin =nan;
    indexBeraTrace =nan;
    return
end
%find the beraTraces for which there is a wave annotation
wTrace = [];
for ii= 1 : B.nTraces
    tmp_zeros = isnan(W(ii).t);
    if sum(reshape(tmp_zeros, numel(tmp_zeros),1))~=10;
        wTrace = [wTrace, ii];
    end
end

switch B.Stim(1).modality
    case 'Optical'
        [IntMin,iimin] = min([B.C.Ical(wTrace)]);
        indexBeraTrace = wTrace(iimin);
    case'Acoustic'
        [IntMin,iimin]  = min([B.Stim(wTrace).intensity]);
        indexBeraTrace = wTrace(iimin);
end

if isempty(IntMin) && isempty(indexBeraTrace)
    IntMin =nan;
    indexBeraTrace =nan;

end

end
