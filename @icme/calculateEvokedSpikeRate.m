function [all_evoked_spike_rate] = calculateEvokedSpikeRate(obj,stim_criteria_array, t_start,t_stop )
% icme\calculateEvokedSpikeRate calculates evoked spike rate [Hz]
% for all stimuli defined in stim_criteria_array by subtracting baseline spike rate before trigger from the the response spike rate in [t_start,t_stop]
% input:
%   obj (icme)
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [column in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%       the fixed stimulus will be the property described in the second row    
%   t_start double analysis time window start
%   t_stop double analysis time window stop
% output
%   meanEvokedSpikeRate 32xn_stimuli array with mean evoked spike rates calculated in the
%       time window for each presented stimulus
%   meanBaselineSpikeRate 32xn_stimulix30 all spike rates
%   calculated in the baseline window right before the trigger

% try if the calibrated Stimlist exists
if isfield(obj.C,'stimlistCal')
    OBJ_stimlist=obj.C.stimlistCal;
else
    OBJ_stimlist=obj.Stim.stimlist;
end

% figure out which stimuli are investigated
stim_ID=1:1:length(OBJ_stimlist(:,1));
for jj=1:size(stim_criteria_array,1)
    stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
    stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
    stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
    stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
end
fixedStimStimList_ix=stim_criteria_array(2,1);%freq
changing_var_ix=stim_criteria_array(1,1);%SPL dB


fixedStimList=unique(OBJ_stimlist(stim_ID,fixedStimStimList_ix));
num_StimVars=length(fixedStimList);

% calculate absolute spike rate
[meanSpikeRates, ~] = calculateSpikeRate(obj, t_start,t_stop );
%define baseline rate window 
t_start_baseline=-t_stop;
t_stop_baseline=-t_start;
% calculate basline spike rate 
[meanBaselineSpikeRate, ~] = calculateSpikeRate(obj, t_start_baseline,t_stop_baseline );
% define mean evoked rate
meanEvokedSpikeRate=meanSpikeRates-meanBaselineSpikeRate;
for fixedStim_ix=1:num_StimVars
        % determined the current fixed stimulus for which the d'
        % analysis is performed (eg. freq=500Hz) for tonotopy
        cur_fixed_var=fixedStimList(fixedStim_ix);
        cur_stim_ixs=stim_ID(ismember(stim_ID, find(OBJ_stimlist(:,fixedStimStimList_ix)==cur_fixed_var)));
         % check if you have any double presentations of stimuli
        changing_var_all=OBJ_stimlist(cur_stim_ixs, changing_var_ix); % tonotopy this is dB
        [~, indices_unique, ~] = unique(changing_var_all);
        cur_stim_ixs=cur_stim_ixs(indices_unique);       
        % cut down the arrays to only wanted stimuli
        cur_stimlist=OBJ_stimlist(cur_stim_ixs,:);
        changing_var=cur_stimlist(:, changing_var_ix); 
        cur_evokedSpikeRates=meanEvokedSpikeRate(:,cur_stim_ixs);
        cur_baselineSpikeRates=meanBaselineSpikeRate(:,cur_stim_ixs);
        all_evoked_spike_rate(fixedStim_ix).meanEvokedSpikeRate=cur_evokedSpikeRates;
        all_evoked_spike_rate(fixedStim_ix).meanBaselineSpikeRate=cur_baselineSpikeRates;
        all_evoked_spike_rate(fixedStim_ix).fixed_var_value = cur_fixed_var;
        all_evoked_spike_rate(fixedStim_ix).changing_var_values=changing_var; 
end

