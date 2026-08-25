function    [SR_thresholds]=getSRthresholds(IC,stim_criteria_array,analyze_SR_array,t_start,t_stop)
% getSRthresholds determines the stimulus intensity needed to drive the
% recording to a set of evoked firing rates
% The evoked spike rate of every electrode is calculated over the selected
% stimuli, iso-rate contour lines are drawn through that electrode-by-intensity
% map, and the threshold for a firing rate is the smallest intensity anywhere on
% its contour line, i.e. the intensity at which the most sensitive electrode
% first reaches that rate.
%
% input:
%   IC (icme) IC recording object
%   stim_criteria_array (nx3 array floats) helper to identify wanted stimuli
%       [column in stimlist, min value, max value]. The first row has to
%       describe the intensity, because it forms the x axis the thresholds are
%       read off; further rows fix the remaining stimulus properties
%       exp. [4,0,90;1,4000,4000] a 4 kHz pure tone from 0 to 90 dB SPL
%   analyze_SR_array (1xk double) evoked firing rates in Hz for which the
%       threshold intensity is wanted
%   t_start (double) start of the time window in which the spike rate is
%       extracted, in ms after trigger
%   t_stop (double) end of that time window, in ms after trigger
% output:
%   SR_thresholds (kx1 double) intensity needed to reach each firing rate in
%       analyze_SR_array, in the unit of the stimulus variable named in the
%       first row of stim_criteria_array (e.g. dB SPL, mW, mA). NaN where the
%       recording never reached that firing rate.
%
% assumptions:
%   The recording has to be an intensity series: the analysis is only
%   meaningful if the first row of stim_criteria_array selects a range of
%   intensities rather than a single value.
[all_spike_rate_results] = calculateEvokedSpikeRate(IC,stim_criteria_array,t_start,t_stop);
spike_rate_results=all_spike_rate_results(1,1);
% extract the evoked SR_array
cur_data =spike_rate_results.meanEvokedSpikeRate;
used_stimuli=spike_rate_results.changing_var_values(1:end);
max_Intensity=spike_rate_results.changing_var_values(end);
min_intensity=spike_rate_results.changing_var_values(1);
% Draw iso-rate contour lines through the electrode-by-intensity map. The
% electrode axis is passed as all_electrodes+1 so that the contour of an
% electrode is bounded on both sides.
[all_contourlines,all_thresholds] =getContourLinesForXYdata(cur_data,...
    analyze_SR_array,used_stimuli,IC.SL.all_electrodes+1);
% column 2 holds the intensity at the lowest point of each contour line,
% column 1 the electrode it belongs to
SR_thresholds=all_thresholds(:,2);
end
