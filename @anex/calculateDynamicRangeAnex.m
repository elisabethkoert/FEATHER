function [fig, dynamic_range,all_stimuli, all_stimuli_dB_re_oABR, all_spike_rates, all_dPrimes_Cum, all_dPrimes_Base] = calculateDynamicRangeAnex(ee,Exp_type,intensity_index_stimlist,stim_criteria_array,t_start,t_stop,plot_bool,filter_value)
    %anex/calculateDynamicRangeAnex calcualtes the dynmic range for all icmes
    %
    %
    % output
    % fig
    %
    % input:
    % ee: (anex) experiment from which to pool all IC recordings
    % Exp_type: (sting) name of the experiment as given in the UserInput table
    % intensity_index_stimlist: collumn in stim_list that contains the
    % intensity (eg. 1 for pulse stimuli, 4 for Mx_tones)
    % stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
    %      exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
    %      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
    % t_start: float/int start timepoint for histogram bins and also response time analysis
    % t_stop: float/int end of histogram bins/ analysis of spikerate
    % plot_bool: bool, decide if the figure should be created or if we only calculate the output values
    % filter value: string use if only one filter type should be included
    
    
    
    num_recordings=0;
    num_responsive_units=0;

    % get oABR threshold
    [ExpIntThrOptical] = intensityThreshold(ee, 'Optical');
    if ~isempty(ExpIntThrOptical)
        oABRThr=ExpIntThrOptical.IntensityThreshold;
    else
        oABRThr=[]; % for rel to 1 mW
    end
    [ExpIntThrIC] = intensityThresholdIC(ee,'increasingLvl',Exp_type);
%     [ExpIntThrIC] = intensityThresholdIC(ee,'baseline',Exp_type)
    if ~isempty(ExpIntThrIC)
        ICThr=ExpIntThrIC.thresholdIC;
    else
        ICThr=[]; % for rel to 1 mW
    end  


    if ~strcmp(Exp_type,'MX_tones') &&...
            ( isempty(ICThr) || isnan(oABRThr) || isempty(oABRThr) )
        fig=[];
        dynamic_range=[];
        all_stimuli=[];
        all_stimuli_dB_re_oABR=[];
        all_spike_rates=[];
        all_dPrimes_Cum=[];
        all_dPrimes_Base=[];
        return
    end
    % prepare saving structures
    stimuli_list={};
    SpikeRates_list={};
    dPrime_Cum_list={};
    dPrime_Base_list={};
    % load UT
    in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
    load(in_dir_name);%loads UT, containing user input and stimulus types for each icme
    L =listIcme(ee);
    for ii = 1: numel(L.IC_SeriesID)
        ix_in_UT= cellfun(@(x) strcmp( x ,string(L.IC_SeriesID(ii))),UT.data(:,find(contains(UT.fieldNames,'SeriesID'))));
        if ischar(UT.data{ix_in_UT,find(contains(UT.fieldNames,'d fiber'))})
            UT.data{ix_in_UT,find(contains(UT.fieldNames,'d fiber'))}=str2num(UT.data{ix_in_UT,find(contains(UT.fieldNames,'d fiber'))}); % not all UT Data tables have it saved as int
        end

        if strcmp(Exp_type,'MX_tones') &&...
            UT.data{ix_in_UT,find(contains(UT.fieldNames,'Use'))}== -1 || ~contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'ExpType'))},Exp_type) || contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'ExpType'))},'deaf') 
                continue
        elseif  ~strcmp(Exp_type,'MX_tones') && (UT.data{ix_in_UT,find(contains(UT.fieldNames,'Use'))}== -1 || ~contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'ExpType'))},Exp_type) || contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'ExpType'))},'deaf') ||...
                (~contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'pos cochlea'))},'RW') &&~contains(UT.data{ix_in_UT,find(contains(UT.fieldNames,'pos cochlea'))},'bas')) ||...
                (UT.data{ix_in_UT,find(contains(UT.fieldNames,'d fiber'))})~=200) %fiber diameter
                continue
        end
        if exist('filter_value','var')
            if str2num(UT.data{ix_in_UT,find(contains(UT.fieldNames,'Filter'))})~=filter_value
                continue
            end
        end
        IC=loadIcme(icme(ee,string(L.IC_SeriesID(ii))));
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
        % get responsive units
        elecs = getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop);%1:1:32;%
        if ~isempty(elecs)
            stimuli=OBJ_stimlist(stim_ID,intensity_index_stimlist);
            stimuli_list{end+1}=stimuli;
            [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,t_start,t_stop); % get spikerates
            SpikeRates_list{end+1}=meanSpikeRates(elecs,stim_ID);
            d_prime_results = calculateDprime(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
            dPrime_Cum_list{end+1}=d_prime_results.all_Dprime_cumsum(elecs,:);
            d_prime_results = calculateDprime(IC,'baseline',stim_criteria_array,t_start,t_stop);
            dPrime_Base_list{end+1}=d_prime_results.all_Dprime_array(elecs,:);
            num_responsive_units=num_responsive_units+length(elecs);
            num_recordings=num_recordings+1;
        end
        
    end       
    

    %% if empty return
    if isempty(stimuli_list) % return emtpy figure
        fig=[];
        dynamic_range=[];
        all_stimuli=[];
        all_stimuli_dB_re_oABR=[];
        all_spike_rates=[];
        all_dPrimes_Cum=[];
        all_dPrimes_Base=[];
        return
    end

    
   % join up stimuli info for that animal
   all_stimuli=unique(vertcat(stimuli_list{:}));
   all_stimuli_dB_re_oABR=10*log10(all_stimuli/oABRThr);
   all_stimuli_dB_re_1mW=10*log10(all_stimuli/1);
   all_spike_rates=NaN(num_responsive_units ,length(all_stimuli));
   all_dPrimes_Cum=NaN(num_responsive_units ,length(all_stimuli));
   all_dPrimes_Base=NaN(num_responsive_units ,length(all_stimuli));
   start_ix=1;
   for kk=1:num_recordings
        stimuli_now=stimuli_list{kk};
        Spike_rates_now=SpikeRates_list{kk};
        d_primes_cum_now=dPrime_Cum_list{kk};
        d_primes_base_now=dPrime_Base_list{kk};
        n_Muas_now=size(Spike_rates_now,1);
        [~, indices] = ismember(stimuli_now, all_stimuli);
        all_spike_rates(start_ix:start_ix+n_Muas_now-1,indices)=Spike_rates_now;
        all_dPrimes_Cum(start_ix:start_ix+n_Muas_now-1,indices(2:end))=d_primes_cum_now;
        all_dPrimes_Base(start_ix:start_ix+n_Muas_now-1,indices)=d_primes_base_now;
        start_ix=start_ix+n_Muas_now;
   end
  
   
   % spike rate 10 percent to 90 perc
   SR_change=max(mean(all_spike_rates,'omitnan'))-min(mean(all_spike_rates,'omitnan'));
   value_90_per_max_SR=min(mean(all_spike_rates,'omitnan'))+0.9*SR_change;
   value_10_per_max_SR=min(mean(all_spike_rates,'omitnan'))+0.1*SR_change;
   [~,ix_90_per_max_SR]=min(abs(mean(all_spike_rates,'omitnan')-value_90_per_max_SR));
   [~,ix_10_per_max_SR]=min(abs(mean(all_spike_rates,'omitnan')-value_10_per_max_SR));
   if ix_10_per_max_SR==1
       ix_10_per_max_SR=2; % if the very first with 0 mW is the closest to +10 % this will cause problems in the log scale
   end
   % d' cum ==1
   [~,ix_dPrime_cum_1]=min(abs(mean(all_dPrimes_Cum,'omitnan')-1));
   [~,ix_dPrime_base_1]=min(abs(mean(all_dPrimes_Base,'omitnan')-1));

    

   % calculate dynamic ranges
   dynamic_range=struct();
   dynamic_range.SR_10perc_to_90_perc_dB_rel_oABR_thr=all_stimuli_dB_re_oABR(ix_90_per_max_SR)-all_stimuli_dB_re_oABR(ix_10_per_max_SR);
  dynamic_range.SR_10perc_to_90_perc=all_stimuli(ix_90_per_max_SR)-all_stimuli(ix_10_per_max_SR);

   % same value for IC since it is just a different axis
    % dynamic_range.SR_10perc_to_90_perc_dB_rel_IC_thr=all_stimuli_dB_re_IC(ix_90_per_max_SR)-all_stimuli_dB_re_IC(ix_10_per_max_SR);
    dynamic_range.dPrimeCum1_to_90_perc_SR_dB_rel_oABR_thr=all_stimuli_dB_re_oABR(ix_90_per_max_SR)-all_stimuli_dB_re_oABR(ix_dPrime_cum_1);
    dynamic_range.dPrimeCum1_to_90_perc_SR=all_stimuli(ix_90_per_max_SR)-all_stimuli(ix_dPrime_cum_1);

    dynamic_range.dPrimeBase1_to_90_perc_SR_dB_rel_oABR_thr=all_stimuli_dB_re_oABR(ix_90_per_max_SR)-all_stimuli_dB_re_oABR(ix_dPrime_base_1);
    dynamic_range.dPrimeBase1_to_90_perc_SR=all_stimuli(ix_90_per_max_SR)-all_stimuli(ix_dPrime_base_1);

    dynamic_range.oABR_thr=oABRThr;
    dynamic_range.IC_thr=ICThr;
    


    %% plot figure
    if plot_bool==1
        fig=figure;
        subplot(3,2,1)
        hold on
        for y_ix=1:num_responsive_units
            y=all_spike_rates(y_ix,:);
            plot(all_stimuli(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli(1),all_stimuli(end)],[value_90_per_max_SR,value_90_per_max_SR],'k--')
        plot([all_stimuli(1),all_stimuli(end)],[value_10_per_max_SR,value_10_per_max_SR],'k--')
        errorbar(all_stimuli,mean(all_spike_rates,'omitnan'),std(all_spike_rates,'omitnan'))
        xlabel('intensity [mW]')
        ylabel('spike rate [Hz]')
        hold off
        
        % SR vs Intensity (dB rel oABR threshold)
        subplot(3,2,2)
        hold on
        for y_ix=1:num_responsive_units
            y=all_spike_rates(y_ix,:);
            plot(all_stimuli_dB_re_oABR(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_re_oABR(2),all_stimuli_dB_re_oABR(end)],[value_90_per_max_SR,value_90_per_max_SR],'k--')
        plot([all_stimuli_dB_re_oABR(2),all_stimuli_dB_re_oABR(end)],[value_10_per_max_SR,value_10_per_max_SR],'k--')
        errorbar(all_stimuli_dB_re_oABR,mean(all_spike_rates,'omitnan'),std(all_spike_rates,'omitnan'))
        xlabel('intensity [dB re oABR thr.]')
%         xlim([-20 10])
        ylabel('spike rate [Hz]')
        title(sprintf('DR 10-90SR: %.2f [dB rel oABR]',dynamic_range.SR_10perc_to_90_perc_dB_rel_oABR_thr))
        hold off

        % d' cum vs mW
        subplot(3,2,3)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Cum(y_ix,:);
            plot(all_stimuli(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli(1),all_stimuli(end)],[1,1],'k--')
        errorbar(all_stimuli,mean(all_dPrimes_Cum,'omitnan'),std(all_dPrimes_Cum,'omitnan'))
        xlabel('intensity [mW]')
        ylabel("cumulative d'")
        ylim([-1 4])
        hold off
        
        % d' cum (dB rel oABR threshold)
        subplot(3,2,4)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Cum(y_ix,:);
            plot(all_stimuli_dB_re_oABR(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_re_oABR(2),all_stimuli_dB_re_oABR(end)],[1,1],'k--')
        errorbar(all_stimuli_dB_re_oABR,mean(all_dPrimes_Cum,'omitnan'),std(all_dPrimes_Cum,'omitnan'))
        xlabel('intensity [dB re oABR thr.]')
        title(sprintf('DR cdp1-90SR: %.2f [dB rel oABR]',dynamic_range.dPrimeCum1_to_90_perc_SR_dB_rel_oABR_thr))
%         xlim([-20 10])
        ylabel("cumulative d'")
        ylim([-1 4])
        hold off

         % d' baseline vs mW
        subplot(3,2,5)
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
        subplot(3,2,6)
        hold on
        for y_ix=1:num_responsive_units
            y=all_dPrimes_Base(y_ix,:);
            plot(all_stimuli_dB_re_oABR(~isnan(y)),y(~isnan(y)),'Color',[0.7,0.7,0.7],'HandleVisibility','off')
        end
        plot([all_stimuli_dB_re_oABR(2),all_stimuli_dB_re_oABR(end)],[1,1],'k--')
        errorbar(all_stimuli_dB_re_oABR,mean(all_dPrimes_Base,'omitnan'),std(all_dPrimes_Base,'omitnan'))
        xlabel('intensity [dB re oABR thr.]')
        title(sprintf('DR bdp1-90SR: %.2f [dB rel oABR]',dynamic_range.dPrimeBase1_to_90_perc_SR_dB_rel_oABR_thr))
%         xlim([-20 10])
        ylabel("d' to baseline")
        ylim([-1 4])
        hold off
        sgtitle(sprintf('%s %i MUs, %i recordings',ee.ExpID,num_responsive_units,num_recordings))
        fig.Position= [680         248        1115         730];
    else
        fig=[];
    end


end