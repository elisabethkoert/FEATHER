function varargout = processedDataDirPath(action, val)
% path to the processed data directory-do not change if working at IAN 
% Usage:
%   p = processedDataDirPath();            % get
%   processedDataDirPath('set', path);     % set (this Matlab session only)
%   processedDataDirPath('reset');         % reset to default
persistent pth

if isempty(pth)
    pth = fullfile('public','Data','invivoelectrophysiologyFEATHER'); % expecting the UKONMAP to point to UKON100
end

if nargin == 0
    if nargout==0
        disp(pth); 
    else 
        varargout{1} = pth; 
    end
    return
end

switch lower(action)
    case {'get'}
        varargout{1} = pth;
    case {'set','put'}
        validateattributes(val, {'char','string'}, {'nonempty'});
        varargout{1} = char(val);
        pth=val;
        if nargout, varargout{1} = pth; end
    case {'reset','clear'}
        pth =  fullfile('public','Data','invivoelectrophysiologyFEATHER'); 
        if nargout, varargout{1} = pth; end
    otherwise
        error('Unknown action. Use ''get'', ''set'' or ''reset''.')
end



end


