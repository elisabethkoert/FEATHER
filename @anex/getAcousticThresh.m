function threshold=getAcousticThresh(ee,freq,bw,dPrimeMode,dPrimeValue, t_start, t_stop)
% This is a function to get the threshold for a certain dPrime-value for a
% single channel acoustic experiment. This is at the moment only used for
% NA experiments.
% Input:
% ee: anex object (the right animal experiment)
% freq: 1x1 double value, frequency in Hz
% bw: 1x1 double: Bandwidth in octaves (0 for a pure tone) 
% dPrimeMode: character array: 2 possible modes, 'increasingLvl' or
% 'baseline'
% dPrimeValue: 1x1 double, dPrimeValue for which the threshold should be
% given
% t_start, t_stop: 1x1 double each, containing the start nad the stop in ms
% for the SR calculation for DPrime function
% Output: 
%Threshold: 1x1 double containing the threshold for the given input
%Note: when there were multiple exepriments for the given frequency and
%bandwidth, then the last experiment that was not marked as invalid will be
%taken.
if ~exist("t_start",'var') && nargin==5 % this sets default values for t_start and stop when they are not given
    t_start=0;
    t_stop=150;
end

%% Load the overview, atmthe function is specific for NA experiments
stim_list_all=loadStimOverview(ee,'Single_NB');
is_ix=unique(stim_list_all(find(stim_list_all(:,2)==bw & stim_list_all(:,1)==freq),end));
if length(is_ix)>1
    warning('Multiple experiments for the given input found, last one taken');
end
is_ix=is_ix(end);
L =listIcme(ee);
IC=loadIcme(icme(ee,string(L.IC_SeriesID(is_ix))));
stim_criteria_array=[6,0, 90;1, freq, freq; 2, bw,bw];
[all_d_prime_results] = calculateDprimeMultipleStimVars(IC ,dPrimeMode,stim_criteria_array,t_start,t_stop);
dPrimeValue_ix=find(all_d_prime_results{1, 1}.analyzed_d_prime_array==dPrimeValue);
threshold=all_d_prime_results{1, 1}.thresholds(1,dPrimeValue_ix);
end