function []=plotHeatmap_evokedSR_dPbase1_contour(IC,stim_criteria_array,t_start,t_stop,max_SR,SR_lines,colormap_2use,linewidth_2use)
%% This is a function to plot contour line heatmaps as done in previous publications
% Input: 
%   IC: icme object
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [4,50,90;1,1000,1000] a 1000 Hz pure tone btw 1000 and 32000 Hz with
%      50-90 dB (increasing lvl)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   t_start (double) start of timewindow in which to extract the spike rate
%   t_stop (double) stop of time window in which to analysie the spike rate
%   max_SR (double) limit for color_map
%   SR_lines (nx1 double) at what evoked SR levels to draw extra lines 
%   colormap_2use ('string', default 'parula') name of the colormap to use in drawing
% Output: no output, figure has to be opened before calling the function

if nargin < 8 || isempty(linewidth_2use)
    linewidth_2use = 1;
end

if nargin < 7 || isempty(colormap_2use)
    colormap_2use = 'parula';
end
if nargin < 6 || isempty(SR_lines)
    SR_lines = [200, 300, 400];
end
if nargin < 5 || isempty(max_SR)
    max_SR = 400;
end


if ~numel(SR_lines)>3
    warning('Too high number of dPrime Contours, will only plot the first 3')
end
hold on
% First get the dPrime-Array
[all_d_prime_results]=calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
cur__dPrime_data=all_d_prime_results{1,1}.all_Dprime_array;
Lvl=all_d_prime_results{1, 1}.changing_var_values;
% Calculate the SR array
[all_evoked_spike_rate] = calculateEvokedSpikeRate(IC,stim_criteria_array, t_start,t_stop );
cur_SR_data=all_evoked_spike_rate(1,1).meanEvokedSpikeRate;
% plot the filled contours
[C, h] = contourf(Lvl(1:end), 1:1:32,cur_SR_data, [floor(min(min(cur_SR_data))):0.5:ceil(max(max(cur_SR_data)))]);
set(h,'LineColor','none');
set(h,'HandleVisibility','off');
set(h,'LineWidth',linewidth_2use);
c = colorbar('eastoutside'); 
caxis([0 max_SR]); 
set(c,'XTick',[0:100:max_SR]); 
colormap(colormap_2use);
% plot dP Contour
[C, h] = contour(Lvl(1:end),1:1:32, cur__dPrime_data, [1,1]);  
set(h,'LineColor','k');
set(h,'LineWidth',linewidth_2use);
set(h,'LineStyle','-')
set(h,'DisplayName','threshold')
% plot the SR contours
line_styles={':','--','-'};
for kk=1:numel(SR_lines)
    [C, h] = contour(Lvl(1:end),1:1:32, cur_SR_data, [SR_lines(kk),SR_lines(kk)]);
    set(h,'LineColor','w');
    set(h,'LineWidth',linewidth_2use);
    set(h,'LineStyle',line_styles{kk})
    set(h,'DisplayName',sprintf('%i Hz',SR_lines(kk)))
end
ylabel(c, ['evoked SR [Hz]']); %cur_cmap = get(f1,'Colormap'); set(f1,'Colormap',flipud(cur_cmap));
 ax = gca;
 ax.YDir = 'reverse';
 ax.LineWidth = linewidth_2use;  % Sets the box/axis lines to thickness 3
box on;
end