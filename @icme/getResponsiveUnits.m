function [responsive_units] = getResponsiveUnits(obj,stim_criteria_array,t_start,t_stop)
% icme\getResponsiveUnits finds electrodes/MUs with d' > 1 versus baseline
% This script gets spike rates in the given time window after the trigger and compares them to rates in the
% same time window before the trigger (baseline) to calculate d' values.
% Any electrode that had d'>1 for any presented stimulus counts as
% responsive unit.
% input:
%   obj (icme): IC recording to analyse
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [column in stimlist, min value, max value]
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   t_start,t_stop (float): [ms] time window of investigation after the trigger
% output:
%   responsive_units (1xn array): electrode IDs that had some d' above 1
% elec names 1:1:32;
    if nargin==2
         t_start = 2;
         t_stop = 25;
    end
    
     % load d prime results
    d_prime_results = calculateDprimeMultipleStimVars(obj,'baseline',stim_criteria_array,t_start,t_stop);
    if isempty(d_prime_results)
        responsive_units=[];
    else
        % filter which electrodes /MUA units had any values above d'=1
        responsive_units = obj.SL.all_electrodes(any(d_prime_results{1}.all_Dprime_array>1,2))+1;
    end
end
