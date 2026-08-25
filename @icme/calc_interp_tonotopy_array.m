function [interp_tonotopy_array, tonotopy_slope]=calc_interp_tonotopy_array(IC,dPrimeMode,dPrimeThresh)
% calc_interp_tonotopy_array estimates the characteristic frequency of every
% recording electrode from a tonotopy recording
% calculateTonotopicSlope returns a characteristic frequency only for those
% electrodes at which one could be determined. Because the inferior colliculus
% is tonotopically ordered along the probe, those points fall close to a
% straight line once frequency is expressed in octaves and electrode position
% in millimetres. This function fits that line, removes outliers and reads a
% characteristic frequency off the fit for all 32 electrodes, including the
% ones where none could be measured directly.
%
% input:
%   IC (icme) IC recording object, best from a tonotopy (MX_tones) protocol
%   dPrimeMode (str) mode passed on to calculateTonotopicSlope, either
%       'increasingLvl' or 'baseline'
%   dPrimeThresh (double) d' level at which an electrode counts as responding.
%       Present in the signature but not used by the current implementation,
%       which passes a fixed value of 1 to calculateTonotopicSlope.
% output:
%   interp_tonotopy_array (2x32 double) row 1 the electrode numbers 1 to 32,
%       row 2 the characteristic frequency of each electrode in kHz
%   tonotopy_slope (double) slope of the tonotopic axis in octaves per mm,
%       from the outlier-cleaned fit
%
% assumptions:
%   Electrodes sit 50 um apart, so electrode number times 0.05 is the position
%   along the probe in mm.
%   Frequencies are expressed in octaves above 500 Hz.
%   Outliers are removed in two passes, each dropping points further than two
%   standard deviations of the residuals from the current fit.
 [tonotopy_array, tonotopy_slope,elec_best_freq_array,elec_freq_thr_array] = calculateTonotopicSlope(IC,0,dPrimeMode,1);
% keep only the electrodes for which a characteristic frequency was found
temp_tonotopy_array=tonotopy_array;
        nan_ixs=find(isnan(temp_tonotopy_array(:,2)));
        temp_tonotopy_array(nan_ixs,:)=[];
        % express the tonotopy in the units the slope is defined in:
        % frequency in octaves above 500 Hz, electrode position in mm
        CFs_kHz=temp_tonotopy_array(:,1)/1000;
        CFs_oct=log2(CFs_kHz/.500);
        depth=temp_tonotopy_array(:,2)*0.05;
        % p maps octaves onto mm, so its inverse slope is in octaves per mm
        p= polyfit(CFs_oct,depth,1);
        tonotopy_slope=1/p(1); % oct/mm

        % drop electrodes whose frequency sits far off the tonotopic line,
        % twice, so that outliers uncovered by the first pass are caught too
        for rep=1:2
            y_fit=polyval(p,CFs_oct);
            residuals=depth-y_fit;
            sigma=std(residuals);
            outliers=abs(residuals)>2*sigma;
            if any(outliers)
                CFs_oct=CFs_oct(~outliers);
                depth=depth(~outliers);
                p= polyfit(CFs_oct,depth,1);
                tonotopy_slope=1/p(1); % oct/mm
            end
        end
% Refit in the other direction, mm -> octaves, because the interpolation
% below evaluates frequency as a function of electrode position. This is a
% separate least-squares fit rather than the inverse of the one above, so
% it deliberately does not update tonotopy_slope.
p=polyfit(depth,CFs_oct,1);
CF_interp_oct=polyval(p,[1:1:32]*0.05);
CFs_interp_kHz=500.*2.^(CF_interp_oct);
all_elecs=[1:1:32];
interp_tonotopy_array(1,:)=all_elecs;
interp_tonotopy_array(2,:)=CFs_interp_kHz;
end