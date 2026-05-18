function [all_d_prime_results] = calculateDprimeMultipleStimVars(obj ,mode,stim_criteria_array,t_start,t_stop)
% icme\calculateDprimeMultipleStimVars calculates d' values after separating stimuli into subgroups (e.g., frequencies for tonotopy recordings)
% dPrime calculation happens by comparing spike rate distributions either between consecutive stimuli (mode=increasingLvl) or with a
% baseline (mode=baseline) taken from timewindow before trigger, same length as stimulus but max 50 ms 
%
% input:
%   obj (icme) IC recording object, 
%   mode (str) either increasingLvl or baseline
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [column in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%       the fixed stimulus will be the property described in the second row     
%        exp. [4,50,90;1,500,32000] analyses the d' value for stimuli of
%       increasing SPL (50-90 dB) and analyses their d' value separated by
%       frequencies
%   t_start (double) start of timewindow in which to extract the spike rate
%   t_stop (double) stop of time window in which to analyze the spike rate
% output in d_prime_results object:
%   mode (str) either increasingLvl or baseline
%   t_start (double) start of timewindow in which to extract the spike rate
%   t_stop (double) stop of time window in which to analyze the spike rate
%   intensities=sortLvl; % changing values (eg intensity in mW) that were compared to each other in the d' analysis
%   fixed_var_header (string): stimulus variable that was fixed eg.
%           frequency
%   fixed_var_value (double): value of the fixed stimulus
%   changing_var_header (string): variable that was changing intensity
%           during the analysis (eg. SPL, laserPower)
%  changing_var_values (1xm double) eg. used intensities during
%           stimulation
%   all_Dprime_array (32 x m for baseline, 32 x (m-1) for increasingLvl):
%       dPrime values for each stimulus and electrode
%   all_Dprime_cumsum (32 x m for baseline, 32 x (m-1) for increasingLvl):
%       cumulative sum of all_Dprime_array for each electrode
%    analysed_d_prime_array (1x k) % investigated d' values for
%       threshold determination
%   thresholds_by_channel_Cum (32xk) containing the threshold value of the
%       changing variable that is needed to reach the d' value in the cum
%       d' sum
%   thresholds_by_channel_base; (32xk) containing the threshold value of the
%       changing variable that is needed to reach the d' value in the
%       all_dPrime_array
%   thresholds(1xk) minimum of the  thresholds_by_channel_Cum to get the
%       smallest intensity eliciting a response with a d' value from the 
%       analysed_d_prime_array at any electrode
    
    

       


    if nargin <=2 & ~exist('t_start') & ~exist('t_stop')
        t_start = 0;% time before and after a trigger that is supposed to be investigated
        t_stop = 150; % default 50 ms after trigger
    end
    
    % % try if the calibrated Stimlist exists
    if isfield(obj.C,'stimlistCal')
        OBJ_stimlist=obj.C.stimlistCal;
    else
        OBJ_stimlist=obj.Stim.stimlist;
    end
    % the thresholds will be calculated for these d' values
    analyzed_d_primes=1:0.5:10;

    % figure out which stimuli are investigated
    stim_ID=1:1:length(OBJ_stimlist(:,1));
    for jj=1:size(stim_criteria_array,1)
        stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
        stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
        stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
        stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
    end

    fixedStimStimList_ix=stim_criteria_array(2,1);%freq
    changing_var_ix=stim_criteria_array(1,1);%SPL dB
    
    


    fixedStimList=unique(OBJ_stimlist(stim_ID,fixedStimStimList_ix));
    num_StimVars=length(fixedStimList);
    fixed_var_header =obj.Stim.stimheader{fixedStimStimList_ix};
    changing_var_header =obj.Stim.stimheader{changing_var_ix};
    
    
    % get the unsorted spike rates for all stimuli
    [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(obj,t_start,t_stop); % ToDo figure out how to get cache on here
    if strcmp(mode,'baseline')
            %calculate baseline as time window before trigger (max 50 ms)
            if t_stop>=50
                t_stop=50;
            end
            [meanSpikeRatesBaseline, spikeRateAllRepsBaseline]  = calculateSpikeRate(obj,-t_stop,-t_start); 
    end
    
    
     % initialize variables
    all_electrodes = obj.SL.all_electrodes; 
    all_d_prime_results={};
    for fixedStim_ix=1:num_StimVars
        % determined the current fixed stimulus for which the d'
        % analysis is performed (eg. freq=500Hz) for tonotopy
        cur_fixed_var=fixedStimList(fixedStim_ix);
        cur_stim_ixs=stim_ID(ismember(stim_ID, find(OBJ_stimlist(:,fixedStimStimList_ix)==cur_fixed_var)));
        % check if you have any double presentations of stimuli
        changing_var_all=OBJ_stimlist(cur_stim_ixs, changing_var_ix); % tonotopy this is dB
        [~, indices_unique, ~] = unique(changing_var_all);
        cur_stim_ixs=cur_stim_ixs(indices_unique);
        % cut down the arrays to only wanted stimuli
        cur_stimlist=OBJ_stimlist(cur_stim_ixs,:);
        cur_meanSpikeRates=meanSpikeRates(:,cur_stim_ixs);
        cur_spikeRateAllReps=spikeRateAllReps(:,cur_stim_ixs,:);
        if strcmp(mode,'baseline')
            cur_spikeRateAllRepsBaseline=spikeRateAllRepsBaseline(:,cur_stim_ixs,:);
        end
    
        % find the cahnging variable that will form the x-axis of the
        % comparison plot
        changing_var=cur_stimlist(:, changing_var_ix); % tonotopy this is dB
    
        % either sort if the changing variable needs to be in
        % increasing level order leave in presented order for baseline
        % comparison
        if strcmp(mode,'increasingLvl')
            % since we are calculating based on the spike rate in the
            % previous level we need to sort the levels 
            [stimuli, iStimuli] = sort(unique(changing_var,'stable'));
            nComp= size(cur_meanSpikeRates,2)-1; % numebr of comparisons needed for d' analysis
        elseif strcmp(mode,'baseline')
            stimuli=unique(changing_var,'stable');
            iStimuli =1:1:length(stimuli);
            %calculate baseline as time window before trigger 
            nComp= size(cur_meanSpikeRates,2); % numebr of comparisons needed for d' analysis per electrode
        else
            disp('unknown mode')
            d_prime_results={};
            return
        end
    
        %% start caclulating the dPrime array
        all_Dprime_array = zeros(size(cur_meanSpikeRates,1), nComp); % 32 x numStimuli for all d' at all electrodes
        % calculate d' for each electrode
        for yy = 1:length(all_electrodes)
            StimResp =  cur_spikeRateAllReps(yy,:,:); % we need to look at the spikerates in each rep of the same stimuli to get a distribution
            if strcmp(mode,'baseline')
                    StimRespBaseline =  cur_spikeRateAllRepsBaseline(yy,:,:);
            end
            DprimeMat = zeros(nComp,1); 
            ROC = cell(nComp,1); 
            AUCMat = zeros(nComp,2);
            % ROC analysis
            for curStimComp = 1:nComp
                if strcmp(mode,'increasingLvl')
                    N = StimResp(1,iStimuli(curStimComp),:); 
                    N = N(1,:);
                    P = StimResp(1,iStimuli(curStimComp+1),:);
                    P = P(1,:);
                elseif strcmp(mode,'baseline')
                    N = StimRespBaseline(1,iStimuli(curStimComp),:);
                    N = N(1,:);
                    P = StimResp(1,iStimuli(curStimComp),:); 
                    P = P(1,:);
                end
                [ROCmat, AUC, Dprime, SE] = ROCAna_03(obj, N, P, 0);
                DprimeMat(curStimComp,1) = Dprime;
                AUCMat(curStimComp,1:2) = [AUC, SE];
                ROC{curStimComp,1} = ROCmat;
            end
            all_Dprime_array(yy, :) = DprimeMat';
        end
        all_Dprimes_cumsum = cumsum(all_Dprime_array, 2);
    
    
        % analyse threshold intensities for specific d' values
        if strcmp(mode,'increasingLvl')
            d_prime_intensities=stimuli(2:end);
        elseif strcmp(mode,'baseline')
            d_prime_intensities=stimuli;
            % ToDo decide if in basleine case we want to get the thresholds
            % in the cum d prime or just in d' array
        end

        thresholds_by_channel_Cum = nan(length(analyzed_d_primes), length(all_electrodes))';
        for d_prime_i=1:length(analyzed_d_primes)
                % find the threshold value
                cur_d_prime=analyzed_d_primes(d_prime_i);
                for elec_i=1:length(all_electrodes)
                    indices=find(all_Dprimes_cumsum(elec_i,:)>cur_d_prime);
                    if ~isempty(indices)
                        thresholds_by_channel_Cum(elec_i,d_prime_i)=min(d_prime_intensities(indices));
                    end
                end  
        end    

        thresholds_by_channel_baseline = nan(length(analyzed_d_primes), length(all_electrodes))';
        for d_prime_i=1:length(analyzed_d_primes)
                % find the threshold value
                cur_d_prime=analyzed_d_primes(d_prime_i);
                for elec_i=1:length(all_electrodes)
                    indices=find(all_Dprime_array(elec_i,:)>cur_d_prime);
                    if ~isempty(indices)
                        thresholds_by_channel_baseline(elec_i,d_prime_i)=min(d_prime_intensities(indices));
                    end
                end  
        end    
    
        

        d_prime_results.t_start=t_start;
        d_prime_results.t_stop = t_stop;
        d_prime_results.mode = mode;
        d_prime_results.fixed_var_header = fixed_var_header;
        d_prime_results.fixed_var_value = cur_fixed_var;
        d_prime_results.changing_var_header = changing_var_header; % is the Unit/description for the stimuli values
        d_prime_results.changing_var_values=stimuli; % changing values (eg intensity in mW) that were compared to each other in the d' analysis
        d_prime_results.all_Dprime_cumsum=all_Dprimes_cumsum;%32 x length(stimuli)
        d_prime_results.all_Dprime_array=all_Dprime_array; % 32xlength(stimuli)
        d_prime_results.analyzed_d_prime_array=analyzed_d_primes; % investigated d' values for threshholding
        d_prime_results.thresholds_by_channel_Cum=thresholds_by_channel_Cum; % n__analyzed d_prime_values x n_elecs containing the threshold values for the given d'
        d_prime_results.thresholds_by_channel_base=thresholds_by_channel_baseline; % n__analyzed d_prime_values x n_elecs containing the threshold values for the given d' in the comparison with Baseline
        d_prime_results.thresholds = min(thresholds_by_channel_Cum,[],'omitnan'); % 1x n_analzed d'values threshold for each analyzed d'
        
        % save in big structure
        all_d_prime_results{fixedStim_ix}=d_prime_results;
    
    
    
    end

end



            
        
