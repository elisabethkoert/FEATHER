function [joinedVoltage_filt] = bandfilt(joinedVoltage, high_pass, low_pass, samplingfrequency, filterorder)
 F_nyq = samplingfrequency/2;
 Wn =[high_pass low_pass]/F_nyq;
 [b,a] = butter(filterorder, Wn);
 joinedVoltage_filt = filtfilt(b, a, joinedVoltage);
end

