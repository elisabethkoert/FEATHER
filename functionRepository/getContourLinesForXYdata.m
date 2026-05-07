function [all_contourlines,all_thresholds] = getContourLinesForXYdata(data,contour_levels,x_values,y_values)
%getContourLinesForXYdata extracts the contourlines and thresholds (x,y) at the contour levels
% The data should be an array of numbers where the collumns are associated 
% to the x-values and the rows associated to the y values, eg. a dPrime analysis results array
% closed contourlines get removed, those that are touching the edge ofthe
% y-Values get closed all the way to the highest x_value
%   Input:
%       data(nxm array of doubles): 
%       contour_levels(1xk list of doubles): levels to extract the contourlines
%           from eg. dPrimevalues at [1,2,3];
%       x_values(mx1 list of doubles): describing the collumns in the data
%       y_values(nx1list of doubles): describing the rows in the data
%   Output:
%       all_contour_lines(struct length contour levels): containing the
%           points (x,y) of all contourlines as well as the threhsodl for each
%           line
%       all_thresholds (kx3) list containing the contour valuesin the first collumn and then the
%           (x,y) values of the threshold (smallest x) for that level



% Example for d' increasing Lvl contourlines and threhsolds
%     all_d_prime_results = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array, t_start,t_stop);
%     d_prime_results=all_d_prime_results{1};
%     [all_contour_lines,all_thresholds]=getContourLinesForData( ...
%         d_prime_results.all_Dprime_cumsum,d_prime_results.analyzed_d_prime_array,d_prime_results.stimuli(2:end),IC.SL.all_electrodes+1)



% calculate contour matrix
    all_contourlines=cell(size(contour_levels));
    all_thresholds=NaN(length(contour_levels),3);
    all_thresholds(:,1)=contour_levels;
    % if not enough datapoints return empty
    if size(data,2)<2
        return
    end
    ContourMatrix=contourc(x_values,y_values,data,contour_levels);
    % separate into inidividual contourlines and save according to
    % dPrime value
    ix=1;
    while ix<size(ContourMatrix,2)
        dPrime_level=ContourMatrix(1,ix);
        num_of_points=ContourMatrix(2,ix);
        contour_points=ContourMatrix(:,ix+1:ix+num_of_points);
%             fprintf('contour line for dPrime:%.1f with %i points \n',dPrime_level,num_of_points)
        % check if contourline is closed 
%         if  all(contour_points(1,1)==contour_points(1,end)) && (round(contour_points(2,end),1)== round(contour_points(2,1),1))
% %            do nothing
%         else % only save non closed lines
            %check if contourline touches the edges of the electrode
            %array and needs to be closed there
            if contour_points(2,1)==min(y_values) || contour_points(2,1)==max(y_values) % beginning of line
                contour_points=[[x_values(end);contour_points(2,1)],contour_points];
            end
            if contour_points(2,end)==min(y_values) || contour_points(2,end)==max(y_values) % end of line
                contour_points=[contour_points,[x_values(end);contour_points(2,end)]];
            end
            analyzed_d_prime_ix=find(contour_levels==dPrime_level);
            [value,ii]=min(contour_points(1,:));
            helper.contour_points=contour_points;
            helper.threshold=contour_points(:,ii);
            all_contourlines{analyzed_d_prime_ix}{end+1}=helper;
        % end
        ix=ix+num_of_points+1;
    end

    % get overall thresholds for each level
    for level_ix=1:length(contour_levels)
        if ~isempty(all_contourlines{level_ix})
            cur_contourlines=all_contourlines{level_ix};
            cur_thresholds=cellfun(@(x) x.threshold,cur_contourlines,'UniformOutput',false);
            cur_thresholds=horzcat(cur_thresholds{:});
            [~,min_ix]=min(cur_thresholds(1,:));
            all_thresholds(level_ix,2:3)=cur_thresholds(:,min_ix);
        end
    end


end