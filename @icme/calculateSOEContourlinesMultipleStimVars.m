function all_SoE_results = calculateSOEContourlinesMultipleStimVars(obj, mode, stim_criteria_array, t_start, t_stop,isocontourline_levels)
% icme/calculateSOEcontourlinesMultipleStimVars calculates the spread of excitation by measuring the width of isocontourlines in a electrodes-vs-stimulus heatmap for specific stimulus intensities
% This function firsts calculates a 2D array for each electrode and stimulus
% condition (descriped by stim_criteria_array) that contains 
% (depending on the input mode) the baseline or cumulative d' or the evoked spike rate.
% Then it calculates the contourlines in this array at specific d' or SR values. 
% Contourlines on the electrode edges are closed to the highest applied intensity.
% For each contourline_level, the stimulus  intensity threshold is
% determined as the contourline point with the smallest x-value/intensity.
% Then the SoE is determined by measuring the width of the d'=1 isocontourline at
% this threshold value in electrodes. The SoE in mm is calulated by
% multiplying with the standard electrode pitch of 50 µm, the SoE in
% octaves is calculated by multiplying the mm values with the specific
% tonotopic slope for this animal.
% Examples: 
% 'mode'='baseline', SoE_elecs at isocontourline_level=2 is the
%   width of the d' baseline=1 isocontourline at the lowest intensity where
%   d' baseline=2 is reached for any electrode.  
% 'mode'='increasingLvl', SoE_elecs at isocontourline_level=2 is the
%   width of the d' increasingLvl=1 isocontourline at the lowest intensity where
%   d' increasingLvl=2 is reached for any electrode.  
% 'mode'='evokedSR', SoE_elecs at isocontourline_level=200 [Hz] is the
%   width of the d' baseline=1 isocontourline at the lowest intensity where
%   evokedSR=200 [Hz] is reached for any electrode.  
% input
% 	obj icme 
% 	mode (string): describes what to use to draw the isocontour lines
%       (dPrime modes: 'increasingLvL or baseline or SR modes: evokedSR)
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with
%      50-90 dB (increasing lvl sorts by frequency)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
% 	t_start (double) & t_stop (double) : time window [ms] after trigger that is used for the analysis
%   isocontourline_levels (1xn double, optional): levels at which to read
%       out the isocontourlines for the SoE
% output:
% struct all_SoE_result, contains for each option of fixed varibale (eg. frequency in acoustic measurements)
%   contains:
%       analysis_type (string): 'contourlines' to keep track of the used function
%       mode (string): input mode of 
%       fixed_var_header (string): stimulus variable that was fixed eg.
%           frequency
%       fixed_var_value (double): value of the fixed stimulus
%       changing_var_header (string): variable that was changing intensity
%           during the analysis (eg. SPL, laserPower)
%       changing_var_values (1xm double) eg. used intensities during
%           stimulation
%       isocontourline_levels (1xn double) list of analyzed values for the isocontourlines (eg. d'=[1,1.5,2,2.5])
%       thresholds (1xn doubles) minimal changing_variable_value/intensity in the d'level
%           contourlines
%       best_electrode (1xn) electrode for minimal intensity at each d'
%           level (y value of contourline at threshold)
%       SoE_elecs (1xn double) number of electrodes within the d'=1
%           contourline at threshold intensity for that d'level 
%       SoE_mm (1xn double) calculated SoE in mm based on the spread in
%           electrodes and the array pitch of 50 um
%       SoE_oct (1xn double) SoE in oct/mm using the tonotopic slope for this
%           animal (or a standard of 4.5 oct/mm)    


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
    % for mode Sr comparison values have to entered 
    if ~exist('isocontourline_levels')
        if strcmp(mode,'evokedSR') 
            isocontourline_levels=[50:25:500];
        else
            isocontourline_levels=[1:0.5:10];
        end
    end
 
     % load d prime results
    all_d_prime_results = calculateDprimeMultipleStimVars(obj,dPrime_mode,stim_criteria_array, t_start,t_stop);
    % load spike rate results
    [all_evoked_spike_rate] = calculateEvokedSpikeRate(obj,stim_criteria_array, t_start,t_stop );
    if ~numel(all_d_prime_results)==numel(all_evoked_spike_rate)
        error('Evoked spike rate and dPrime results do not have the same length')
    end
    all_SoE_results ={};
    for stim_ix=1:length(all_d_prime_results)
        d_prime_results=all_d_prime_results{stim_ix};
        meanEvokedSpikeRate=all_evoked_spike_rate(stim_ix).meanEvokedSpikeRate;
        if strcmp(mode,'increasingLvl')
            cur_dPrime_data =d_prime_results.all_Dprime_cumsum;
            used_stimuli=d_prime_results.changing_var_values(2:end);
            % check if the first collumn already goes above d'=1 in any
            % electrode forthis will cause issues in closing the contourlines
            if any(cur_dPrime_data(:,1)>1)
                % if yes add a collumn of zeros in front
                cur_dPrime_data=[zeros(size(cur_dPrime_data,1),1),cur_dPrime_data];
                used_stimuli=[0;used_stimuli];
            end
        elseif strcmp(mode,'baseline')
            cur_dPrime_data =d_prime_results.all_Dprime_array;
            used_stimuli=d_prime_results.changing_var_values;
        elseif strcmp(mode,'evokedSR')
            cur_SR_data =meanEvokedSpikeRate;
            cur_dPrime_data=d_prime_results.all_Dprime_array;
            used_stimuli=d_prime_results.changing_var_values;
        end
       
        
        % get contourlines and threhsolds
        if strcmp(mode,'baseline') || strcmp(mode,'increasingLvl')
            [all_contourlines,all_thresholds] =getContourLinesForXYdata(cur_dPrime_data,...
                isocontourline_levels,used_stimuli,obj.SL.all_electrodes+1);
             dp1_contourlines=all_contourlines{1};
        elseif strcmp(mode,'evokedSR')
             [all__dPrime_contourlines,all__dPrime_thresholds] =getContourLinesForXYdata(cur_dPrime_data,...
                [1,2],used_stimuli,obj.SL.all_electrodes+1); % check only for the d' levels 1 and 2 because 1 is the important one but single readout value gives errors
              dp1_contourlines=all__dPrime_contourlines{1};
              [all_contourlines,all_thresholds] =getContourLinesForXYdata(cur_SR_data,...
                isocontourline_levels,used_stimuli,obj.SL.all_electrodes+1);
        end
       
        % find SoE as spread of d'=1 contourline for each threshold
        SoEs_elecs=NaN(size(isocontourline_levels));
        for level_ix=1:length(isocontourline_levels)
            Cur_contourlines=all_contourlines{level_ix};
            if ~isempty(Cur_contourlines)
                threshold_mW=all_thresholds(level_ix,2);
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
                    if any(ceil(ys)==31) && any(xs(find(ceil(ys)==31))<=threshold_mW)
                       intersections = [intersections; threshold_mW, 32];
                    elseif any(ceil(ys)==1) && any(xs(find(ceil(ys)==1))<=threshold_mW )
                       intersections = [intersections; threshold_mW, 1];
                    end


                end
                if ~isempty(intersections)
                    covered_electrodes=unique(intersections(:,2));
                    if ~isempty(covered_electrodes)
                        if length(covered_electrodes)==1
                            SoEs_elecs(level_ix)=1;
                        else
    %                         SoEs_elecs(activity_ix)=ceil(max(covered_electrodes))-floor(min(covered_electrodes));
                            SoEs_elecs(level_ix)=max(covered_electrodes)-min(covered_electrodes); % this allows for electrode interpolation as well
                        end
                end
                else
                    SoEs_elecs(level_ix)=NaN;
                end
            end
        end



     
% 
%        % PLOT RESULTS; UNCOMMENT IF NEEDED
%        n_electrodes=length(obj.SL.all_electrodes);
%        if strcmp(mode,'evokedSR')
%             cur_data=cur_SR_data; 
%             cmax_val=ceil(max(max(cur_data))/50)*50;
%             cmap=parula(2*cmax_val/50);
%             c_lim=[0, cmax_val];
% 
%         else
%             cur_data= cur_dPrime_data; 
%             cmap=parula(2*ceil(max(max(cur_data))));
%             c_lim=[0, ceil(max(max(cur_data)))];
%         end
%         f1 = figure('color', [1 1 1], 'units','normalized','position',[.1 .1 0.35 .7]); 
%         hold on; 
%         title(mode)
%         pcolor(used_stimuli,[obj.SL.all_electrodes+1], cur_data); 
%         ylim([1 n_electrodes]); 
%         xlim([used_stimuli(1), used_stimuli(end)])
%         c = colorbar; 
%         xlabel('intensity [mW]')
%         ylabel('electrode')
%         colormap(cmap);
%         clim(c_lim)
%         % plot d'=1 isocontourline used for SoE readout
%         for kk=1:length(dp1_contourlines)
%             points = dp1_contourlines{kk}.contour_points;
%             plot(points(1,:), points(2,:), 'r-', 'LineWidth', 2);
%         end
%         % plot investigated levels contour lines
%         for level_ix = 1:numel(isocontourline_levels)
%             Cur_contourlines = all_contourlines{level_ix};
%     
%             if ~isempty(Cur_contourlines)
%                 % optional threshold marker
%                 if size(all_thresholds,1) >= level_ix && size(all_thresholds,2) >= 3
%                     scatter(all_thresholds(level_ix,2), all_thresholds(level_ix,3), ...
%                         60, 'w', 'filled', 'MarkerEdgeColor', 'k');
%                 end
%     
%                 for kk = 1:length(Cur_contourlines)
%                     points = Cur_contourlines{kk}.contour_points;
%                     plot(points(1,:), points(2,:), 'w--', 'LineWidth', 2);
%                 end
%             end
%         end
%         set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')
% 

        %% calculate spread of excitation in octaves
        % get tonotopic slope 
        tonotopy_files=dir(fullfile(expProcDataDir,'ICME','*tonotopy_res_dprimethr_1_mode_increasingLvl.mat'));
        if ~isempty(tonotopy_files)
            res=load(fullfile(tonotopy_files(1).folder,tonotopy_files(1).name));
            tonotopy_slope=res.tonotopy_slope;
        else
            tonotopy_slope= 4.5; 
        end        
        SoEs_mm=SoEs_elecs*0.05; %50 µm per electrode
        SoEs_oct=SoEs_mm*tonotopy_slope;


        %% save results in output structure
        SoE_results.analysisType='Contourlines';
        SoE_results.mode=mode;
        SoE_results.fixed_var_header=d_prime_results.fixed_var_header;
        SoE_results.fixed_var_value =d_prime_results.fixed_var_value; % what was the fixed variable of the stimulus for this analysis
        SoE_results.changing_var_header =d_prime_results.changing_var_header; % what was the fixed variable of the stimulus for this analysis
        SoE_results.changing_var_values =d_prime_results.changing_var_values; % what was the fixed variable of the stimulus for this analysis

        SoE_results.isocontourline_levels= isocontourline_levels;
        SoE_results.thresholds=all_thresholds(:,2);
        SoE_results.best_electrode=all_thresholds(:,3);
        SoE_results.SoE_elecs = SoEs_elecs;
        SoE_results.SoE_mm = SoEs_mm;
        SoE_results.SoE_oct = SoEs_oct;

        all_SoE_results{stim_ix}=SoE_results;
    end
    

end
