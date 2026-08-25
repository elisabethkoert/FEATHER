function [all_peak_results]=calc_dPrime_over_separate_peak(IC,stim_criteria_array,t_start,t_stop)
% icme\calc_dPrime_over_separate_peak splits a spectral tuning curve into its
% separate spectral peaks and describes each of them
% The d' array of the recording is calculated against the baseline with
% icme\calculateDprimeMultipleStimVars, smoothed, and a d'=1 contour line is
% drawn through it. Where that contour reaches its lowest intensity the
% recording responds most sensitively, so several such minima mean the
% recording has several spectral peaks. The d' array is cut apart at the least
% sensitive point between neighbouring peaks and every peak is then described
% on its own by its threshold per d' level, its best electrode and the centroid
% of its d'=1 contour. If no contour can be drawn at all, the recording is
% handed to icme\calc_dPrime_over_single_peak and treated as one peak.
%
% input:
%   IC (icme) IC recording object
%   stim_criteria_array (nx3 array floats) helper to identify wanted stimuli
%       [column in stimlist, min value, max value]. The first row describes the
%       intensity that forms the x axis, further rows fix the remaining
%       stimulus properties
%       exp. [4,50,90;1,500,32000] analyses stimuli of increasing SPL
%       (50-90 dB), separated by frequency
%   t_start (double) start of the time window in which the spike rate is
%       extracted, in ms after trigger
%   t_stop (double) end of that time window, in ms after trigger
% output in all_peak_results, one element per detected spectral peak:
%   ExpID (char) animal the recording belongs to
%   electrodes (1xp double) electrodes of the original probe that this peak
%       spans
%   intensities (1xm double) intensities that were compared, in the unit of the
%       changing stimulus variable (e.g. mW, dB SPL)
%   analyzed_d_primes (1xk double) d' levels the thresholds were determined for
%   thresholds_by_channel (pxk double) intensity at which each electrode of the
%       peak first exceeds each analysed d' level, NaN where it never does
%   thresholds (1xk double) smallest of those intensities across the electrodes
%       of the peak, i.e. the threshold of the peak at each d' level
%   BE (double) best electrode of the peak: the electrode reaching the lowest
%       threshold at the first analysed d' level, in original probe numbering
%   centroid_BE (double) electrode coordinate of the centroid of the d'=1
%       contour polygon, in original probe numbering; a smoother estimate of
%       the position of the peak than BE
%   dPrime_array (pxm double) part of the d' array belonging to this peak
%   SR_array (pxm double) matching evoked spike rates in Hz
%
% assumptions:
%   The probe has 32 electrodes.
%   Peaks detected on the first or last electrode are discarded, because a peak
%   at the edge of the probe cannot be delimited on both sides.
%   The contour used for the centroid is drawn only up to the intensity at
%   which d'=3 is reached, or up to the highest threshold reached if d'=3 never
%   is.
%   Caching is switched off while the d' array is calculated and switched back
%   on at the end, so the function changes the global cache state.
%
% side effects:
%   Draws a figure of the detected peaks and centroids and writes it to disk
%   for visual inspection; the output folder is currently hard-coded.

% define parameters at the beginning
enablecache off
% calculate the dPrime array 
[all_d_prime_results_baseline] = calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
% calculate the SR array 
[all_evoked_spike_rate] = calculateEvokedSpikeRate(IC,stim_criteria_array, t_start,t_stop );
mean_SR_array=all_evoked_spike_rate(1,1).meanEvokedSpikeRate;
d_prime_array=all_d_prime_results_baseline{1,1}.all_Dprime_array;
Lvl=all_d_prime_results_baseline{1, 1}.changing_var_values;
% smooth the d-Prime array to reliably detect peaks 
dPrimeArray_smoothed = imgaussfilt(d_prime_array, 2);
% plot the filled contours
fig_0=figure();
% ----- OPTIONAL plot plot all contours for reference -----
subplot(1,2,1)
plotHeatmapContour_ChReefLED(IC,stim_criteria_array,t_start,t_stop,400,[200,300,400],'parula');
set(fig_0,'Position',[100,100,900,450])
subplot(1,2,2)
% --------- 
 try [C1, h1] = contourf(Lvl(1:end),1:1:32,dPrimeArray_smoothed,[1 1]); % try drawing contour lines
     s1 = getcontourlines(C1); % separate individual contour line shapes
 catch
     warning('There is not sufficient sifgnificant activation to calculate contour lines! change specified parameters')
     close(fig_0)
     [all_peak_results]=calc_dPrime_over_single_peak(IC,stim_criteria_array,t_start,t_stop);
     return
 end
 % close(fig_0);
 % get individual contour lines
 contour_lines=struct();
 contour_lines.x=[];
 contour_lines.y=[];
 n=0;
 for zz = 1:size(s1, 2)
    % closed contours are islands inside the tuning curve rather than its
    % outline, so only open contour lines are kept
    if s1(zz).x(1) == s1(zz).x(end) && s1(zz).y(1) == s1(zz).y(end)
    else 
        n=n+1;
       contour_lines.x=[contour_lines.x,s1(zz).x];
       contour_lines.y=[contour_lines.y,s1(zz).y];
    end
 end
 % The contour is most sensitive where its intensity is lowest, so the
 % spectral peaks are the valleys of contour_lines.x. Mirroring the trace
 % turns those valleys into peaks that findpeaks can locate.
 contour_lines.x=-contour_lines.x;
 match_peaks=contour_lines.x-min(contour_lines.x);

% Find spectral peaks
[pks_all,locs_all]=findpeaks(match_peaks);% find locations of spectral peaks, ,"MinPeakHeight",0.3
peak_locs_all=contour_lines.y(locs_all);
[peak_locs_all,peak_sort_ix]=sort(peak_locs_all);
pks_all=pks_all(peak_sort_ix);
peak_locs=peak_locs_all;
pks=pks_all;
% ----- OPTIONAL plot found contour lines -----
hold on
scatter(-min(contour_lines.x)-pks,peak_locs,50,'filled','blue','DisplayName','Peaks') % substract from maximum to run peak into actual position in the plot 
% ----
% split the d-Prime array in between peaks to analyze them seperately
start_index=1;
end_index=[];
% a peak sitting on the first or last electrode cannot be delimited on
% both sides, so it is not treated as a separate peak
peak_locs=peak_locs(~(peak_locs==32));
peak_locs=peak_locs(~(peak_locs==1));
% cut between two peaks at the electrode where the contour is least
% sensitive, i.e. where the highest intensity is needed to reach d'=1
for num_peaks=1:numel(peak_locs)-1
    inter_peaks=find(contour_lines.y>peak_locs(num_peaks) & contour_lines.y<peak_locs(num_peaks+1));
    [~,is_min]=min(contour_lines.x(inter_peaks));
    min_loc(num_peaks)=contour_lines.y(inter_peaks(is_min));
    start_index=[start_index,round(min_loc(num_peaks))+1];
    end_index=[end_index,round(min_loc(num_peaks))];
end
end_index=[end_index,32];
% now create an individual d-Prime Array for every peak
for num_peaks=1:numel(start_index)
    all_peaks{num_peaks}=d_prime_array(start_index(num_peaks):end_index(num_peaks),:);
    all_peaks_SR{num_peaks}=mean_SR_array(start_index(num_peaks):end_index(num_peaks),:);
end
% analyze parameters of each peak individually
all_peak_results=struct();
intensities=all_d_prime_results_baseline{1,1}.changing_var_values; % get intensities from the d-Prime structure
analyzed_d_primes=all_d_prime_results_baseline{1,1}.analyzed_d_prime_array; 
for is_peak=1:numel(all_peaks) % loop through all detected peaks
    all_electrodes=[1:size(all_peaks{is_peak},1)]; % define a new electrode array based on the size of the peak, this does not resemble the original electrodes
     thresholds_by_channel = nan(length(analyzed_d_primes), size(all_peaks{is_peak},1))';
     cur_dP_array=all_peaks{1,is_peak};
        for d_prime_i=1:length(analyzed_d_primes)
                % find the threshold value
                cur_d_prime=analyzed_d_primes(d_prime_i);
                for elec_i=1:length(all_electrodes)
                    indices=find(cur_dP_array(elec_i,:)>cur_d_prime);
                    if ~isempty(indices)
                        thresholds_by_channel(elec_i,d_prime_i)=min(intensities(indices));
                    end                        
                end  
        end    
         all_peak_results(is_peak).thresholds=min(thresholds_by_channel,[],'omitnan');
         if isempty(all_peak_results(is_peak).thresholds) % no d' level was ever reached in this peak, skip it
             all_peak_results(is_peak).thresholds=[];
             continue
         end
         % transfer to the all_peak_results structure
         all_peak_results(is_peak).ExpID=IC.ExpID;
         all_peak_results(is_peak).intensities=intensities;
         all_peak_results(is_peak).analyzed_d_primes=analyzed_d_primes;
         all_peak_results(is_peak).electrodes=[start_index(is_peak):1:end_index(is_peak)]; 
         all_peak_results(is_peak).thresholds_by_channel=thresholds_by_channel; 
         % Get the centroid of activation
         max_d_Prime_level=3; % cutoff for drawing of contour
         d_prime_max_ix=find(max_d_Prime_level==analyzed_d_primes);
         is_max_mw=all_peak_results(is_peak).thresholds(d_prime_max_ix); % for drawing centroid until the maximum dPrime reached
         if isnan(is_max_mw)
              is_max_mw=max(all_peak_results(is_peak).thresholds);% if max d Prime is not reached, go for highest d Prime reached
         end
         is_min_mw=min(all_peak_results(is_peak).thresholds);
         intensities_for_ix=intensities(1:end);
         is_ix_low=find(intensities_for_ix==is_min_mw); % not used currently
         is_ix_high=find(intensities_for_ix==is_max_mw);
         f0=figure();
         try [C1, h1] = contourf(Lvl(1:is_ix_high),all_electrodes,all_peaks{1,is_peak}(:,1:is_ix_high),[1 1]);% draws contourline specifically around the peak
             s1 = getcontourlines(C1);
         end
        close(f0)
        % get the contour lines in to the format to draw a polygon
        sizes = arrayfun(@(s) numel(s.x), s1);
        [~, size_idx] = max(sizes);
        % Keep the longest contour line, which is the outline of the peak.
        % shape_coordinates(1) is the empty element left by the struct
        % initialisation and is used below to hold the corner points that
        % close the outline against the edges of the probe; the contour
        % itself sits in shape_coordinates(2), and both are concatenated
        % when the polygon is built.
        shape_coordinates=struct;
        shape_coordinates(end+1).x=s1(size_idx).x;
        shape_coordinates(end).y=s1(size_idx).y;
        % contour touches the first electrode: close it at that edge
        if any([shape_coordinates(:).y]==1)
            shape_coordinates(1).x=[intensities_for_ix(is_ix_high),shape_coordinates(1).x];
            shape_coordinates(1).y=[1,shape_coordinates(1).y];
        end
        % contour touches the last electrode of the peak: close it there too
        if any([shape_coordinates(:).y]==size(all_peaks{is_peak},1))
            shape_coordinates(1).x=[shape_coordinates(1).x,intensities_for_ix(is_ix_high)];
            shape_coordinates(1).y=[shape_coordinates(1).y,size(all_peaks{is_peak},1)];
        end
        % draw the polygon and find the centroid
        pgon_contour=polyshape([shape_coordinates(:).x,],[shape_coordinates(:).y]);
        [centroid_int,centroid_BE]=centroid(pgon_contour);
    
        all_peak_results(is_peak).centroid_BE=(centroid_BE+(start_index(is_peak)-1));
        all_peak_results(is_peak).BE=(mean(find(thresholds_by_channel(:,1)==all_peak_results(is_peak).thresholds(1)))+(start_index(is_peak)-1));
        all_peak_results(is_peak).dPrime_array=all_peaks{1,is_peak};
        all_peak_results(is_peak).SR_array=all_peaks_SR{1,is_peak};
        % ------ OPTIONAL plot the location of the centroid -------
        scatter(centroid_int,all_peak_results(is_peak).centroid_BE,50,'filled','red','DisplayName','Centroid')
end
% ------ OPTIONAL check the position of centroid and peak detection and save the figure -------
% adapt the plot a little bit
figure(fig_0);   % bring the figure to the front for inspection
xlabel(all_d_prime_results_baseline{1, 1}.changing_var_header)
ylabel('Electrode [#1-32]')
title(strcat('Detection of separate peaks and centroids in ',IC.SeriesID,' ',all_d_prime_results_baseline{1, 1}.changing_var_header))
% wait for user input
% uiwait(msgbox('Check if figures look reasonable, then press OK.', 'Review', 'modal'));
% now save the figure for documentation
ax = gca;
ax.YDir = 'reverse';
fig_path="W:\home\nalbrecht\Writing\MS\ChReef_LED\Fig_graphics\Fig_5_Cf_shift\Centroid_Peak_Detection";
fig_name=[strcat(IC.SeriesID,'_',all_d_prime_results_baseline{1, 1}.changing_var_header,'_','Centroid.png')];
exportgraphics(fig_0,fullfile(fig_path,fig_name),"Resolution",300)
close(fig_0) % close the figure
enablecache on
end
