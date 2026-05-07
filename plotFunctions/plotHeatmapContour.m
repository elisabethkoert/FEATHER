function []=plotHeatmapContour(IC,mode,stim_criteria_array,t_start,t_stop,max_dPrime,dP_lines,colormap_2use)
%% This is a function to plot contour line heatmaps as done in previous publications
% Input: 
% IC: icme object
%stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [4,50,90;1,1000,1000] a 1000 Hz pure tone btw 1000 and 32000 Hz with
%      50-90 dB (increasing lvl)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   t_start (double) start of timewindow in which to extract the spike rate
%   t_stop (double) stop of time window in which to analysie the spike rate
%Output: no output, figure has to be opened before calling the function
if nargin==5 && ~exist("max_dPrime") && ~exist("dP_lines") && ~exist("colormap_2use")
    max_dPrime=3;
    dP_lines=[1,2,3];
    colormap_2use='parula';
end
% First get the dPrime-Array
[all_d_prime_results]=calculateDprimeMultipleStimVars(IC,mode,stim_criteria_array,t_start,t_stop);
cur_data=zeros(size(all_d_prime_results{1,1}.all_Dprime_cumsum,1),size(all_d_prime_results{1,1}.all_Dprime_cumsum,2)+1);
cur_data(:,2:end)=all_d_prime_results{1,1}.all_Dprime_cumsum;
stim_criteria_array_baseline=stim_criteria_array;
stim_criteria_array_baseline(1,[2:3])=0;
% calculate the baseline value for the 0 mW condition
d_prime_baseline=calculateDprime(IC,'baseline',stim_criteria_array_baseline,t_start,t_stop);
cur_data(:,1)=d_prime_baseline.all_Dprime_array;
Lvl=all_d_prime_results{1, 1}.changing_var_values;
% plot the filled contours
[C, h] = contourf(Lvl(1:end), 1:1:32,cur_data, [floor(min(min(cur_data))):0.5:ceil(max(max(cur_data)))]); hold on; set(h,'LineColor','none')
c = colorbar('eastoutside'); clim([0 max_dPrime]); set(c,'XTick',[0:1:max_dPrime]); colormap(colormap_2use);
for i=1:numel(dP_lines)
[C, h] = contour(Lvl(1:end),1:1:32, cur_data, [dP_lines(i),dP_lines(i)]); hold on; set(h,'LineColor','w');set(h,'LineWidth',1);set(h,'LineStyle',':')
end
ylabel(c, ['d' sprintf( '\''' ) '-value']); %cur_cmap = get(f1,'Colormap'); set(f1,'Colormap',flipud(cur_cmap));
set(gca,'YTick',[2:2:32], 'Xtick', Lvl(2:end), 'Xticklabel',  round(Lvl(2:1:end),2));
set(gca,'FontSize',12)
 ax = gca;
 ax.YDir = 'reverse';
box on;
end