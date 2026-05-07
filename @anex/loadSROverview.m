function [meanSpikeRates,spikeRateAllReps]=loadSROverview(ee,ExpType,t_start,t_stop)
% This is a function to load the overview of IC experiments recorded for an
% animal and a specific experiment type. These overviews are created and
% saved by the CreateOverview.m function in a previous step. 
% Input:
% ee - Anex object
% ExpType- char containing the experiment type for which the overview
% should be loaded. Note: This can only load for one experiment type at a
% time. 
% Output: meanSpikeRates -- 32xN Double array conatining the mean spike
% rates over all  Reps for all performed stimulus presentations over all experiments of
% this type separated by the 32 electrodes.
% spikeRateAllReps -- similar to mean spikeRates 32XNxR, SR split up for
% the R repetititions (usually 30)
save_name_SR = strcat("Spike_Rate_Overview_",ee.ExpID,"_",ExpType,'_',num2str(t_start),'_',num2str(t_stop),".mat");
overviewtab_singleNB=fullfile(expProcDataDir,'ICME','Overviews',save_name_SR);
load(overviewtab_singleNB,'meanSpikeRates','spikeRateAllReps');
end
