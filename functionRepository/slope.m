function s = slope;
% slope - estimate slope of curve using mouse clicks
%    slope calls ginput to click twice on the current figure and then
%    returns the slope dy/dx.
%
%    If XScale property of the axes is log, and the YScale is lin, the
%    slope is given in "dy per octave", or dy/d(log2(x)), i.e. the y
%    variations per doubling of the X value.
% 
%    If X is shown in a lin scale and Y on log scale, dlog(y)/dx is given.
% 
%    If both X and Y are shown in log units, dlog2(y)/dlog2(x) is given.
%
%    See also ginput.

qq = ginput(2);
xplot(qq(:,1),qq(:,2),'k');
Xsc = get(gca,'Xscale');
Ysc = get(gca,'Yscale');
X = qq(:,1);
Y = qq(:,2);
if isequal('log', Xsc),
    X = log2(X);
end
if isequal('log', Ysc),
    Y = log2(Y);
end
s = diff(Y)/diff(X);


