function [fig] = makeRasterPlot(obj,stim_criteria_array,elecs,y_label,ScatterMarkerSize)
% icme\makeRasterPlot plots the raster plot for a given ICME 
% for a subset of stimuli and electrodes
%
% input:
% 	obj icme 
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the y axis parameter in the rasterplot will be the property
%      described in the first row, thsi should optimally be the  only
%      changing parameter in the stimulation (you can exclude others by
%      fixing them on one value in the second or thisr row of the array)
%      exp.  [4,10,500;1,30,34] % stimuli with increasing rep_rate but only
%      for full intensity of ~32 mW (need to keep a range due to not
%      exactly calibrated lasers
%   elecs list of int ( in 1:32) : electrode IDs to take the spiketimes from
%   y_label (string): y label of the plot, default "repetition rate [Hz]"
%   ScatterMarkerSize (int): size to plot the idnividual dots in (default 5)
% output:
%   fig (raster plot figure of all spikes detected on all electrodes given
%       in elecs where the stimulation fullfills the criteria given in the
%       stim_criteria_array sorted by the stimulus described in the first row
%       of the stim_criteria_array


if ~exist('y_label')
    y_label='repetition rate [Hz]';
end
if ~exist('ScatterMarkerSize')
    ScatterMarkerSize=5;
end

% try if the calibrated Stimlist exists
if isfield(obj.C,'stimlistCal')
    OBJ_stimlist=obj.C.stimlistCal;
else
    OBJ_stimlist=obj.Stim.stimlist;
end


stim_ID=1:1:length(OBJ_stimlist(:,1));
for jj=1:size(stim_criteria_array,1)
    stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
    stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
    stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
    stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
end

 % collect all spikes that fulfill the requirements
Spik_list=[];
for elec_ix=1:length(elecs)
    elec=elecs(elec_ix);
    elec_name=strcat('elec', num2str(elec-1));
    Spik_list_cur=obj.SL.spik_list_all.(elec_name);
    ix=ismember(Spik_list_cur(:,1),stim_ID);
    Spik_list=[Spik_list;Spik_list_cur(ix,:)];
end

usedStimuli=OBJ_stimlist(stim_ID,stim_criteria_array(1,1));
y_ticks=1:1:length(OBJ_stimlist(stim_ID,stim_criteria_array(1,1)));
fig=figure();
[~,~,cur_y_plot]=unique(Spik_list(:, 1));
cur_y_plot=cur_y_plot-Spik_list(:, 2)/30;
scatter(Spik_list(:, 6), cur_y_plot, ScatterMarkerSize ,'k','filled');

xlim([-0.02 max(obj.Stim.dura)+0.02]);
xlabel('time [s]');
yticks(y_ticks)
yticklabels(num2str(usedStimuli(y_ticks)))
ylabel(y_label);

end