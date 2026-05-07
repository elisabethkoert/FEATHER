function [ROCmat, AUC, Dprime, SE] = ROCAna_01(IC,N, P, flag_adjustAUC)
% [ROCmat, AUC, Dprime, SE] = ROCAna_00(N, P);
% this function creates a ROC curve and calculates the corresponding area
% under the curve (AUC) as well as the Dprime value and they accompanying
% standard error 
%
% Dprime can have positive and negative values, here Dprime is not taken as
% the discriminability of two distributions - or in other words the distance
% of two distributions - but rather it is asked how likely it is that a value
% from a distribution given as POSITIVES indeed is counted as positive,
% i.e. LARGER. Thus if say one gets a distribution stemming from louder
% sounds being presented and one from a softer sound, one can ask what the
% likelihood would be that a value from the LOUDER distribution would be
% classified as louder, assuming it leads to higher values.
%
% e.g: - this leads to an AUC of 0.815 and a Dprime of 1.2678
% N = [0.3, 0.4, 0.5, 0.5, 0.5, 0.6, 0.7, 0.7, 0.8, 0.9];
% P = [0.5, 0.6, 0.6, 0.8, 0.9, 0.9, 0.9, 1.0, 1.2, 1.4];
%
%      - if N == P than AUC equals 0.5 and Dprime is 0

if nargin < 2
    help(mfilename)
    
    error('Not enough input arguments!')
end

if ~exist('flag_adjustAUC','var')  | isempty(flag_adjustAUC);
    flag_adjustAUC = 0;
end

x = [N, P]'; % data
y = [zeros(size(N)), ones(size(P))]'; % classification (real ones)

numP = numel(P);
numN = numel(N);

% figure out the thresholds to test based on the given data
listThresholds = unique(x);
listThresholds = [listThresholds(1)-0.1; listThresholds];
nThresholds = numel(listThresholds);

ROCmat = zeros(nThresholds,2);
for iThreshold = 1:nThresholds;
    curThreshold = listThresholds(iThreshold);

%     % ALGORITHM 1
%     [iAboveThr, xAboveThr] = find(x(:) > curThreshold);
% 
%     TruePos   = numel(find(y(iAboveThr) == 1))./numP;
%     FalsePos  = numel(find(y(iAboveThr) == 0))./numN;
%     
%     ROCmat(iThreshold,:) = [FalsePos, TruePos];
 
    % ALGORITHM 2
    TruePos   = sum(P > curThreshold)./numP;
    TrueNeg   = sum(N <= curThreshold)./numN;
    FalsePos  = 1-TrueNeg;
    
    ROCmat(iThreshold,:) = [FalsePos, TruePos];
end
ROCmat = flipud(ROCmat);
   
ROCforAUC = ROCmat;
% % adjust extreme values to avoid having Dprime values of infinity
% % this approach (adjustment) doesnt work this way for ROC to Dprime 
% % see MacMillan & Creelman SDT: A Users Guide 1991
% if flag_adjustROC
%     % adjust values for negatives
%     ROCforAUC(find(ROCforAUC(:,1) == 0),1) =  0.5./numN;
%     ROCforAUC(find(ROCforAUC(:,1) == 1),1) =  (numN-0.5)./numN;
%     
%     % adjust values for positives
%     ROCforAUC(find(ROCforAUC(:,2) == 0),2) =  0.5./numP;
%     ROCforAUC(find(ROCforAUC(:,2) == 1),2) =  (numP-0.5)./numP;    
% end

AUC = sum(ROCforAUC(1:end-1,2).*diff(ROCforAUC(:,1))) + sum(diff(ROCforAUC(:,1)).*diff(ROCforAUC(:,2)))./2; % AREA UNDER THE CURVE: test: if N equals P than AUC must be 0.5 and Dprime must be 0
% AUC = sum(ROCmat(1:end-1,2).*diff(ROCmat(:,1))) + sum(diff(ROCmat(:,1)).*diff(ROCmat(:,2)))./2; % AREA UNDER THE CURVE: test: if N equals P than AUC must be 0.5 and Dprime must be 0

% deal with arbitrary assignment of positive and negative if chosen to do so
AUC = abs(AUC); % in case the area under the curve is calculated to be negative - which makes no sense to have directionality
% adjust extreme AUC values which lead to +- Inf Dprime
if AUC == 1
  AUC = (numP+numN-0.5)/(numP+numN);
elseif AUC == 0
  AUC = 0.5/(numP+numN);
end
Dprime = 2*erfinv(2*AUC-1); % ALTERNATIVE: sqrt(2)*inverse of normal cumulative distribution function (AUC); leads to the same result
% the inverse function would be: AUC=norminv(Dprime./sqrt(2)) or AUC = (erf(Dprime/2)+1)./2

% calculate standard error
Q1 = AUC./(2.0 -AUC);
Q2 = (2 *AUC^2)./(1.0 +AUC);

SE = sqrt((AUC*(1.0-AUC) + (numP-1.0)*(Q1 - AUC^2) + (numN-1.0)*(Q2 -AUC^2)) / (numP * numN));

