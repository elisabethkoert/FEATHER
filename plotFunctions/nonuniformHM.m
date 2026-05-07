function fh = nonuniformHM(x_centers,y_centers,data)


% Calculate the edges of the columns and rows
x_edges = [(x_centers(1) - (x_centers(2) - x_centers(1)) / 2), ...
    (x_centers(1:end-1) + x_centers(2:end)) / 2, ...
    (x_centers(end) + (x_centers(end) - x_centers(end-1)) / 2)];

y_edges = [(y_centers(1) - (y_centers(2) - y_centers(1)) / 2), ...
    (y_centers(1:end-1) + y_centers(2:end)) / 2, ...
    (y_centers(end) + (y_centers(end) - y_centers(end-1)) / 2)];


% Fill the arrays with corner coordinates and colors
% Create the heatmap with proportional box dimensions
fh = figure;
hold on;

% Loop through the data and create patches for each box
for i = 1:length(y_centers)
    for j = 1:length(x_centers)
        % Calculate the coordinates of the corners of the box
        x_corners = [x_edges(j), x_edges(j), x_edges(j+1), x_edges(j+1)];
        y_corners = [y_edges(i), y_edges(i+1), y_edges(i+1), y_edges(i)];
        % Create the patch
        patch(x_corners, y_corners, data(i, j), 'EdgeColor', 'none');
    end
end

% Adjust the axis properties
colorbar;  % Add a colorbar for reference
title('Heatmap with Proportional Box Dimensions');
axis tight;
set(gca, 'YDir', 'reverse'); % Reverse the y-axis
hold off;

% Optionally adjust the display labels if necessary
xticks(x_centers);  % Set the ticks to match the x center coordinates
xticklabels(arrayfun(@num2str, x_centers, 'UniformOutput', false));  % Custom labels for the columns
yticks(y_centers);  % Set the ticks to match the y center coordinates
yticklabels(arrayfun(@num2str, y_centers, 'UniformOutput', false));  % Labels for the rows
end




