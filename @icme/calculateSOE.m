function SoE_results = calculateSOE(obj, mode, stim_criteria_array,t_start, t_stop)
% icme\calculateSOE calculates the spread of excitation for an ICME object
% by looking for the threshold of each d' value and finding the first and
% last electrode that have a d' value above one with this intensity, and
% defining the spread as the area between these electrodes
% input
% 	obj icme 
% 	mode string how to calculate the d' value (increasingLvL or baseline)
% % stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with
%      50-90 dB (increasing lvl sorts by frequency)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
% 	t_start, t_stop float time window [ms] of investigation after the trigger
% output in struct SoE_results 
%     d_prime_array 1xn floats of analyzed d' values (eg. [1,1.5,2,2.5])
%     SoE_elecs 1xn floats number of electrodes between the first and last
%       that reached d'=1 for the threshold intensity for each analysed d'
%     SoE_mm = SoEs_mm; calculated SoE in mm based on the elec num and
%       pitch of 50 um
%     SoE_oct = SoEs_oct; SoE in oct/mm using the tonotopic slope for this
%       animal (or a standard of 4 oct/mm)
%       best_electrode (double) : electrode or mean of mutliple electrodes
%       that had the lowest threshold intensity

warning('using calculateSoE without MSV, try to swith to MSV because this function is getting retired')

    %fill in default function inputs
    if nargin <=4 
        if ~exist('mode') 
            mode='increasingLvl';
        end
        if ~exist('t_start')
             t_start = 0;% time before and after a trigger that is supposed to be investigated
        end
        if ~exist('t_stop')
             t_stop = 50;% time before and after a trigger that is supposed to be investigated
        end
    end
 

    % get dPrime values
    d_prime_results = calculateDprime(obj,mode,stim_criteria_array,t_start,t_stop);
    if strcmp(mode,'increasingLvl')
            thresholds_by_channel=d_prime_results.thresholds_by_channel_Cum;
    elseif strcmp(mode,'baseline')
        thresholds_by_channel=d_prime_results.thresholds_by_channel_base;
    end
    analyzed_d_prime_array = d_prime_results.analyzed_d_prime_array;
    d_prime_1_ix=find(analyzed_d_prime_array==1);
    
    SoEs_elecs=NaN(size(analyzed_d_prime_array));
    for d_prime_ix=1:length(analyzed_d_prime_array)
        thr_value=min(thresholds_by_channel(:,d_prime_ix)',[],'omitnan');
        % find electrodes whose d'=1 threshold is below the theshold
        % value for the given d' value
        d_prime_above_1_at_thr_ixs=find(thresholds_by_channel(:,d_prime_1_ix)<=thr_value);
        % get number of electrodes 
        if ~isempty(d_prime_above_1_at_thr_ixs)
           SoEs_elecs(d_prime_ix)=d_prime_above_1_at_thr_ixs(end)-d_prime_above_1_at_thr_ixs(1) +1;
        end

    end
    % calculate spread of excitation in octaves
    % get tonotopic slope
    % tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_SortedByElec_dprimethr_2_mode_increasingLvl.mat'));
	tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_SortedByElec_dprimethr_1_mode_baseline.mat'));
    if ~isempty(tonotopy_files)
        res=load(fullfile(tonotopy_files.folder,tonotopy_files.name));
        tonotopy_slope=res.tonotopy_slope;
    else
        tonotopy_slope= 4.5; % ToDo get actual values for each experiment
    end
    SoEs_mm=SoEs_elecs*0.05; %50 µm per electrode
    SoEs_oct=SoEs_mm*tonotopy_slope;

    % get best_electrode
    [value,ix]=min(min(thresholds_by_channel,[],2));
    all_elecs=[1:1:32];
    best_elecs=mean(all_elecs(min(thresholds_by_channel,[],2)==value) );
    
    % save results in output structure
    SoE_results.d_prime_array= analyzed_d_prime_array;
    SoE_results.SoE_elecs = SoEs_elecs;
    SoE_results.SoE_mm = SoEs_mm;
    SoE_results.SoE_oct = SoEs_oct;
    SoE_results.best_electrode=best_elecs;

        
    
end
        