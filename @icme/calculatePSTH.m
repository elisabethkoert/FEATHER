function [PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC_list,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,t_start,t_stop,PSTH_binsize,normalize_plot )
% icme\calculatePSTH calculates (and plots) the PeriStimulusTimeHistogram and its on/off kinetics
% This script creates the PSTH for one icme for all stimuli matching the given stimulus criteria in the given time
% window tstart-tstop and it calculates the response onset and offset (t_onset, t_offset) 
% from the normalized histogram as the timepoint when the
% spikerate is more than 3x std of the baseline mean 
% (baseline currently calculated form the last 10 ms of the stimulation
% window). The offset has to be at least 2 ms after the onset to avoid
% detecting noise in the stimulus onset.
%
% output
%   PSTH_norm: (1xn double) normalized PSTH of the detected spikes
%   PSTH: (1xn double) actual PSTH of the detected spikes
%   bin_centers: (1xn) of the centers of the PSTH bins (ms)
%   resp_ix: (nx1) indices of PSTH entries between t_onset and t_offset
%   t_onset [ms]: first bin after t_start where 2 consecutive bins are above 3*std above baseline mean activity , if not detected, set to t_stop
%   t_offset [ms]: first bin after t_onset where 2 consecutive bins are below 3*std above baseline mean activity, set to t_stop if not detected
%   peak_response_time [ms]: float, bin with the highest response rate [ms]
%
% input:
%   	IC_list: icme/list of ICMEs
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [column in stimlist, min value, max value]
%      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   elecs: list[int] which electrodes the spikes should be taken from, if
%       kept empty, the function to get responsive units will be called
%   plot_bool: bool, decide if the figure should be created or if we only calculate the output values
%   artefact_removal: bool, decide if the spikes during stimulus
%   stimdur_ix: int of where in stimlist the whole stimulus duration is found (needed for artefact removal) and plotting
%   t_start: float/int start timepoint for histogram bins and also response time analysis
%   t_stop: float/int end of histogram bins/ analysis of spikerate
%   PSTH_binsize: float bin size in ms
%   normalize_plot: bool if plot shows normalized count or real count


    if ~exist('t_start')
         t_start = -10;% time before and after a trigger that is supposed to be investigated
    end
    if ~exist('t_stop')
         t_stop = 50;% time before and after a trigger that is supposed to be investigated
    end
    if ~exist('PSTH_binsize')
         PSTH_binsize=0.25;% 0.25 ms used in MAria Michael paper 2023
    end
     if ~exist('artefact_removal')
         artefact_removal=0; % default not to 
     end
     if ~exist('normalize_plot')
         normalize_plot=1; % default not show normalized PSTH
     end
    
    Spik_list=[];
    num_recordings=0;
    num_of_units=0;
    for IC=IC_list % lop through all presented icmes
        fprintf('calculating PSTH for %s \n',IC.SeriesID)
        % try if the calibrated Stimlist exists    
        if isfield(IC.C,'stimlistCal')
            OBJ_stimlist=IC.C.stimlistCal;
        else
            OBJ_stimlist=IC.Stim.stimlist;
        end
    
        
    
        %% Extract the relevant spikes
        % get the relevant stim_ID
        stim_ID=1:1:length(OBJ_stimlist(:,1));
            for jj=1:size(stim_criteria_array,1)
                stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
                stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
                stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
                stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
            end
        % get stimdur
        stimdur=max(IC.Stim.stimlist(:,stimdur_ix));
        if  contains(IC.ExpInfo.exp_type,'eCI') %eCI gives stimudur in µs
            stimdur=stimdur/1000;
        end
        % actually get active electrodes if no electrodes were given as
        % input
        if isempty(elecs)
             elecs_cur=getResponsiveUnits(IC,stim_criteria_array,3,30);
        else
            elecs_cur=elecs;
        end
        num_of_units=num_of_units+length(elecs_cur);
        % collect all spikes that fulfill the requirements
        Spik_list_now=[];
        for elec_ix=1:length(elecs_cur)
            elec=elecs_cur(elec_ix);
            elec_name=strcat('elec', num2str(elec-1));
            Spik_list_cur=IC.SL.spik_list_all.(elec_name);
            ix=ismember(Spik_list_cur(:,1),stim_ID);
            Spik_list_now=[Spik_list_now;Spik_list_cur(ix,:)];
        end
        % extract info on the investigated stimulus
        if contains(IC.Stim.exp_type,'f_train') & contains(IC.Stim.exp_type,'Pulse')
            stim_intensity=unique(OBJ_stimlist(stim_ID,1));
            rep_rates=unique(OBJ_stimlist(stim_ID,4));
            stim_intensity_str=sprintf('%s mW Pulse %s Hz',strjoin(string(stim_intensity),','),strjoin(string(rep_rates),','));
        elseif contains(IC.Stim.exp_type,'Pulse')
            stim_intensity=unique(OBJ_stimlist(stim_ID,1));
            stim_intensity_str=sprintf('%s mW Pulse',strjoin(string(stim_intensity),','));
        elseif contains(IC.Stim.exp_type,'MX_tones')
            stim_intensity=unique(OBJ_stimlist(stim_ID,4));
            stim_freq=unique(OBJ_stimlist(stim_ID,1));
            stim_intensity_str=sprintf('%s Hz %s dB',strjoin(string(stim_freq),','),strjoin(string(stim_intensity),','));
        else
            stim_intensity_str=sprintf('stim #%i',stim_ID);
        end
    
        %% stimulus artefact removal
        % remove all spikes in the time window of the stimulation +- 0.25 ms
        if artefact_removal==1
             if ~contains(IC.ExpInfo.exp_type,'f_train') && ~contains(IC.ExpInfo.exp_type,'eCI')%single pulse removal
                stim_start=0;
                stim_end=stim_start+stimdur;
                Spik_list_now(find(Spik_list_now(:,6)>=stim_start-0.15/1000 & Spik_list_now(:,6)<=stim_start+0.1/1000),:)=[];
                Spik_list_now(find(Spik_list_now(:,6)>=stim_end+0.1/1000 & Spik_list_now(:,6)<=stim_end+0.35/1000),:)=[];
             elseif contains(IC.ExpInfo.exp_type,'eCI')
                    % take out spikes between 0.1 and 3 ms because some
                    % artefact thing is happenig in the psth, same values
                    % as in alexDieter2019 methods
                  Spik_list_now(find(Spik_list_now(:,6)>=-0.5/1000 & Spik_list_now(:,6)<=2.5/1000),:)=[];
             else % pulse train removal
                rate=OBJ_stimlist(stim_ID,4);
                stim_start=[0:(1000/rate):100]/1000;
                stim_end=stim_start +1/1000;
                for art_ix=1:length(stim_start)
                    Spik_list_now(find(Spik_list_now(:,6)>=stim_start(art_ix)-0.15/1000 & Spik_list_now(:,6)<=stim_start(art_ix)+0.1/1000),:)=[];
                    Spik_list_now(find(Spik_list_now(:,6)>=stim_end(art_ix)+0.1/1000 & Spik_list_now(:,6)<=stim_end(art_ix)+0.35/1000),:)=[];
                end
            end
        end
        
        Spik_list=[Spik_list;Spik_list_now];
        if ~isempty(Spik_list_now)
                    num_recordings=num_recordings+1;
        end

    end

%% create PSTH with quantification for a time_window
%     PSTH_bins = [t_start:PSTH_binsize:t_stop];
%     PSTH = histc(Spik_list(:, 6)*1000,PSTH_bins); % completely work in ms
    [PSTH,edges] = histcounts(Spik_list(:, 6)*1000,'BinWidth',PSTH_binsize,'BinLimits',[t_start,t_stop]);
    PSTH_norm = PSTH./max(PSTH); % normalize PSTH to maximum response
    bin_centers=(edges(1:end-1) + edges(2:end)) / 2;
    [~,ix_max]=max(PSTH_norm);
    peak_response_time=edges(ix_max); % in ms after stimulus onset

    
    mean_baseline = mean(PSTH_norm(bin_centers < -5)); % determine the mean of baseline activity using baseline at least 5 ms before trigger (to avoid artefact before the stimulus
    std_baseline  = std(PSTH_norm(bin_centers <-5));  % determine the standard deviation of baseline activity
    
    % get the time window of significant responses for first 2 stimuli
    % above baseline after stimulus onset
%     idx_onset=find(bin_centers==min(abs(bin_centers)));
    [~, idx_onset] = min(abs(bin_centers));
    idx_bigger_baseline = find(PSTH_norm > (mean_baseline+3*std_baseline));
    idx_bigger_baseline(idx_bigger_baseline<=idx_onset)=[];
    diffs_above = diff(idx_bigger_baseline);
    first2aboveBaselineBinIndex = idx_bigger_baseline(find(diffs_above==1, 1));
    
    if ~isempty(first2aboveBaselineBinIndex)
        % first 2 stimuli below afterwards
        idx_below_baseline =find(PSTH_norm <= (mean_baseline+3*std_baseline));
        idx_below_baseline(idx_below_baseline<first2aboveBaselineBinIndex+2/PSTH_binsize)=[];
        diffs_below = diff(idx_below_baseline);
        first2belowBaselineBinIndex = idx_below_baseline(find(diffs_below==1, 1));
    else
        first2belowBaselineBinIndex =1;
    end

    % to make plotting easier, create a boolean matrix of significant responses
    resp_idx = zeros(length(bin_centers), 1); 
    resp_idx(first2aboveBaselineBinIndex:first2belowBaselineBinIndex-1) = 1;
    t_onset = bin_centers(first2aboveBaselineBinIndex); % ms
    t_offset =bin_centers(first2belowBaselineBinIndex); %ms
    
    %% PSTH for all normalized spikes with time window analysis around P1
    if plot_bool==1
        figure('color', [1 1 1], 'units','normalized','position',[0.2 0.0525 0.597395833333333 0.375]);
        hold on;
        if normalize_plot==1
            bar(bin_centers(resp_idx == 0), PSTH_norm(resp_idx == 0), 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', [0.7 0.7 0.7]);
            bar(bin_centers(resp_idx == 1), PSTH_norm(resp_idx == 1), 'FaceColor', 'k', 'EdgeColor', 'k');
             ylim([0 1]); set(gca, 'YTick', [0:0.5:1]); 
             %plto stimulus
            plot([0,0,stimdur*1000,stimdur*1000],[0,1,1,0],'r','LineWidth',2)
            % horizontal plot for 3*baseline
            plot([t_start,t_stop],[mean_baseline+3*std_baseline,mean_baseline+3*std_baseline],'k--')
        else
            bar(bin_centers(resp_idx == 0), PSTH(resp_idx == 0), 'FaceColor', 'k', 'EdgeColor', 'k');
            bar(bin_centers(resp_idx == 1), PSTH(resp_idx == 1), 'FaceColor', 'k', 'EdgeColor', 'k');
        end
        set(gca,'FontSize',16);
        xlim([t_start t_stop]);
        set(gca,'TickDir','out'); 
        ylabel('firing rate [norm.]');
        xlabel('time [ms]')
        title(sprintf('PSTH %i MUs: t_on = %.2f ms, t_off=%.2f ms',num_of_units,t_onset,t_offset),Interpreter="none")
%         title(sprintf('PSTH for %s in %s: t_on = %.2f ms, t_off=%.2f ms',stim_intensity_str,IC.SeriesID,t_onset,t_offset),Interpreter="none")
    end
end
