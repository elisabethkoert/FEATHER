function S = span(X,Z, MinSpan);
% span - minimumm and maximum of in array  
%
%   span(X) returns [min(X); max(X)] when X is a matrix or column array and
%   [min(X), max(X)] when X is a row array.
%
%   S = span(X,F) applies "zoom factor" F, i.e. 
%     S = mean(S1) + Z*[-0.5 0.5]*diff(S1) where S1=span(X).
%
%   S = span(X,F, MinSpan) extends the span symmetrically to MinSPan if it
%   is smaller than MinSpan.
%
%   See also DataSpan.

[Z, Minspan] = arginDefaults('Z, MinSpan',1, []);

S = [min(X); max(X)];
M = mean(S);
D = Z*diff(S)/2;
if ~isempty(Minspan),
    D = max(D, MinSpan/2);
end
S = [M-D; M+D];

if numel(X)>1 && size(X,1)==1,
    S = S.';
end



