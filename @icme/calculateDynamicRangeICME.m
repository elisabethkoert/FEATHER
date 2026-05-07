function [fig, dynamic_range,all_stimuli, all_stimuli_dB_logScale, all_spike_rates,all_evoked_spike_rates, all_dPrimes_Cum, all_dPrimes_Base] = calculateDynamicRangeICME(IC,intensity_index_stimlist,stim_criteria_array,t_start,t_stop,plot_bool,ValueForLogScaling)
    %icme/calculateDynamicRangeICME calcualtes the dynamic range for an IC
    % based on the mean spike rate for all responsive electrodes over a
    % range of intensities
    % input:
    %   IC (icme): IC recording to analyse
    %   intensity_index_stimlist (int): collumn in stim_list that containsthe  intensity (eg. 1 for pulse stimuli, 4 for Mx_tones)
    %   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
    %      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
    %      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
    %   t_start: float/int start timepoint for histogram bins and also response time analysis
    %   t_stop: float/int end of histogram bins/ analysis of spikerate
    %   plot_bool: bool, decide if the figure should be created or if we only calculate the output values
    % output:
    %   fig (if plot bool is 1,else []) contains the plots for spike rate, cumulative
    %       d' and d' to baseline across all used intensities as well as
    %       for the intensities rel to 1mW
    %   dynamic_range (struct) containing 3 types of DR measurements all
    %       relative to 1 mW
    %       SR_10perc_to_90_perc_dB_logScale  (intensity range to get from
    %           10 % to 90 % of the max spike rate rel. to 1 mW on a log scale)
    %       dPrimeCum1_to_90_perc_SR_dB_logScale (intensity range to get from
    %           d' cum =1 threhsold to to 90 % of the max spike rate rel. to 1 mW, log scale)  
    %       dPrimeBase1_to_90_perc_SR_dB_logScale  (intensity range to get from
    %           d' baseline =1 threshold to 90 % of the max spike rate rel. to 1 mW, log scale)
    %       ValueForLogScaling (double) : value to get from lin. intensity
    %           range to log scale (default 1)
    %       SR_10perc_to_90_perc  (intensity range to get from
    %           10 % to 90 % of the max spike rate)
    %       dPrimeCum1_to_90_perc_SR (intensity range to get from
    %           d' cum =1 threhsold to to 90 % of the max spike rate)  
    %       dPrimeBase1_to_90_perc_SR  (intensity range to get from
    %           d' baseline =1 threshold to 90 % of the max spike rate)
    %   all_stimuli (nx1 double) list of used intensities
    %   all_stimuli_dB_logScale (nx1 doubel) list of intensities re. 1 mW
    %   all_spike_rates (num_responsive_elecs x n) of detected spikeratesfor all
    %       responsive units and stimuli
    %   all_dPrimes_Cum (num_responsive_elecs x n) of cum d' values for all
    %       responsive units and stimuli
    %   all_dPrimes_Base (num_responsive_elecs x n)of baseline d' values for all
    %       responsive units and stimuli
        
    
    
    % check if the calibrated Stimlist exists
    if isfield(IC.C,'stimlistCal')
        OBJ_stimlist=IC.C.stimlistCal;
    else
        OBJ_stimlist=IC.Stim.stimlist;
    end
    % get the Stim_ID for the wanted range of stimuli
    stim_ID=1:1:length(OBJ_stimlist(:,1));
    for jj=1:size(stim_criteria_array,1)
        stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
        stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
        stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
        stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
    end
     % check if you have any double presentations of stimuli and remove
     % them
    changing_var_all=OBJ_stimlist(stim_ID, intensity_index_stimlist); 
    [~, indices_unique, ~] = unique(changing_var_all);
    stim_ID=stim_ID(indices_unique);

    % get responsive units
    elecs = getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop);
    % if empty return
    if isempty(elecs) % return emtpy figure
        fig=[];
        dynamic_range=[];
        all_stimuli=[];
        all_stimuli_dB_logScale=[];
        all_spike_rates=[];
        all_evoked_spike_rates=[];
        all_dPrimes_Cum=[];
        all_dPrimes_Base=[];
        return
    end


    stimuli=OBJ_stimlist(stim_ID,intensity_index_stimlist);
    [all_stimuli,indices,~]=unique(stimuli);
    [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,t_start,t_stop); % get spikerates
    all_spike_rates= meanSpikeRates(elecs,stim_ID);
    [all_evoked_spike_rate] = calculateEvokedSpikeRate(IC,stim_criteria_array, t_start,t_stop );
    all_evoked_spike_rates=all_evoked_spike_rate.meanEvokedSpikeRate(elecs,:);
    d_prime_results = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
    all_dPrimes_Cum=d_prime_results{1}.all_Dprime_cumsum(elecs,:);
    d_prime_results = calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
    all_dPrimes_Base=d_prime_results{1}.all_Dprime_array(elecs,:);
    num_responsive_units=length(elecs);

  
   % get d' =1 indices
   [~,ix_dPrime_cum_1]=min(abs(mean(all_dPrimes_Cum,1,'omitnan')-1));
   [~,ix_dPrime_base_1]=min(abs(mean(all_dPrimes_Base,'omitnan')-1));
   
    % check if value for log scaling was given as input, otherwise take d'
    % baseline =1 threshold
    if ~exist('ValueForLogScaling')
             ValueForLogScaling = all_stimuli(ix_dPrime_base_1); % 1 mW for 
    end

   if contains(IC.Stim.exp_type,'eCI')
    all_stimuli_dB_logScale=20*log10(all_stimuli/ValueForLogScaling);
   else
     all_stimuli_dB_logScale=10*log10(all_stimuli/ValueForLogScaling);
   end


   % mean spike rate over all electrodes per intensity, then get 10-90 %SR
   % change for DR
   SR_change_mean_all_elecs=max(mean(all_spike_rates,1,'omitnan'))-min(mean(all_spike_rates,1,'omitnan'));
   value_90_per_max_SR=min(mean(all_spike_rates,1,'omitnan'))+0.9*SR_change_mean_all_elecs;
   value_10_per_max_SR=min(mean(all_spike_rates,1,'omitnan'))+0.1*SR_change_mean_all_elecs;
   [~,ix_90_per_max_SR]=min(abs(mean(all_spike_rates,1,'omitnan')-value_90_per_max_SR));
   [~,ix_10_per_max_SR]=min(abs(mean(all_spike_rates,1,'omitnan')-value_10_per_max_SR));
   if ix_10_per_max_SR==1
       ix_10_per_max_SR=2; % if the very first with 0 mW is the closest to +10 % this will cause problems in the log scale
   end

   % absolute spike rate chooses for each intensity the max value from the highest responding electrode
   % measures DR as 10 percent to 90 perc of this absolute SR
   SR_change_max_elec=max(max(all_spike_rates,[],1))-min(max(all_spike_rates,[],1));
   value_90_per_max_SR_abs=min(max(all_spike_rates,[],1))+0.9*SR_change_max_elec;
   value_10_per_max_SR_abs=min(max(all_spike_rates,[],1))+0.1*SR_change_max_elec;
   [~,ix_90_per_max_SR_abs]=min(abs(max(all_spike_rates,[],1)-value_90_per_max_SR_abs));
   [~,ix_10_per_max_SR_abs]=min(abs(max(all_spike_rates,[],1)-value_10_per_max_SR_abs));
   if ix_10_per_max_SR_abs==1
       ix_10_per_max_SR_abs=2; % if the very first with 0 mW is the closest to +10 % this will cause problems in the log scale
   end

   % mean EVOKED spike rate over all electrodes per intensity, then get 10-90 %SR
   % change for DR
   eSR_change_mean_all_elecs=max(mean(all_evoked_spike_rates,1,'omitnan'))-min(mean(all_evoked_spike_rates,1,'omitnan'));
   value_90_per_max_eSR=min(mean(all_evoked_spike_rates,1,'omitnan'))+0.9*eSR_change_mean_all_elecs;
   value_10_per_max_eSR=min(mean(all_evoked_spike_rates,1,'omitnan'))+0.1*eSR_change_mean_all_elecs;
   [~,ix_90_per_max_eSR]=min(abs(mean(all_evoked_spike_rates,1,'omitnan')-value_90_per_max_eSR));
   [~,ix_10_per_max_eSR]=min(abs(mean(all_evoked_spike_rates,1,'omitnan')-value_10_per_max_eSR));
   if ix_10_per_max_eSR==1
       ix_10_per_max_eSR=2; % if the very first with 0 mW is the closest to +10 % this will cause problems in the log scale
   end

   % absolute EVOKED spike rate chooses for each intensity the max value from the highest responding electrode
   % measures DR as 10 percent to 90 perc of this absolute eSR
   eSR_change_max_elec=max(max(all_evoked_spike_rates,[],1))-min(max(all_evoked_spike_rates,[],1));
   value_90_per_max_eSR_abs=min(max(all_evoked_spike_rates,[],1))+0.9*eSR_change_max_elec;
   value_10_per_max_eSR_abs=min(max(all_evoked_spike_rates,[],1))+0.1*eSR_change_max_elec;
   [~,ix_90_per_max_eSR_abs]=min(abs(max(all_evoked_spike_rates,[],1)-value_90_per_max_eSR_abs));
   [~,ix_10_per_max_eSR_abs]=min(abs(max(all_evoked_spike_rates,[],1)-value_10_per_max_eSR_abs));
   if ix_10_per_max_eSR_abs==1
       ix_10_per_max_eSR_abs=2; % if the very first with 0 mW is the closest to +10 % this will cause problems in the log scale
   end


   % calculate dynamic ranges
   dynamic_range=struct();
   dynamic_range.ValueForLogScaling=ValueForLogScaling;
   % SR mean over all electrodes:
   % in DB
   dynamic_range.SR_10perc_to_90_perc_dB_logScale=all_stimuli_dB_logScale(ix_90_per_max_SR)-all_stimuli_dB_logScale(ix_10_per_max_SR);
   dynamic_range .dPrimeCum1_to_90_perc_SR_dB_logScale=all_stimuli_dB_logScale(ix_90_per_max_SR)-all_stimuli_dB_logScale(ix_dPrime_cum_1);
   dynamic_range.dPrimeBase1_to_90_perc_SR_dB_logScale=all_stimuli_dB_logScale(ix_90_per_max_SR)-all_stimuli_dB_logScale(ix_dPrime_base_1);
    % in absoulte values
   dynamic_range.SR_10perc_to_90_perc=all_stimuli(ix_90_per_max_SR)-all_stimuli(ix_10_per_max_SR);
   dynamic_range.dPrimeCum1_to_90_perc_SR=all_stimuli(ix_90_per_max_SR)-all_stimuli(ix_dPrime_cum_1);
   dynamic_range.dPrimeBase1_to_90_perc_SR=all_stimuli(ix_90_per_max_SR)-all_stimuli(ix_dPrime_base_1);
   % SR taken from max electrode per intensity
   dynamic_range.SR_10perc_to_90_perc_dB_logScale_absolute=all_stimuli_dB_logScale(ix_90_per_max_SR_abs)-all_stimuli_dB_logScale(ix_10_per_max_SR_abs);
   dynamic_range.SR_10perc_to_90_perc_absolute=all_stimuli(ix_90_per_max_SR_abs)-all_stimuli(ix_10_per_max_SR_abs);
    
    % evoked SR mean over all electrodes:
   % in DB
   dynamic_range.eSR_10perc_to_90_perc_dB_logScale=all_stimuli_dB_logScale(ix_90_per_max_eSR)-all_stimuli_dB_logScale(ix_10_per_max_eSR);
   dynamic_range .dPrimeCum1_to_90_perc_eSR_dB_logScale=all_stimuli_dB_logScale(ix_90_per_max_eSR)-all_stimuli_dB_logScale(ix_dPrime_cum_1);
   dynamic_range.dPrimeBase1_to_90_perc_eSR_dB_logScale=all_stimuli_dB_logScale(ix_90_per_max_eSR)-all_stimuli_dB_logScale(ix_dPrime_base_1);
    % in absoulte values
   dynamic_range.eSR_10perc_to_90_perc=all_stimuli(ix_90_per_max_eSR)-all_stimuli(ix_10_per_max_eSR);
   dynamic_range.dPrimeCum1_to_90_perc_eSR=all_stimuli(ix_90_per_max_eSR)-all_stimuli(ix_dPrime_cum_1);
   dynamic_range.dPrimeBase1_to_90_perc_eSR=all_stimuli(ix_90_per_max_eSR)-all_stimuli(ix_dPrime_base_1);
   % SR taken from max electrode per intensity
   dynamic_range.eSR_10perc_to_90_perc_dB_logScale_absolute=all_stimuli_dB_logScale(ix_90_per_max_eSR_abs)-all_stimuli_dB_logScale(ix_10_per_max_eSR_abs);
   dynamic_range.eSR_10perc_to_90_perc_absolute=all_stimuli(ix_90_per_max_eSR_abs)-all_stimuli(ix_10_per_max_eSR_abs);


    %% plot figure
    if plot_bool==1
        fig=figure;
        subplot(4,2,1)
        hold on
        for y_ix=1:num_responsive_units
            y=all_spike_rates(y_ix,:);
            plot(all_stimuli(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli(1),all_stimuli(end)],[value_90_per_max_SR,value_90_per_max_SR],'k--')
        plot([all_stimuli(1),all_stimuli(end)],[value_10_per_max_SR,value_10_per_max_SR],'k--')
        errorbar(all_stimuli,mean(all_spike_rates,1,'omitnan'),std(all_spike_rates,'omitnan'),'b')
        % add what happens with the absolute SR
        plot(all_stimuli,max(all_spike_rates,[],1),'r')
         plot([all_stimuli(1),all_stimuli(end)],[value_90_per_max_SR_abs,value_90_per_max_SR_abs],'r--')
        plot([all_stimuli(1),all_stimuli(end)],[value_10_per_max_SR_abs,value_10_per_max_SR_abs],'r--')
        xlabel('intensity [mW]')
        ylabel('spike rate [Hz]')
        title(sprintf('DR 10-90 mean SR: %.1f,max SR: %.1f [dB]',dynamic_range.SR_10perc_to_90_perc,dynamic_range.SR_10perc_to_90_perc_absolute))
        hold off
        
        % SR vs Intensity (dB rel oABR threshold)
        subplot(4,2,2)
        hold on
        for y_ix=1:num_responsive_units
            y=all_spike_rates(y_ix,:);
            plot(all_stimuli_dB_logScale(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_90_per_max_SR,value_90_per_max_SR],'k--')
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_10_per_max_SR,value_10_per_max_SR],'k--')
        errorbar(all_stimuli_dB_logScale,mean(all_spike_rates,1,'omitnan'),std(all_spike_rates,'omitnan'),'b')
        % add what happens with the absolute SR
        plot(all_stimuli_dB_logScale,max(all_spike_rates,[],1),'r')
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_90_per_max_SR_abs,value_90_per_max_SR_abs],'r--')
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_10_per_max_SR_abs,value_10_per_max_SR_abs],'r--')
        xlabel(sprintf('intensity [dB re %.1f]',ValueForLogScaling))
%         xlim([-20 10])
        ylabel('spike rate [Hz]')
        title(sprintf('DR 10-90 mean SR: %.1f [dB],max SR: %.1f [dB]',dynamic_range.SR_10perc_to_90_perc_dB_logScale,dynamic_range.SR_10perc_to_90_perc_dB_logScale_absolute))
        hold off

        % evoked SR
        subplot(4,2,3)
        hold on
        for y_ix=1:num_responsive_units
            y=all_evoked_spike_rates(y_ix,:);
            plot(all_stimuli(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli(1),all_stimuli(end)],[value_90_per_max_eSR,value_90_per_max_eSR],'k--')
        plot([all_stimuli(1),all_stimuli(end)],[value_10_per_max_eSR,value_10_per_max_eSR],'k--')
        errorbar(all_stimuli,mean(all_evoked_spike_rates,1,'omitnan'),std(all_evoked_spike_rates,'omitnan'),'b')
        % add what happens with the absolute SR
        plot(all_stimuli,max(all_evoked_spike_rates,[],1),'r')
         plot([all_stimuli(1),all_stimuli(end)],[value_90_per_max_eSR_abs,value_90_per_max_eSR_abs],'r--')
        plot([all_stimuli(1),all_stimuli(end)],[value_10_per_max_eSR_abs,value_10_per_max_eSR_abs],'r--')
        xlabel('intensity [mW]')
        ylabel('evoked spike rate [Hz]')
        title(sprintf('DR 10-90 mean eSR: %.1f,max SR: %.1f [dB]',dynamic_range.eSR_10perc_to_90_perc,dynamic_range.eSR_10perc_to_90_perc_absolute))
        hold off
        
        % eSR vs Intensity (dB)
        subplot(4,2,4)
        hold on
        for y_ix=1:num_responsive_units
            y=all_evoked_spike_rates(y_ix,:);
            plot(all_stimuli_dB_logScale(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_90_per_max_eSR,value_90_per_max_eSR],'k--')
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_10_per_max_eSR,value_10_per_max_eSR],'k--')
        errorbar(all_stimuli_dB_logScale,mean(all_evoked_spike_rates,1,'omitnan'),std(all_evoked_spike_rates,'omitnan'),'b')
          % add what happens with the absolute SR
        plot(all_stimuli_dB_logScale,max(all_evoked_spike_rates,[],1),'r')
         plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_90_per_max_eSR_abs,value_90_per_max_eSR_abs],'r--')
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[value_10_per_max_eSR_abs,value_10_per_max_eSR_abs],'r--')
        xlabel(sprintf('intensity [dB re %.1f]',ValueForLogScaling))
%         xlim([-20 10])
        ylabel('evoked spike rate [Hz]')
        title(sprintf('DR 10-90 mean eSR: %.1f [dB],max SR: %.1f [dB]',dynamic_range.eSR_10perc_to_90_perc_dB_logScale,dynamic_range.eSR_10perc_to_90_perc_dB_logScale_absolute))
        hold off

        % d' cum vs mW
        subplot(4,2,5)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Cum(y_ix,:);
            plot(all_stimuli(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli(1),all_stimuli(end)],[1,1],'k--')
        errorbar(all_stimuli(1:end-1),mean(all_dPrimes_Cum,1,'omitnan'),std(all_dPrimes_Cum,'omitnan'),'b')
        xlabel('intensity [mW]')
        ylabel("cumulative d'")
        ylim([-1 4])
        hold off
        
        % d' cum (dB rel oABR threshold)
        subplot(4,2,6)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Cum(y_ix,:);
            plot(all_stimuli_dB_logScale(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[1,1],'k--')
        errorbar(all_stimuli_dB_logScale(1:end-1),mean(all_dPrimes_Cum,1,'omitnan'),std(all_dPrimes_Cum,'omitnan'),'b')
        xlabel(sprintf('intensity [dB re %.1f]',ValueForLogScaling))
        title(sprintf('DR cdp1-90SR: %.2f [dB rel 1 mW]',dynamic_range.dPrimeCum1_to_90_perc_SR_dB_logScale))
%         xlim([-20 10])
        ylabel("cumulative d'")
        ylim([-1 4])
        hold off

         % d' baseline vs mW
        subplot(4,2,7)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Base(y_ix,:);
            plot(all_stimuli(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli(1),all_stimuli(end)],[1,1],'k--')
        errorbar(all_stimuli,mean(all_dPrimes_Base,'omitnan'),std(all_dPrimes_Base,'omitnan'))
        xlabel('intensity [mW]')
        ylabel("d' to baseline")
        ylim([-1 4])

        hold off
        
        % SR vs Intensity (dB rel oABR threshold)
        subplot(4,2,8)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Base(y_ix,:);
            plot(all_stimuli_dB_logScale(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_logScale(2),all_stimuli_dB_logScale(end)],[1,1],'k--')
        errorbar(all_stimuli_dB_logScale,mean(all_dPrimes_Base,'omitnan'),std(all_dPrimes_Base,'omitnan'))
        xlabel(sprintf('intensity [dB re %.1f]',ValueForLogScaling))
        title(sprintf('DR bdp1-90SR: %.2f [dB rel 1mW]',dynamic_range.dPrimeBase1_to_90_perc_SR_dB_logScale))
%         xlim([-20 10])
        ylabel("d' to baseline")
        ylim([-1 4])
        hold off
        sgtitle(sprintf('%s %i MUs',IC.SeriesID,num_responsive_units),'interpreter','none')
        fig.Position= [680         248        1115         730];
    else
        fig=[];
    end


end