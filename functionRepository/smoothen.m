function [Y, Nwin] = smoothen(X, Width, dt);
% smoothen - smooth data by convolution with a hamming window
%   smoothen(X, N) smooths array X by convolving X with a N-th order,
%   normalized, hamming window. N is rounded upward to the next odd mumber.
%   The result is truncated symmetrically so that it has the same length 
%   as X. If X is a matrix, its columns are smoothed. 
%
%   smoothen(X, -N) assumes that X is periodic and uses a N-long window.
%   In this case, smoothing connects the first part of X with the last.
%
%   smoothen(X, Width, dt) uses a N = round(Width/dt) as the length of the
%   window, that is, the window width is specified in the X-axis units of
%   the input array X.
%
%   smoothen(X, Width, -dt) subtracts the averages the columns of X prior 
%   to the convolution and adds the column averages afterwrds. This reduces
%   edge effects.
%
%   [X, M]=smoothen(...) also returns the length M of the hanning window
%   used for smoothing.
%
%   See also Derivative, HANNING.

if nargin<3, dt = 1; end
circular = (Width<0);
Width = abs(Width);
ZeroMean = dt<0;
dt = abs(dt);
% upward rounding of window length to next odd integer
Nhalf = round((Width/dt-1)/2);
Nwin = 2*Nhalf+1;
if Nwin<1, 
    Nwin=1; 
    Nhalf=0;
end;
if isempty(X), Y=X; return; end
Win = hamming(Nwin);
Win = Win/sum(Win); % normalize

if isvector(X) && (size(X,1)==1), % row vector -> temp turn into col vector
    X = X.'; 
    isRow=1;
else,
    isRow=0;
end
if ZeroMean,
    Av = nanmean(X,1);
    X = bsxfun(@plus, X, -Av);
end
if circular,
    Nextra = Nwin;
    ir = 1:Nextra;
    X = [X(end-Nextra+ir); X; X(ir)];
else,
    Nextra = 0;
end
doDec = (Nwin>100) && isvector(X);
Y = convmult(Win, X); % columnwise conv
Y = Y(1+Nhalf+Nextra:end-Nhalf-Nextra,:); % truncate newly formed "tails"
if ZeroMean, % restore column averages
    X = bsxfun(@plus, X, Av);
end

if isRow, Y = Y.'; end % restore original orientation


