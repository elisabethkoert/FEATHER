function SNR = snrSN(peaks, rowsSpikes, SNRHalfWindowPre, SNRHalfWindowPost, singleTrace, plotting)
    %                
    % This function calculates signal-to-noise ratio (SNR) of a trace from juxtacellular recording from a neuron.
    % Signal and noise are defined as described here:
    % Stratton, P., Cheung, A., Wiles, J., Kiyatkin, E., Sah, P., & Windels, F. (2012). 
    % Action potential waveform variability limits multi-unit separation in freely behaving rats. 
    % PloS one, 7(6), e38482.
    % SNR is then converted to decibels (dB) using formula for voltage SNR
    % SNR = 20 x log10 (rms(signal)/rms(noise))
    %
    % Inputs:
    % peaks - (double array) matrix containing all the info about the peaks
    % in that trace from the findpeaks function (more details in the SpikeDetection_kMeans function description)
    % rowsSpikes - (double array) which rows in the peaks matrix correspond to
    % spikes
    % SNRHalfWindowPre - (float) how much time before the peak should be
    % included in s
    % SNRHalfWindowPost - (flaot) how much time after the peak should be
    % included in s
    % singleTrace - (double array) an array of numbers representing a single recorded
    % trace in volts
    % plot - (boolean) if 1 then plot separately signal and noise, if 0
    % then no plots are produced
    %
    % Outputs:
    % SNR - (double) calculated SNR
    % if plot=1 then the function also returns a figure with 3 subplots: a
    % full trace, only signal, only noise
    
    % Get indeces of the parts of the trace making up spikes
    spikesPreIdxAll = peaks(rowsSpikes,3)-SNRHalfWindowPre;
    spikesPostIdxAll = peaks(rowsSpikes,3)+SNRHalfWindowPost;
    % Exclude incomplete spikes
    spikesPreIdx = spikesPreIdxAll(spikesPreIdxAll > 0 & spikesPostIdxAll <= length(singleTrace));
    spikesPostIdx = spikesPostIdxAll(spikesPreIdxAll > 0 & spikesPostIdxAll <= length(singleTrace));
    spikesIdx = [];
    for idx=1:length(spikesPreIdx)
        spikesIdx = [spikesIdx, spikesPreIdx(idx):spikesPostIdx(idx)];
    end
    % Turn indexes to a logical
    spikesIdxLogic = ismember(1:length(singleTrace),spikesIdx);
    spikesTrace = singleTrace(spikesIdxLogic);
    %noiseTrace = singleTrace(setdiff(1:end,spikesIdx))
    noiseTrace = singleTrace(~spikesIdxLogic);
    % Calculate SNR
    SNR = 20*log10(rms(spikesTrace(~isnan(spikesTrace)))/rms(noiseTrace(~isnan(noiseTrace))));
    
    % Uncomment below for alternative SNR calculation
    % Exact method from Stratton et al., 2012 (same as what is used above, just without converting to dB)
    % SNR = rms(spikesTrace(~isnan(spikesTrace)))/rms(noiseTrace(~isnan(noiseTrace)));
    % Method from Typlt et al., 2012
    % SNR = mean(peaks(rowsSpikes,4))/std(noiseTrace(~isnan(noiseTrace)));
    
    % Plotting
    if plotting
        figure;
        % Full trace
        subplot(1,3,1)
        plot(singleTrace)
        title('Full trace')
        xlabel('Time')
        ylabel('Recorded potential (V)')
        % Signal
        subplot(1,3,2)
        plot(spikesTrace)
        title('Signal')
        xlabel('Selected time')
        ylabel('Recorded potential (V)')
        % Noise
        subplot(1,3,3)
        plot(noiseTrace)
        title('Noise')
        xlabel('Selected time')
        ylabel('Recorded potential (V)')
    end
end