function H = xplot(varargin)
% xplot - add plot to existing plot(s)
%    xplot(..) sets the current figure in "hold on mode", calls
%    plot(..) and restores the original hold mode of the current axes.
%    xplot also brings the current plot to the foreground.
%
%    xplot(..., 'n') is equivalent to plot(...). ['n' for 'new']
%
%    xplot returns the handles returned by plot.
%
%    See also figure, dplot, xdplot.

if nargin<1,
    error('Not enough input arguments.');
end

%figure out whether first input arg is handle to axes
if issinglehandle(varargin{1}) && isequal(get(varargin{1}, 'Type'),'axes'),
    hax = varargin{1}; % use these axes
    varargin = varargin(2:end); %remove handle from list
else,
    hax = gca;
end

if (nargin>1) && isequal('n', varargin{end}),
    % by convention xplot(..., 'n') is equivalent to plot(...)
    h = plot(hax, varargin{1:end-1});
else, % add plot
    ih = ishold(hax);
    hold(hax, 'on');
    h = plot(hax, varargin{:});
    if ~ih, hold(hax, 'off'); end
end
if  isempty(myflag('neverfocus')), 
    figure(parentfigh(hax));
end

% only return outarg if explicitly requested (suppress unwanted echoing)
if nargout>0,
    H  = h;
end
