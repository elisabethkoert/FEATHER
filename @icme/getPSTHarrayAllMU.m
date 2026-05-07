function [array_reps, array_all,bin_centers]=getPSTHarrayAllMU(IC,stim_criteria_array,t_start,t_stop,PSTH_binsize)
% icme\getPSTHarrayAllMU calcualtes the PSTH for each electrode for a given
% stimulus and joins them all in one large array 
% output
%   array_reps double array(num_elecsxrepsx num_PSTH_bins) that contains the detected spike
%   number separated for each repetitions
%   array_all: double array (num_elecsx num_PSTH_bins) that contains the detected spike
%   number summed over all repetitions
% input:
%   	IC: icme
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
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
     PSTH_binsize=1;
end
num_bins=(t_stop-t_start)/PSTH_binsize;
array_reps=zeros(32,30,ceil(num_bins));
array_all=zeros(32,ceil(num_bins));
for ii=1:32
    elecs=ii;
    [PSTH,PSTH_reps, bin_centers] = calculateSpikeBins(IC,stim_criteria_array,elecs, t_start,t_stop,PSTH_binsize);
    array_reps(ii,:,:)=PSTH_reps; % NA 17.12.2024 added so that it collects an array for all reps
    array_all(ii,:)=PSTH;
end
end