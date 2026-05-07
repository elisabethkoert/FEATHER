function [fig]=plotPSTHHeatmap(IC,stim_criteria_array,t_start,t_stop,PSTH_binsize,kernel_width)
% icme\gplotPSTHMap calcualtes the PSTH for each electrode for a given time
% window and stimulus, results are plotted as a heatmap where x repersents
% time and y the different electrodes
% 
% output
%  Figure showing the heatmap of the PSTH over all electrodes
% input:
%   	IC: icme
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   t_start: float/int start timepoint for histogram bins and also response time analysis
%   t_stop: float/int end of histogram bins/ analysis of spikerate
%   PSTH_binszize: float binsize in ms
% kernel_width: float in ms for the window used for kernel smoothin, if this
% is 0 then no smoothing is apllied
%% get PSTH
[array_reps, array_all,bin_centers]=getPSTHarrayAllMU(IC,stim_criteria_array,t_start,t_stop,PSTH_binsize);
if ~kernel_width==0
    array_all=get_smooth(array_all,PSTH_binsize,kernel_width);
end
%% Do plots
x_values=bin_centers;
all_electrodes=IC.SL.all_electrodes;
fig = nonuniformHM(x_values,(all_electrodes+1)',array_all);
caxisLimits = [0; max(max(array_all))];
title([])
colormap(parula(2*ceil(caxisLimits(2))))
        % Set the colormap limits
if exist('clim')
    c=colorbar;
    clim(caxisLimits)
    c.Ticks=0:1:caxisLimits(2);
else
    caxis(caxisLimits)
end       
xlabel('Time [ms]')
ylabel('electrode #')
%make y-axis more sparse for readability
set(gca,'YTick', 1:4:32, 'YtickLabel', 1:4:32)
set(gca,'XTick',x_values(1:10:end),'XTickLabel',x_values((1:10:end)))
xtickangle(45) 
