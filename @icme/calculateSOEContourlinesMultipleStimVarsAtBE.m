function all_SoE_results = calculateSOEcontourlinesMultipleStimVarsAtBE(obj, mode, stim_criteria_array, t_start, t_stop)
% icme/calculateSOEcontorulinesMultipleStimVarsAtBE calculates the thresholds at the best electrode and SoE based on d'contourlines
% This function firsts calculates the cumulative d' array (or
% baseline depending on the mode) for all electrodes and stimuli that fall
% into the stim_criteria_array. Then it calculates the contourlines in this
% array. Closed contourlines are removed, the ones on the electrode edges are closed to the highest intensity.
% The best electrode is determined as the one with the lowest intensity in
% the d'=1 contourline. THe threhsolds for higher d' levels are read at
% this electrode as first stimulus intensity needed to get to each d'
% level. The SoE (spread of excitation) is determined by measuring the width 
% of the d' isocontourline at this threshold value.
% 	obj icme 
% 	mode string how to calculate the d' value (increasingLvL or baseline)
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with
%      50-90 dB (increasing lvl sorts by frequency)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
% 	t_start (double) & t_stop (double) : time window [ms] after trigger that is used for the analysis
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
 
    
     % load d prime results
    all_d_prime_results = calculateDprimeMultipleStimVars(obj,mode,stim_criteria_array, t_start,t_stop);
    all_SoE_results ={};
    for stim_ix=1:length(all_d_prime_results)
        d_prime_results=all_d_prime_results{stim_ix};
        analyzed_d_prime_array = d_prime_results.analyzed_d_prime_array;
        if strcmp(mode,'increasingLvl')
            cur_data =d_prime_results.all_Dprime_cumsum;
            used_stimuli=d_prime_results.changing_var_values(2:end);
        elseif strcmp(mode,'baseline')
            cur_data =d_prime_results.all_Dprime_array;
            used_stimuli=d_prime_results.changing_var_values;
        end

        % check if the first collumn already goes above d'=1 in any
        % electrode forthis will cause issues in closing the contourlines
        if any(cur_data(:,1)>1)
            % if yes add a collumn
            cur_data=[zeros(size(cur_data,1),1),cur_data];
            used_stimuli=[0;used_stimuli];
        end

         % get contourlines and threhsolds
        [all_contourlines,all_thresholds] =getContourLinesForXYdata(cur_data,...
            analyzed_d_prime_array,used_stimuli,obj.SL.all_electrodes+1);
        dp1_contourlines=all_contourlines{1};

        % close dP1 contourlines to run along edges of IC if necessary
        if ~isempty(dp1_contourlines)
             % get threeshold values in mW at the best electrode
             % find best electrode
            x_values=cellfun(@(x) (x.threshold(1)), dp1_contourlines);
            [~,pos]=min(x_values);
            dp1_threshold=dp1_contourlines{pos}.threshold;
            BE=round(dp1_threshold(2));
            p = polyfit(cur_data(BE,:),used_stimuli,5); % fit for threhsold finding
    
            % find overall threshold values and SoE
            SoEs_elecs=NaN(size(analyzed_d_prime_array));
            all_thresholds=zeros(2,length(analyzed_d_prime_array));
            for d_prime_ix=1:length(analyzed_d_prime_array)
              % check if the value gets reached and only then caclulate SoE
              if analyzed_d_prime_array(d_prime_ix)<=max(cur_data(BE,:))
                    % get threshold at BE by looking at the values in the
                    % dPrime analysis results array cur_data
                    % no interpolation
                    threshold_mW=used_stimuli(find(cur_data(BE,:)>=analyzed_d_prime_array(d_prime_ix),1));
                    % interpolation
    %                     threshold_mW=polyval(p,analyzed_d_prime_array(d_prime_ix));
                    % save threshold
                    all_thresholds(:,d_prime_ix)=[threshold_mW;BE];
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
                            elseif (x1 - threshold_mW) * (x2 - threshold_mW) < 0  % check if threshold is between x1 and x2
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
                    if isempty(intersections)
                        SoEs_elecs(d_prime_ix)=1;
                    else
                        covered_electrodes=unique(intersections(:,2));
                        if ~isempty(covered_electrodes)
                            if length(covered_electrodes)==1
                                SoEs_elecs(d_prime_ix)=1;
                            else
        %                         SoEs_elecs(d_prime_ix)=ceil(max(covered_electrodes))-floor(min(covered_electrodes));
                                SoEs_elecs(d_prime_ix)=max(covered_electrodes)-min(covered_electrodes); % this allows for electrode interpolation as well
                            end
                        end
                    end
                end
            end
    
    
    
         
    
    % %         % plot results
    %         n_electrodes=length(obj.SL.all_electrodes);
    %         f1 = figure('color', [1 1 1], 'units','normalized','position',[.1 .1 0.35 .7]); 
    %         hold on; 
    % %         title(num2str(SoEs_elecs(1:8)))
    %         pcolor(used_stimuli,[obj.SL.all_electrodes+1], cur_data); 
    %         ylim([1 n_electrodes]); 
    %         xlim([d_prime_results.changing_var_values(1) d_prime_results.changing_var_values(end)])
    %         c = colorbar; 
    %         cmap=parula(2*ceil(max(max(cur_data))));
    %         xlabel('intensity [mW]')
    %         ylabel('electrode')
    %         colormap(cmap);
    %         clim([0 ceil(max(max(cur_data)))])
    %         c.Label.String="cum d'";
    %         % plot threshholds and contour lines for d'1,2,3
    %         colormarkers={':w','--r','-.w'};
    %         threshold_markers={'pw','ow','sw'};
    %         title(obj.SeriesID)
    %         for d_prime_i=[1,2,3]
    %             d_prime_pos=find(d_prime_i==analyzed_d_prime_array);
    %             Cur_contourlines=all_contourlines{d_prime_pos};
    %             % check if the contour is a circle
    %             if ~isempty(Cur_contourlines) 
    % %                 scatter(all_thresholds(1,d_prime_pos),all_thresholds(2,d_prime_pos),100,threshold_markers{d_prime_i},'filled') 
    %                 for kk=1:length(Cur_contourlines)
    %                     points= Cur_contourlines{kk}.contour_points;
    %                     plot( points(1,:),points(2,:),colormarkers{d_prime_i}, 'linewidth', 3)
    %                 end
    %             end
    %         end
    %             set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')
    % %         
     
    
            % calculate spread of excitation in octaves
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
    
            
            % get best_electrode based only on dPrime_matrix
            best_elecs=all_thresholds(2,find(analyzed_d_prime_array==1));
        else
            SoEs_elecs=NaN(size(analyzed_d_prime_array));
            SoEs_mm=NaN(size(analyzed_d_prime_array));
            SoEs_oct=NaN(size(analyzed_d_prime_array));
            best_elecs=NaN(size(analyzed_d_prime_array));
        end
        
        % save results in output structure
        SoE_results.analysisType='ControurlinesAtBE';
        SoE_results.fixed_var_header=d_prime_results.fixed_var_header;
        SoE_results.fixed_var_value =d_prime_results.fixed_var_value; % what was the fixed variable of the stimulus for this analysis
        SoE_results.changing_var_header =d_prime_results.changing_var_header; % what was the fixed variable of the stimulus for this analysis
        SoE_results.changing_var_values =d_prime_results.changing_var_values; % what was the fixed variable of the stimulus for this analysis
        SoE_results.isocontourline_levels= analyzed_d_prime_array;
       
        SoE_results.SoE_elecs = SoEs_elecs;
        SoE_results.SoE_mm = SoEs_mm;
        SoE_results.SoE_oct = SoEs_oct;
        SoE_results.best_electrode=best_elecs;
   

        all_SoE_results{stim_ix}=SoE_results;
    end
    
end

  


