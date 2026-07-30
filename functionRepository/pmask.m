function ma = pmask(x, Y);
% PMASK - plot mask for selective plotting 
%   M = PMASK(V), where V is a logical vector, returns a vector the
%   same size as V with zeros where V is true and NaNs where ~V.
%   When added to a plot argument, data points k for which V(k)==0 are 
%   not plotted.
%
%   pmask(x,Y) is samesize(pmask(x),y)

ma = 0*x;
inx = find(~x);
if ~isempty(inx), ma(inx) = nan; end;
if nargin>1,
    ma = samesize(ma,Y);
end


