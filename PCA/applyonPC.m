function [array_PCA]=applyonPC(is_array,no_PC,coeff, plotPC,legend_header)
% This is a function that projects a spike count array onto a PC space. 
% The projected array can be used for further dissimilarity analysis. 
% Input: 
% is_array: X*1 cell array with each cell containing an MxT double array
% with M being the umber of Multi Units and the being the number of time
% bins. 
% No_PC double, this is the number of principal components that the data
% should be projected on
% coeff:DxX double array with D being the first D PC.These are the
% principal component coefficients.
%% The following variables needed for plotting should only be entered if plotting is wanted
% plot PC this is a 2X1 double containing the 2 prinicpial components that
% shouldbe used for the visualization plots. 
% Legend_header: Double array: Header for the legend as a number( (directly
% extracted from the sti criteria array.)
% Output: 
% arra_pca: No_PCxT double array containing the projected data. 

if nargin>3 % This means plotting variables are given
    plot_bool=1;
    if ~length(plotPC)==2
        error('For plotting there should only be 2 prinicpal components entered.')
    end
    if ~length(legend_header)==size(is_array,1)
        error('Give a legend header that has the same size as the array that will be projected.')
    end
else
    plot_bool=0;
end
array_PCA=cell(1,size(is_array,2));
for i=1:size(is_array,2)
    is_array{i}=is_array{i}';
    array_PCA{1,i}=(is_array{i}-mean(is_array{i},2))*coeff(:,1:no_PC);% mean is substracted before projection as the same is done for the PCA --> this may be questionable 
end
if plot_bool==1
    clear('i');
    colors = lines(numel(legend_header));
    figure()
    tiledlayout(3,2);
    nexttile(1);
    hold on
    for i=1:length(legend_header)
         legendLabels{i} = [num2str(legend_header(i))]; % Customize the label as needed
        plot(array_PCA{1,i}(:,plotPC(1)),'Color', colors(i, :), 'LineWidth', 1.5, 'Marker','o');
         %legend(legendLabels, 'Location', 'best'); % Legend is currently
         %only shown in the last tiled plot (NA 28.12.2024)
         ylabel('PC 1');
         xlabel('Time [ms]')
         title('Traces in PC 1')
        % ylim([-10 30])
    end
    clear('i')
    hold off
%     figure()
    nexttile(2);
    hold on
    for i=1:length(legend_header)
         legendLabels{i} = [num2str(legend_header(i))]; % Customize the label as needed
        plot(array_PCA{1,i}(:,plotPC(2)),'Color', colors(i, :), 'LineWidth', 1.5, 'Marker','o');
         %legend(legendLabels, 'Location', 'best');
         ylabel('PC 2');
         xlabel('Time [ms]')
         title('Traces in PC 2')
         %ylim([-10 30])
    end
    clear('i')
    nexttile([2,2]);
    hold on
    for i=1:length(legend_header)
         legendLabels{i} = [num2str(legend_header(i))]; % Customize the label as needed
         plot(array_PCA{1,i}(:,plotPC(1)),array_PCA{1,i}(:,plotPC(2)),'Color', colors(i, :), 'LineWidth', 1.5);
         % scatter(array_PCA{1,i}(:,plotPC(1)),array_PCA{1,i}(:,plotPC(2)),'Color', colors(i, :))
         legend(legendLabels, 'Location', 'best');
         ylabel('PC 2');
         xlabel('PC 1')
         title('Differentiation in PC 1 vs 2')
        % ylim([-10 30])
         %xlim([-10 30])
    end
set(gcf, 'Units', 'centimeters');
set(gcf, 'Position', [2, 2, 10, 15]); % Example: [left, bottom, width, height]
% fontsize(10,"points");
allAxes = findall(gcf, 'Type', 'axes');
for i=1:size(allAxes,1)
    allAxes(i).Title.FontSize=12;
end
end
end

