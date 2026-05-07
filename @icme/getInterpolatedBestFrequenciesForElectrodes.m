function [interpolated_best_frequencies] = getInterpolatedBestFrequenciesForElectrodes(obj,elecs,mode,d_prime_thr)
% icme\getInterpolatedBestFrequenciesForElectrodes 
% load the tonotopy results calculated for the animal with given conditions
% and reads the interpolated best frequency for each electrode from the
% tontopy_array
% input:
% obj (icme) IC recording object
% elecs (lsit of int): electrodes for which to get the best frequency,
% default (1:1:32)
% mode (string): type of d prime analysis used for the tonotopy analysis
%   'increasingLvl'/'baseline'
% d_prime_thr (float): threshold used in the tonotopy analysis
%
% output:
% interpolated_best_frequencies(list of int) of the best frequency for each
% electrode
if ~exist('elecs','var') 
    elecs=1:1:32;
end
if ~exist('mode','var') 
    mode='increasingLvl';
end
if ~exist('d_prime_thr','var') 
    d_prime_thr=2;
end

% load tontopy results
% tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_SortedByElec_dprimethr_2_mode_increasingLvl.mat'));
%         tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_SortedByElec_dprimethr_1_mode_baseline.mat'));
tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_dprimethr_1_mode_increasingLvl.mat'));

if ~isempty(tonotopy_files)
    res=load(fullfile(tonotopy_files(1).folder,tonotopy_files(1).name));
    used_frequencies=res.tonotopy_array(:,1);
    found_BE=res.tonotopy_array(:,2);
    used_frequencies(find(isnan(found_BE)))=[];
    found_BE(find(isnan(found_BE)))=[];
    p= polyfit(found_BE,used_frequencies,1);
    interpolated_best_frequencies=polyval(p,elecs);
else
   error(sprintf('no tonotopy recording found for %s to assign best frequencies to electrodes',string(obj.SeriesID)  ))
end        

end