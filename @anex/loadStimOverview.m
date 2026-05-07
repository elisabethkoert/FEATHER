function [stim_list_all]=loadStimOverview(ee, ExpType)
% This is a function to load the overview of IC experiments recorded for an
% animal and a specific experiment type. These overviews are created and
% saved by the CreateOverview.m function in a previous step. 
% Input:
% ee - Anex object
% ExpType- char containing the experiment type for which the overview
% should be loaded. Note: This can only load for one experiment type at a
% time. 
% Output: stim_list_overview -- overview stimlist for the epxeriment type
% MxN Double array with M being the presented stimuli and N the stimulus
% characteristics.
save_name_stimlist = strcat("Stimlist_Overview_",ee.ExpID,"_",ExpType,".mat");
overviewtab_singleNB=fullfile(expProcDataDir,'ICME','Overviews',save_name_stimlist);
load(overviewtab_singleNB,'stim_list_all');
end
