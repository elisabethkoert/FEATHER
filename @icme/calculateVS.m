function [VS_array,all_phases,rates] = calculateVS(obj,stim_criteria_array,t_start,t_stop)
% icme\calculateVS calculates the phase and VS for a protocol with repetitive stimulus presentation
% For each electrode all spikes in the timewindow (t_start,
% t_stop) are collected, then aligned within the stimulus cycle and the VS
% is calculated as vs = sqrt((sum(cos(spiketimes_in_cycle))^2)+(sum(sin(spiketimes_in_cycle))^2))/length(spiketimes_in_cycle);
% Then the Rayleigh test is used to check if the VS is significant 
%    L=2*length(spiketimes_in_cycle)*(vs^2);
%    L>=13.8 alpha 0.001; (currently used); 
%    L>=9.21 alpha 0.01; 
%    L>=5.99 alpha 0.05
%
% input:
%   obj (icme) IC recording object, 
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli 
%     [collum in stimlist, min value, max value]
%     first row should describe the stimulation rate
%   t_start (double [ms]) start of timewindow in which to extract the spike rate
%   t_stop (double [ms]) stop of time window in which to analysie
%
% output
%   VS_array (n_elecs x n_rates) caclulated VS, set to 0 if Rayleigh
%       criterion is not fullfilled
%   all_phases (struct) with fields elecX_00Hz with the spiketimes within a
%       phase for each electrode and rate
%   rates (n_ratesx1) investigated rates

% % try if the calibrated Stimlist exists
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


rates=OBJ_stimlist(stim_ID,stim_criteria_array(1,1));

all_electrode_names=obj.SL.all_electrode_names;


VS_array=zeros(length(all_electrode_names),length(stim_ID));
all_phases = {};

for elec_ix = 1:length(all_electrode_names)
    elec_name=strcat('elec',num2str(elec_ix-1));
    Spik_list=obj.SL.spik_list_all.(elec_name);
   % loop through sitmuli
        for stim_ix = 1:length(stim_ID)
            curStim = stim_ID(stim_ix);
            rate=OBJ_stimlist(curStim,stim_criteria_array(1,1));
            relevant_spiketimes = Spik_list((Spik_list(:,1) == curStim  & Spik_list(:,6) > t_start/1000 & Spik_list(:,6) <= t_stop/1000), 6);
            t_cycle = 1/rate;
            
            spiketimes_in_cycle = [];
            for i_rel_spike = 1:length(relevant_spiketimes)
                t_spik = relevant_spiketimes(i_rel_spike);
                delta_stim_spike = mod(t_spik, t_cycle);
                phase = 2*pi*(delta_stim_spike/t_cycle);
                spiketimes_in_cycle = vertcat(spiketimes_in_cycle, phase);
            end
            
            vs = sqrt((sum(cos(spiketimes_in_cycle))^2)+(sum(sin(spiketimes_in_cycle))^2))/length(spiketimes_in_cycle);
            % Rayleigh test
            L=2*length(spiketimes_in_cycle)*(vs^2);
            
            %L>=13.8 alpha 0.001; L>=9.21 alpha 0.01; L>=5.99 alpha 0.05
            if L>=13.8
                vs=vs; 
            else 
                vs=0;
            end
            
            VS_array(elec_ix, stim_ix) =vs;
            fieldname = sprintf('%s_%iHz',elec_name,rate);
            all_phases.(fieldname) = spiketimes_in_cycle;
        end
end


end