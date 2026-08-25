function    [SR_thresholds,SR_thresholds_ix]=getSR_intensity_thresholds(IC,stim_criteria_array,analyze_SR_array,t_start,t_stop)
% getSR_intensity_thresholds determines the presented intensity at which the
% recording first reaches a set of evoked firing rates
% Unlike getSRthresholds, which interpolates iso-rate contour lines, this
% function stays on the intensities that were actually presented: for every
% requested firing rate it takes the maximum evoked rate across electrodes at
% each intensity and returns the first intensity at which that maximum reaches
% the requested rate. It therefore also returns the index of that intensity,
% which lets a caller pick the matching single-trial responses.
%
% input:
%   IC (icme) IC recording object
%   stim_criteria_array (nx3 array floats) helper to identify wanted stimuli
%       [column in stimlist, min value, max value]. The first row has to
%       describe the intensity; further rows fix the remaining stimulus
%       properties
%       exp. [2,0,1;3,100,100;4,0,0] an electrical pulse from 0 to 1 mA at a
%       fixed pulse width
%   analyze_SR_array (1xk double) evoked firing rates in Hz for which the
%       threshold intensity is wanted
%   t_start (double) start of the time window in which the spike rate is
%       extracted, in ms after trigger
%   t_stop (double) end of that time window, in ms after trigger
% output:
%   SR_thresholds (1xk double) presented intensity at which each firing rate is
%       first reached, in the unit of the stimulus variable named in the first
%       row of stim_criteria_array. NaN where the rate was never reached.
%   SR_thresholds_ix (1xk double) index of that intensity in
%       changing_var_values, so the caller can index the response arrays of the
%       same recording. NaN where the rate was never reached.
%
% assumptions:
%   Intensities are assumed to be ordered ascending in changing_var_values, so
%   that the first index above criterion is also the lowest such intensity.
%   Since only presented intensities are returned, the resolution of the
%   threshold is the step size of the intensity series.
[all_spike_rate_results] = calculateEvokedSpikeRate(IC,stim_criteria_array,t_start,t_stop);
spike_rate_results=all_spike_rate_results(1,1);
% extract the evoked SR_array
cur_data =spike_rate_results.meanEvokedSpikeRate;
used_stimuli=spike_rate_results.changing_var_values(1:end);
max_Intensity=spike_rate_results.changing_var_values(end);
min_intensity=spike_rate_results.changing_var_values(1);
% the most responsive electrode at each intensity decides whether the
% recording as a whole has reached a firing rate
cur_data_max=max(cur_data,[],1);

% first presented intensity at or above each requested firing rate
SR_thresholds_ix = nan(size(analyze_SR_array));

for i = 1:numel(analyze_SR_array)
    idx = find(cur_data_max >= analyze_SR_array(i), 1, 'first');
    if ~isempty(idx)
        SR_thresholds_ix(i) = idx;
    end
end
% translate the indices back into intensity values
SR_thresholds = nan(size(SR_thresholds_ix));

valid_idx = ~isnan(SR_thresholds_ix) & ...
            SR_thresholds_ix >= 1 & ...
            SR_thresholds_ix <= numel(used_stimuli);

SR_thresholds(valid_idx) = used_stimuli(SR_thresholds_ix(valid_idx));
end
