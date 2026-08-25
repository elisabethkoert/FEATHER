function all_SoE_results = calculateSOEContourlinesMainSpectralPeak(IC, mode, stim_criteria_array, t_start, t_stop,SR_comp_values)
% icme/calculateSOEContourlinesMainSpectralPeak calculates the threshold, best electrode and SoE based on d' contourlines
% This function firsts calculates the cumulative d' array (or
% baseline depending on the mode) for all electrodes and stimuli that fall
% into the stim_criteria_array. As an additional step the location of any
% double peaks is determined and the SoE is measured for the main spectral
% peak only.
% Then it calculates the contourlines in this
% array. Closed contourlines are removed, the ones on the electrode edges are closed to the highest intensity.
% The threshold for each d' level is determined as the contourline point with the smallest x-value/intensity,
% the SoE is determined by measuring the width of the d' isocontourline at this threshold value.
% input
% 	IC icme 
% 	mode string how to calculate the d' value (increasingLvL or baseline)
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with
%      50-90 dB (increasing lvl sorts by frequency)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
% 	t_start (double) & t_stop (double) : time window [ms] after trigger that is used for the analysis
%   SR_comp_values in case of mode evoked SR, Spike Rate values in Hz that
%   are used as reference lvels to calculate SoE
% output in struct all_SoE_result, for each option of fixed varibale this
%   contains:
%       analysis_type (string): 'contourlines' to keep track of the used function
%       fixed_var_header (string): stimulus variable that was fixed eg.
%           frequency
%       fixed_var_value (double): value of the fixed stimulus
%       changing_var_header (string): variable that was changing intensity
%           during the analysis (eg. SPL, laserPower)
%       changing_var_values (1xm double) eg. used intensities during
%           stimulation
%       d_prime_array (1xn double) list of analyzed d' levels (eg. [1,1.5,2,2.5])
%       thresholds (1xn doubles) minimal changing_variable_value/intensity in the d'level
%           contourlines
%       best_electrode (1xn) electrode for minimal intensity at each d'
%           level (y value of contourline at threshold)
%       SoE_elecs (1xn double) number of electrodes within the d'=1
%           contourline at threshold intensity for that d'level 
%       SoE_mm (1xn double) calculated SoE in mm based on the spread in
%           electrodes and the array pitch of 50 um
%       SoE_oct (1xn double) the same spread expressed in octaves, obtained
%           by multiplying SoE_mm with the tonotopic slope of this animal
%           (or a standard slope of 4.5 oct/mm when it is unknown)    


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
     if strcmp(mode,'evokedSR')
        dPrime_mode='baseline';
    else
       dPrime_mode=mode;
    end
    % for mode SR comparison values have to entered 
    if strcmp(mode,'evokedSR') & ~exist('SR_comp_values')
        error('To compare across SR, values of comparison have to be entered');
    end
    if strcmp(mode,'evokedSR') & isempty('SR_comp_values')
        error('To compare across SR, values of comparison have to be entered');
    end
     % load d prime results
    all_d_prime_results = calculateDprimeMultipleStimVars(IC,dPrime_mode,stim_criteria_array, t_start,t_stop);
    try [all_peak_results]=calc_dPrime_over_separate_peak(IC,stim_criteria_array,t_start,t_stop);
    catch
        return
    end
    if numel(all_peak_results)==1
        low_peak_ix=1;
    else
    LED_BE_all=[all_peak_results(:).centroid_BE];
    thresholds=vertcat(all_peak_results(:).thresholds); % thresholds in every peak
    [min_thresh]=min(thresholds(:,1));
    low_peak_ix=find(thresholds(:,1)==min_thresh); % find the peak with the lowest threshold
    if numel(low_peak_ix)>1
        [~,is_base]=max([all_peak_results(low_peak_ix).centroid_BE]);
        low_peak_ix=low_peak_ix(is_base);
    end
    end
    d_Prime_array_main_peak=all_peak_results(low_peak_ix).dPrime_array;
    meanEvokedSpikeRate_main_peak=all_peak_results(low_peak_ix).SR_array;
    edge_low=min(all_peak_results(low_peak_ix).electrodes);
    edge_high=max(all_peak_results(low_peak_ix).electrodes);
    all_SoE_results ={};
    for stim_ix=1:length(all_d_prime_results)
        d_prime_results=all_d_prime_results{stim_ix};
        analyzed_d_prime_array = d_prime_results.analyzed_d_prime_array;
        d_prime_1_ix=find(analyzed_d_prime_array==1);
          if strcmp(mode,'increasingLvl')
            cur_dPrime_data= d_Prime_array_main_peak;
            used_stimuli=d_prime_results.changing_var_values(1:end);
            max_Intensity=d_prime_results.changing_var_values(end);
            min_intensity=d_prime_results.changing_var_values(2);
            % check if the first collumn already goes above d'=1 in any
            % electrode forthis will cause issues in closing the contourlines
            if any(cur_dPrime_data(:,1)>1)
                % if yes add a collumn of zeros in front
                cur_dPrime_data=[zeros(size(cur_dPrime_data,1),1),cur_dPrime_data];
                used_stimuli=[0;used_stimuli];
            end
        elseif strcmp(mode,'baseline')
            cur_dPrime_data =d_Prime_array_main_peak;
            used_stimuli=d_prime_results.changing_var_values;
            max_Intensity=d_prime_results.changing_var_values(end);
            min_intensity=d_prime_results.changing_var_values(1);
        elseif strcmp(mode,'evokedSR')
            cur_data =meanEvokedSpikeRate_main_peak;
            cur_dPrime_data=d_Prime_array_main_peak;
            used_stimuli=d_prime_results.changing_var_values;
            max_Intensity=d_prime_results.changing_var_values(end);
            min_intensity=d_prime_results.changing_var_values(1);
        end
        
        %  % get contourlines and threhsolds
        if strcmp(mode,'baseline') || strcmp(mode,'increasingLvl')
            analyzed_activity_array=analyzed_d_prime_array;
            [all_contourlines,all_thresholds] =getContourLinesForXYdata(cur_dPrime_data,...
                analyzed_activity_array,used_stimuli,all_peak_results(low_peak_ix).electrodes);
             dp1_contourlines=all_contourlines{1};
        elseif strcmp(mode,'evokedSR')
             [all__dPrime_contourlines,all__dPrime_thresholds] =getContourLinesForXYdata(cur_dPrime_data,...
                analyzed_d_prime_array,used_stimuli,all_peak_results(low_peak_ix).electrodes);
              dp1_contourlines=all__dPrime_contourlines{1};
              analyzed_activity_array=SR_comp_values;
              [all_contourlines,all_thresholds] =getContourLinesForXYdata(cur_data,...
                analyzed_activity_array,used_stimuli,all_peak_results(low_peak_ix).electrodes);
        end

       
        % find SoE as spread of d'=1 contourline for each threshold
        SoEs_elecs=NaN(size(analyzed_activity_array));
        for d_prime_ix=1:length(analyzed_activity_array)
            Cur_contourlines=all_contourlines{d_prime_ix};
            if ~isempty(Cur_contourlines)
                threshold_mW=all_thresholds(d_prime_ix,2);
                 % for SoE get intersections of threshold with any other contour line at d'=1
                intersections = [];
                for dp1_contour_ix=1:length(dp1_contourlines)
                    xs=dp1_contourlines{dp1_contour_ix}.contour_points(1,:);
                    ys=dp1_contourlines{dp1_contour_ix}.contour_points(2,:);
                    for i = 1:length(xs) - 1
                        x1 = xs(i);
                        x2 = xs(i + 1);
                        y1 = ys(i);
                        y2 = ys(i + 1);
                        if x1 == threshold_mW 
                           intersections = [intersections; x1, y1];
                        elseif x2 == threshold_mW
                            intersections = [intersections; x2, y2];
                        elseif (x1 - threshold_mW) * (x2 - threshold_mW) < 0  % check if threshold_mW is between x1 and x2
                            intersection_x = threshold_mW ;
                            intersection_y = y1+(y2-y1)*(threshold_mW-x1)/(x2 - x1);
                            intersections = [intersections; intersection_x, intersection_y];
                        end
                    end
                    %check if the contour touches the edges / contains the
                    %electrode 0 or 32
                    if any(ceil(ys)==edge_high) && any(xs(find(ceil(ys)==edge_high))<=threshold_mW)
                       intersections = [intersections; threshold_mW, edge_high];
                    elseif any(ceil(ys)==edge_low+1) && any(xs(find(ceil(ys)==edge_low+1))<=threshold_mW )
                       intersections = [intersections; threshold_mW, edge_low];
                    end


                end
                covered_electrodes=unique(intersections(:,2));
                if ~isempty(covered_electrodes)
                    if length(covered_electrodes)==1
                        SoEs_elecs(d_prime_ix)=1;
                    else
%                         SoEs_elecs(d_prime_ix)=ceil(max(covered_electrodes))-floor(min(covered_electrodes));
                        SoEs_elecs(d_prime_ix)=max(covered_electrodes)-min(covered_electrodes); % this allows for electrode interpolation as well
                    end
                end
                if floor(min(covered_electrodes))==edge_low || ceil(max(covered_electrodes))==edge_high
                    SoEs_elecs(d_prime_ix)=NaN;
                end
            end
        end
        % make sure that the limis of the array are not reached here to not
        % underestimate spread 
        
 

        % calculate spread of excitation in octaves
        % get tonotopic slope that was extracted at d'2 level after sorting
        % by electrode
         tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_dprimethr_1_mode_increasingLvl.mat'));
        % tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_SortedByElec_dprimethr_2_mode_increasingLvl.mat'));
%         tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_SortedByElec_dprimethr_1_mode_baseline.mat'));
        if ~isempty(tonotopy_files)
            res=load(fullfile(tonotopy_files(1).folder,tonotopy_files(1).name));
            tonotopy_slope=res.tonotopy_slope;
        else
            tonotopy_slope= 4.5; 
        end        
        SoEs_mm=SoEs_elecs*0.05; %50 µm per electrode
        SoEs_oct=SoEs_mm*tonotopy_slope;

        
        % get best_electrode based only on dPrimematrix
        best_elecs=all_thresholds(:,3);
        intensity_thresholds=all_thresholds(:,2);
        
        % save results in output structure
        SoE_results.analysisType='Contourlines';
        SoE_results.fixed_var_header=d_prime_results.fixed_var_header;
        SoE_results.fixed_var_value =d_prime_results.fixed_var_value; % what was the fixed variable of the stimulus for this analysis
        SoE_results.changing_var_header =d_prime_results.changing_var_header; % what was the fixed variable of the stimulus for this analysis
        SoE_results.changing_var_values =d_prime_results.changing_var_values; % what was the fixed variable of the stimulus for this analysis

        SoE_results.d_prime_array= analyzed_d_prime_array;
        SoE_results.thresholds=intensity_thresholds;
        SoE_results.best_electrode=best_elecs;
        SoE_results.SoE_elecs = SoEs_elecs;
        SoE_results.SoE_mm = SoEs_mm;
        SoE_results.SoE_oct = SoEs_oct;

        all_SoE_results{stim_ix}=SoE_results;
    end
    

end
