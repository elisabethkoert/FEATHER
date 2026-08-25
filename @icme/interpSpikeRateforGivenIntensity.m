function [spike_rate_array_interp] = interpSpikeRateforGivenIntensity(IC,stim_criteria_array,t_start,t_stop,intensities)
% interpSpikeRateforGivenIntensity reads the evoked spike rate of every
% electrode at intensities that were not themselves presented
% The evoked spike rate is calculated over the presented intensity series and
% then linearly interpolated onto the requested intensities. This makes
% recordings comparable at a matched activity level: the caller first finds the
% intensity that drives each recording to a given evoked firing rate (see
% getSRthresholds) and then asks here for the response profile at exactly that
% intensity.
%
% input:
%   IC (icme) IC recording object
%   stim_criteria_array (nx3 array floats) helper to identify wanted stimuli
%       [column in stimlist, min value, max value], first row the intensity
%   t_start (double) start of the time window in which the spike rate is
%       extracted, in ms after trigger
%   t_stop (double) end of that time window, in ms after trigger
%   intensities (1xk double) intensities to interpolate onto, in the unit of
%       the stimulus variable named in the first row of stim_criteria_array
% output:
%   spike_rate_array_interp (32xk double) evoked spike rate of each electrode
%       at each requested intensity, in Hz
%
% assumptions:
%   The recording is assumed to have 32 electrodes.
%   Interpolation is linear and not extrapolated, so requested intensities
%   outside the presented range come back as NaN, as do NaN entries in
%   intensities. That is how firing rates a recording never reached stay
%   marked as missing.
[all_spike_rate_results] = calculateEvokedSpikeRate(IC,stim_criteria_array,t_start,t_stop);
cur_SpikeRate_array=NaN(32,numel(all_spike_rate_results(1,1).changing_var_values));
cur_SpikeRate_array(:,1:end)=all_spike_rate_results(1,1).meanEvokedSpikeRate;

is_dprime_ix=repmat(all_spike_rate_results(1,1).changing_var_values(1:end),1,size(cur_SpikeRate_array,1));
% interp1 works along the first dimension, so the array is transposed for
% the interpolation and transposed back afterwards
spike_rate_array_interp=interp1(all_spike_rate_results(1,1).changing_var_values(1:end),cur_SpikeRate_array',intensities);
spike_rate_array_interp=spike_rate_array_interp';
end



