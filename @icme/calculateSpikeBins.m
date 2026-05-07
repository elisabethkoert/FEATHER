function [PSTH,PSTH_reps, bin_centers] = calculateSpikeBins(IC,stim_criteria_array,elecs, t_start,t_stop,PSTH_binsize )
%% calculates a PSTH/binned Spikes for the specified parameter and the iceme
% This script creates the PSTH for one icme for all stimuli with the gicen set of stimuli criteria  in the given time
% window tstart-tstop. ones it is added up over all repetitions(PSTH),
% once it is separated by all reps (PSTH_reps)
% Normally it summs over the given electrodes. For separation between
% electrodes the function has to be called separately for each electrode.
% output
%   PSTH: (1xn double) actual PSTH of the detected spikes
%   PSTH_reps (Rxn double) with R being the number of repetitions for the
%   experiment
%   bin_centers: (1xn) of the centers of the PSTH bins (ms)
%   
% input:
%   	IC: icme
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   elecs: list[int] which electrodes the spikes should be taken from
%   t_start: float/int start timepoint for histogram bins and also response time analysis
%   t_stop: float/int end of histogram bins/ analysis of spikerate
%   PSTH_binszize: float binsize in ms
    if ~exist('t_start')
         t_start = 0;% time before and after a trigger that is supposed to be investigated
    end
    if ~exist('t_stop')
         t_stop = 150;% time before and after a trigger that is supposed to be investigated
    end
    if ~exist('PSTH_binsize')
         PSTH_binsize=1;% 0.25 ms used in MAria Michael paper 2023
    end
    % try if the calibrated Stimlist exists    
    if isfield(IC.C,'stimlistCal')
        OBJ_stimlist=IC.C.stimlistCal;
    else
        OBJ_stimlist=IC.Stim.stimlist;
    end
    %% Extract the relevant spikes
    % get the relevant stim_ID
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
        Spik_list_cur=IC.SL.spik_list_all.(elec_name);
        ix=ismember(Spik_list_cur(:,1),stim_ID);
        Spik_list=[Spik_list;Spik_list_cur(ix,:)];
    end
%% create PSTH with quantification for a time_window
%reps=unique(Spik_list(:,2));
reps=1:30; % NA 19.12.2024 changed so that it also finds reps that do not have Spikes
for ll=1:length(reps) % NA 17.12.2024 added so that also the PSTHs for the individual reps are collected
    rep_ix=find(Spik_list(:,2)==reps(ll));
    [PSTH_reps(ll,:),edges] = histcounts(Spik_list(rep_ix, 6)*1000,'BinWidth',PSTH_binsize,'BinLimits',[t_start,t_stop]);
end
    PSTH=sum(PSTH_reps,1);
    bin_centers=(edges(1:end-1) + edges(2:end)) / 2;
   
end