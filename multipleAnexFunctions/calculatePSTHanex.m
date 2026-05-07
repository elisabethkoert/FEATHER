function [fig,PSTH_norm,PSTH,bin_centers,resp_idx,t_onset,t_offset,peak_response_time,used_icmes] = calculatePSTHanex(ee_list,Exp_type,stim_criteria_array,plot_bool,artefact_removal,stimdur,t_start,t_stop,PSTH_binsize,normalize_plot )
    %anex/calculatePSTH calcualtes the normalized PeriStimulusTimeHistogram and calculates
    %its on/off kinetics for 1 or multiple anex for a given stimulus condition
    % optionally also plots the PSTH
    % This script creates the PSTH for  of the ICME only in the given time
    % window tstart-tstop and it calculates the response onset and offset (t_onset, t_offset) 
    % from the normalized histogram as the timepoint when the
    % spikerate is more than 2x std of the baseline mean 
    % (baseline currently calculated form the last 10 ms of the stimulation
    % window) The offset has to be at least 2 ms after the onset to avoid
% detecting noise in the stimulus onset.
    % Icmes marked as -1 in the user input table as well as recordings from
    % the apex or midturn are excluded, for those use the icme/calulatePSTH
    % function after first creating a list with all desired icmes
    %
    % output
    %   PSTH_norm: (1xn double) normalized PSTH of the detected spikes
    %   PSTH: (1xn double) actual PSTH of the detected spikes
    %   bin_centers: (1xn) of the centers of the PSTH bins (ms)
    %   resp_ix: (nx1) indices of PSTH entries between t_onset and t_offset
    %    t_onset [ms]: first bin after t_start where 2 consecutive bins are above 3*std above baseline mean activity , if not detected, set to t_stop
    %   t_offset [ms]: first bin after t_onset where 2 consecutive bins are below 3*std above baseline mean activity, set to t_stop if not detected
    %   peak_response_time [ms]: float, bin with the highest response rate [ms]
    %   used_icmes (cell array strings) containing the names of all ICMEs that
    %   went into the results
    % input:
    %    ee_list: (1xn cell array of anex) experiments from which to pool the spikes
    %    Exp_type: (sting) name of the experiment as given in the UserInput table
    %    stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
    %      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
    %      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
    %   plot_bool: bool, decide if the figure should be created or if we only calculate the output values
    %    artefact_removal: bool, decide if the spikes during stimulus
    %     presentation should be omitted (to avoid stimulation artefacts)
    %     stimdur: [s] float stimulus duration (needed for artefact removal) and plotting
    %    t_start: float/int start timepoint for histogram bins and also response time analysis
    %    t_stop: float/int end of histogram bins/ analysis of spikerate
    %    PSTH_binszize: float binsize in ms
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
    Spik_list_now=[];
    used_icmes={};
    num_recordings=0;
    num_animals=0;
    num_responsive_units=0;
    used_this_animal=0;
    for ee_ix=1:length(ee_list)
        ee=ee_list{ee_ix};
        %load UT
        Spik_list_now=[];
        if isfile(fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat")))
            in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
            load(in_dir_name);%loads UT, containing user input and stimulus types for each icme
            L =listIcme(ee);
            for ii = 1: numel(L.IC_SeriesID)
                ix_in_UT= cellfun(@(x) strcmp( x ,string(L.IC_SeriesID(ii))),UT.data(:,find(contains(UT.fieldNames,'SeriesID'))));
                if UT.data{ix_in_UT,find(contains(UT.fieldNames,'Use'))}== -1 ||...
                        ~contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'ExpType'))},Exp_type)||...
                        contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'pos cochlea'))},'mid')||...
                        contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'pos cochlea'))},'ap')
                    continue
                end
                IC=loadIcme(icme(ee,string(L.IC_SeriesID(ii))));
                Spik_list_now=[];
                 % % try if the calibrated Stimlist exists
                if isfield(IC.C,'stimlistCal')
                    OBJ_stimlist=IC.C.stimlistCal;
                else
                    OBJ_stimlist=IC.Stim.stimlist;
                end


                stim_ID=1:1:length(OBJ_stimlist(:,1));
                for jj=1:size(stim_criteria_array,1)
                    stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
                    stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
                    stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
                    stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
                end
                if isempty(stim_ID)
                    continue
                end
                elecs = getResponsiveUnits(IC,stim_criteria_array);
                num_responsive_units=num_responsive_units+length(elecs);
                for elec=elecs'
                    elec_name=strcat('elec', num2str(elec-1));
                    Spik_list_cur=IC.SL.spik_list_all.(elec_name);
                    ix=ismember(Spik_list_cur(:,1),stim_ID);
                    Spik_list_now=[Spik_list_now;Spik_list_cur(ix,:)];
                end
                if artefact_removal==1 && ~isempty(Spik_list_now)
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
                    used_icmes{end+1}=IC.SeriesID;
                    used_this_animal=1; % to catch any ICME within the animal not just the last one
                 end
            end
            if used_this_animal==1 % if we took any data from this animal
                num_animals=num_animals+1; % increase number of animals if we made it to the end of 
                Spik_list_now=[]; % set empty before next animal
                used_this_animal=0;
            end
        end
    
    end
    
    
    %% create PSTH with quantification for a time_window
    if isempty(Spik_list) % return emtpy figure
        figure
        PSTH_norm=[];
        bin_centers=[];
        resp_idx=[];
        t_onset =[];
        t_offset=[];
        peak_response_time=[];
        PSTH=[];
        fig=[];
        return
    end
    [PSTH,edges] = histcounts(Spik_list(:, 6)*1000,'BinWidth',PSTH_binsize,'BinLimits',[t_start,t_stop]);
    PSTH_norm = PSTH./max(PSTH); % normalize PSTH to maximum response
    bin_centers=(edges(1:end-1) + edges(2:end)) / 2;
    [~,ix_max]=max(PSTH_norm);
    peak_response_time=edges(ix_max); % in ms after stimulus onset
    
    
    mean_baseline = mean(PSTH_norm(bin_centers < -5 )); % determine the mean of baseline activity using the activity before 5 ms before stimulus trigger
    std_baseline  = std(PSTH_norm(bin_centers <-5));  % determine the standard deviation of baseline activity
    
    % get the time window of significant responses for first 2 stimuli
    % above baseline after stimulus onset
    idx_onset=find(bin_centers==min(abs(bin_centers)));
    idx_bigger_baseline = find(PSTH_norm > (mean_baseline+2*std_baseline));
    idx_bigger_baseline(idx_bigger_baseline<=idx_onset)=[];
    diffs_above = diff(idx_bigger_baseline);
    first2aboveBaselineBinIndex = idx_bigger_baseline(find(diffs_above==1,1));
%     first2aboveBaselineBinIndex=first2aboveBaselineBinIndex(2);

    % first 2 stimuli below afterwards
    idx_below_baseline =find(PSTH_norm <= (mean_baseline+2*std_baseline));
    idx_below_baseline(idx_below_baseline<first2aboveBaselineBinIndex+2/PSTH_binsize)=[];
    diffs_below = diff(idx_below_baseline);
    first2belowBaselineBinIndex = idx_below_baseline(find(diffs_below==1,1));
%     first2belowBaselineBinIndex=first2belowBaselineBinIndex(2)
    
    % to make plotting easier, create a boolean matrix of significant responses
    resp_idx = zeros(length(bin_centers), 1); 
    resp_idx(first2aboveBaselineBinIndex:first2belowBaselineBinIndex-1) = 1;
    t_onset = bin_centers(first2aboveBaselineBinIndex); % ms
    t_offset =bin_centers(first2belowBaselineBinIndex); %ms
    
    %% PSTH for all normalized spikes with time window analysis around P1
    if plot_bool==1
        fig=figure('color', [1 1 1], 'units','normalized','position',[0.2 0.0525 0.597395833333333 0.375]);
        hold on;
       if normalize_plot==1
            bar(bin_centers(resp_idx == 0), PSTH_norm(resp_idx == 0), 'FaceColor', [0.5 0.5 0.5], 'EdgeColor', [0.7 0.7 0.7]);
            bar(bin_centers(resp_idx == 1), PSTH_norm(resp_idx == 1), 'FaceColor', 'k', 'EdgeColor', 'k');
             ylim([0 1]); set(gca, 'YTick', [0:0.5:1]); 
             %plto stimulus
            plot([0,0,stimdur*1000,stimdur*1000],[0,1,1,0],'r','LineWidth',2)
            % horizontal plot for 2*baseline
            plot([t_start,t_stop],[mean_baseline+2*std_baseline,mean_baseline+2*std_baseline],'k--')
            ylabel('firing rate [norm.]');

        else
            bar(bin_centers(resp_idx == 0), PSTH(resp_idx == 0), 'FaceColor',[0.5 0.5 0.5], 'EdgeColor', [0.5 0.5 0.5]);
            bar(bin_centers(resp_idx == 1), PSTH(resp_idx == 1), 'FaceColor', 'k', 'EdgeColor', 'k');
            ylabel('num of spikes');
       end   
        set(gca,'FontSize',16);
        xlim([t_start t_stop]);
        set(gca,'TickDir','out'); 
        xlabel('time [ms]')
        title(sprintf('%i MUs, %i recordings, %i animals: %.1f-%.1f ms',num_responsive_units,num_recordings,num_animals,t_onset,t_offset),Interpreter="none")
    end


end