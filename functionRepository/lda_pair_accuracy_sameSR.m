function acc = lda_pair_accuracy_sameSR(X1, X2)
% lda_pair_accuracy_sameSR measures how well the responses to two stimuli can
% be told apart by a linear classifier
% Both response sets are recorded at the same evoked firing rate, so that the
% classifier cannot separate them by overall activity and has to use the
% pattern across the recorded units. A linear discriminant is trained on the
% single-trial population responses and its accuracy is estimated by repeated
% five-fold cross-validation.
%
% input:
%   X1 (n1 x u double) single-trial responses to the first stimulus, one row
%       per trial and one column per recorded unit
%   X2 (n2 x u double) the same for the second stimulus
% output:
%   acc (double) fraction of trials classified correctly, averaged over 50
%       repeats of five-fold cross-validation. Chance is 0.5 because the two
%       classes are balanced. NaN when the pair could not be classified, see
%       below.
%
% assumptions:
%   The two classes are balanced by drawing the same number of trials at random
%   from each, so that chance level is exactly 0.5 and accuracy is not inflated
%   by an unequal class size.
%   Trials with a missing value in any unit are dropped, and units without
%   variance in either class are dropped, because a linear discriminant cannot
%   use them.
%   NaN is returned when fewer than two trials per class survive, when no unit
%   is left, or when a class has fewer than five trials, which is the number
%   five-fold cross-validation needs.
%   The result is not deterministic: both the balancing and the
%   cross-validation folds are drawn at random and no seed is set, so repeated
%   calls on the same data differ slightly.

    n1 = size(X1,1);
    n2 = size(X2,1);

    nMin = min(n1, n2);
    if nMin < 2
        acc = NaN;
        return
    end

    % balance the two classes by taking the same number of trials at random
    % from each, so that chance level is exactly 0.5
    ix1 = randperm(n1, nMin);
    ix2 = randperm(n2, nMin);
    X1 = X1(ix1, :);
    X2 = X2(ix2, :);

    % a trial is only usable if every unit has a value for it
    X1 = X1(~any(isnan(X1),2), :);
    X2 = X2(~any(isnan(X2),2), :);

    nMin = min(size(X1,1), size(X2,1));
    if nMin < 2
        acc = NaN;
        return
    end

    X1 = X1(1:nMin, :);
    X2 = X2(1:nMin, :);

    % a unit that does not vary within a class carries no information for a
    % linear discriminant and makes the covariance estimate singular
    v1 = var(X1, 0, 1);
    v2 = var(X2, 0, 1);
    keep = (v1 > 0) & (v2 > 0);

    X1 = X1(:, keep);
    X2 = X2(:, keep);

    if size(X1,2) == 0
        acc = NaN;
        return
    end

    X = [X1; X2];
    Y = [ones(size(X1,1),1); 2*ones(size(X2,1),1)];

    kfold = min(5, min(sum(Y==1), sum(Y==2)));
    if kfold < 5
        acc = NaN;
        return
    end


    % pseudoLinear uses the pseudo-inverse of the pooled covariance, which
    % stays defined when there are more units than trials
    Mdl = fitcdiscr(X, Y, 'DiscrimType', 'pseudoLinear');
    

   nRep =50;
   acc_rep = nan(nRep,1);
    
   % repeat the cross-validation so that the accuracy does not depend on one
   % particular random split into folds
   for irep = 1:nRep
       CV = crossval(Mdl, 'KFold', 5);
       acc_rep(irep) = 1 - kfoldLoss(CV);
   end
    
   acc = mean(acc_rep);
end