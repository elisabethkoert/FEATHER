function fig = changeFigureSize(fig, fraction, height_ratio)
    % changeFigureSize  Change a figure's on-screen size so its width equals
    %                   fraction * A4_width (A4 width = 21.0 cm).
    %
    % Usage:
    %   changeFigureSize([], 1/3)           % change current figure to 1/3 A4 width
    %   changeFigureSize(figH, 1/2, 0.5)     % change figH to 1/2 A4 width and 12 cm height
    %
    % Inputs:
    %   fig        - (optional) figure handle. If empty or omitted, gcf is used.
    %   fraction   - scalar: fraction of A4 width (e.g. 1/3, 1/2, 1)
    %   height_ratio  - (optional) desired figure width/height ratio Default = 0.8 
    %
    % Output:
    %   fig        - the figure handle that was modified
    %
    % Notes:
    % - This function ONLY changes the figure's on-screen Position (Units='centimeters').
    %   It does NOT change PaperSize/PaperPosition or export anything. If you later
    %   export to PDF and want the PDF page width to match, set PaperSize/PaperPosition
    %   (or use exportgraphics) separately.
    
    if nargin < 1 || isempty(fig)
        fig = gcf;
    end
    
    if nargin < 2 || isempty(fraction)
        error('You must provide a fraction of A4 width (e.g. 1/3, 1/2, 1).');
    end
    
    if nargin < 3 || isempty(height_ratio)
        height_ratio = 0.8;
    end
    
    % Validate figure
    if ~ishandle(fig) || ~strcmp(get(fig,'Type'),'figure')
        error('First argument must be a valid figure handle or empty.');
    end
    
    % A4 width in cm
    A4_width_cm = 21.0;
    
    % calculate target width and height in cm
    target_width_cm = fraction * A4_width_cm;
    
    target_height_cm = height_ratio * target_width_cm;

    % set figure size in centimeters (Position uses [left bottom width height])
    set(fig, 'Units', 'centimeters');
    pos = get(fig, 'Position');
    % keep left/bottom, update width & height
    pos(3) = target_width_cm;
    pos(4) = target_height_cm;
    set(fig, 'Position', pos);
    
    % return figure handle
end
