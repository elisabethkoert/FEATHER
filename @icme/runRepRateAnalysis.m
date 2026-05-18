function [rates,meanSpikeRates_respUnits,SpikesPerStimulus_respUnits,VS_array_respUnits,cutoff_fqs,all_phases] = runRepRateAnalysis(obj,stim_criteria_array,t_start,t_stop,elecs)
% icme\runRepRateAnalysis calculates common metrics for pulse train protocols
% This function calculates spike rate, number of spikes per stimulus, VS, phase, and cutoff frequency
% for a protocol with trains of stimuli presented with different stimulation rates for a subset of electrodes in a IC multiunit recording
%
% input:
%   obj (icme) IC recording object, 
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli 
%     [collum in stimlist, min value, max value]
%     first row should describe the stimulation rate
%   t_start (double [ms]) start of timewindow in which to extract the spike rate
%   t_stop (double [ms]) stop of time window in which to analyse
%   elecs (nx1 double) list of electrode IDs to use [1:1:32]
% output
%   rates (n_ratesx1) investigated rates
%   meanSpikeRates_respUnits (n_elecs x n_rates double) mean spike rate
%       during whole stimulation timewindow [Hz]
%   SpikesPerStimulus_respUnits (n_elecs x n_rates double) number of spikes
%       divided by number of presented stimuli in the whole time window
%   VS_array (n_elecs x n_rates double) calculated VS, set to 0 if Rayleigh
%       criterion is not fulfilled
%   cutoff_fqs (1xn_elecs double) for each electrode/MU the lowest rate
%       where the VS was 0 meaning the MUA was unable to follow the stimulus
%       timing
%   all_phases (struct) with fields elecX_00 with the spiketimes within a
%       phase for each electrode and rate
 
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
    
    % extract the used rates from the stimlist
    rates=OBJ_stimlist(stim_ID,stim_criteria_array(1,1));
    % calculate num_stimulu per rate
    num_stimuli=(rates*0.1)+1; % for each rate we stimulate first at 0 ms but another time at 100 ms
     % get spikerates at responsive units/ input elec list and within the defined StimCriteriaArray
    [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(obj,t_start,t_stop);
    meanSpikeRates_respUnits=meanSpikeRates(elecs,stim_ID); 
    % get number of spikes from rate by multiplying with timewindow 
    meanNumSpikes_wholeRec_respUnits=meanSpikeRates_respUnits*t_stop/1000;
    % calculate spikes per stimulus and spike propability by dividing by the numebr of
    % sitmuli dep on the rate
    SpikesPerStimulus_respUnits=meanNumSpikes_wholeRec_respUnits./num_stimuli';
    
    % calculate VS (and timing within phase) for all responsive units
    [VS_array,all_phases,rates_VS] = calculateVS(obj,stim_criteria_array,t_start,t_stop);
    VS_array_respUnits=VS_array(elecs,:);
    
    % count cut-off frequencies for individual multi-units
    cutoff_fqs = [];
    for i_n = 1:size(VS_array_respUnits, 1) % loop through all units
        cur_data = VS_array_respUnits(i_n,:);
        if isempty(find(cur_data == 0, 1, 'first')) % finds first 0 VS for an MUA
            cutoff_fqs(i_n) = NaN;
        else
            cutoff_fqs(i_n) = rates(find(cur_data == 0, 1, 'first'), 1);
        end
    end
end
