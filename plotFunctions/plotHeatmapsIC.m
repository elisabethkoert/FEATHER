function fig= plotHeatmapsIC(IC, mode, stim_criteria_array,t_start,t_stop)
% icme/plotHeatmapsIC this function plots the standard heatmaps for individual ICME
% this includes Spiekrate Plots (bad electrodes are set to 0 Hz)
% and d' plots (increasing Lvl as well as baseline calculation)
% input:
%   IC (icme) IC recording ICect, 
%   mode (str) 
%       'SR', 
%       'dPrimeCum'
%       dPrimeCum_contour
%       'dPrimeBaseline'    
%       'SR_MSV' (multiple_stim_variables: makes multiple plots for a fixed parameter descibed in the second row of the stim_criteria array)   
%       'dPrimeCum_MSV' 
%       'dPrimeBaseline_MSV'
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the x axis/sorted parameter for increasinglvl will be the property described in the first row
%      exp. [4,50,90;1,1000,1000] a 1000 Hz pure tone btw 1000 and 32000 Hz with
%      50-90 dB (increasing lvl)
%      exp.  [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
%   t_start (double) start of timewindow in which to extract the spike rate
%   t_stop (double) stop of time window in which to analysie the spike rate
% outputIC
%   fig

if ~exist('t_start') & ~exist('t_stop')
    t_start = 0;% time before and after a trigger that is supposed to be investigated
    t_stop = 50; % default 50 ms after trigger
end

 % % try if the calibrated Stimlist exists
if isfield(IC.C,'stimlistCal')
    OBJ_stimlist=IC.C.stimlistCal;
else
    OBJ_stimlist=IC.Stim.stimlist;
end



% figure out which stimuli are investigated
stim_ID=1:1:length(OBJ_stimlist(:,1));
for jj=1:size(stim_criteria_array,1)
    stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
    stim_ID = stim_ID(ismember(stim_ID, stim_ID_1));
    stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
    stim_ID = stim_ID(ismember(stim_ID, stim_ID_2));
end

% get x_labels & values
if contains(IC.Stim.exp_type,'OBIS_LS594_PulseTrain') & stim_criteria_array(1,1)==1 
        x_label = 'Laser intensity [mW]'; % this one is saved badly in stim_header
else
    try
    x_label=IC.Stim.stimheader{stim_criteria_array(1,1)};
    catch
        x_label='empty'
    end
end

x_values=unique(OBJ_stimlist(stim_ID,stim_criteria_array(1,1)),'stable');

if ~isfield(IC.C,'stimlistCal')
     x_label=[x_label ' (wo. calib)'];
end
% replace _ with spaces
x_label=strrep(x_label,'_',' ');

all_electrodes=IC.SL.all_electrodes;

if strcmp(mode,'SR')
    [meanSpikeRates, ~]  = calculateSpikeRate(IC, t_start,t_stop);
    % limit to only needed stimuli
    meanSpikeRates=meanSpikeRates(:,stim_ID);

    % Heatmap of spike rate
    % sort x values
    [x_values,sorting_ixs]=sort(x_values);

    fig = nonuniformHM(x_values',(all_electrodes+1)',meanSpikeRates(:,sorting_ixs));
    title(fig.Children(1),"Spike Rate [Hz]")
    colormap("parula")
    % Set the colormap limits
    caxisLimits = [0; max(max(meanSpikeRates))]; % Example limits
    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel(x_label)
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32])
    set(gca,'XTick',x_values,'XTickLabel',x_values)

elseif strcmp(mode,'dPrimeCum')
    d_prime_results= calculateDprimeMultipleStimVars(IC,'increasingLvl', stim_criteria_array,t_start,t_stop);
    all_Dprimes_cumsum= d_prime_results{1}.all_Dprime_cumsum;
      % sort x values
    [x_values,sorting_ixs]=sort(x_values);
    % d' cumsum values plot
    fig = nonuniformHM(x_values(2:end)',(all_electrodes+1)',all_Dprimes_cumsum(:,sorting_ixs((2:end)-1)));
    title(fig.Children(1),['cum. d' sprintf( '\''' ) ])
    colormap(parula(2*ceil(max(max(all_Dprimes_cumsum)))))
    % Set the colormap limits
    caxisLimits = [0, ceil(max(max(all_Dprimes_cumsum)))]; % Example limits
    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel(x_label)
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32])
    set(gca,'XTick',x_values,'XTickLabel',x_values)
elseif strcmp(mode,'dPrimeBase_contour')
    d_prime_results= calculateDprimeMultipleStimVars(IC,'baseline', stim_criteria_array,t_start,t_stop);
    all_Dprimes= d_prime_results{1}.all_Dprime_array;
    % exclude impossible stimuli from plotting
    if isfield('impossibleStimuli',IC.C) % only works after calibration files have been checked in analysis
        if ~isempty(IC.C.impossibleStimuli)
            if IC.C.impossibleStimuli ~=1 % first one is not included anyway
                x_values(IC.C.impossibleStimuli)=[];
                all_Dprimes(:,IC.C.impossibleStimuli-1)=[];
            end
        end
    end
    % d' cumsum values plot
    analyzed_d_prime_array=[-1:0.5:ceil(max(max(all_Dprimes)))];
    fig = figure();
    hold on
    all_contourlines=cell(size(analyzed_d_prime_array));
    ContourMatrix=contourf(all_Dprimes,[-1:0.5:ceil(max(max(all_Dprimes)))]);


    %separate into inidividual contourlines and save according to
       % dPrime value
        ix=1;
        while ix<size(ContourMatrix,2)
            dPrime_level=ContourMatrix(1,ix);
            num_of_points=ContourMatrix(2,ix);
            contour_points=ContourMatrix(:,ix+1:ix+num_of_points);
%             fprintf('contour line for dPrime:%.1f with %i points \n',dPrime_level,num_of_points)
            % check if contourline is closed 
            if all(contour_points(:,1)==contour_points(:,end))
%                 fprintf('closed\n')
            else % only save non closed lines
                analyzed_d_prime_ix=find(analyzed_d_prime_array==dPrime_level);
                if ~isempty(analyzed_d_prime_ix)
                    [value,ii]=min(contour_points(1,:));
                    helper.contour_points=contour_points;
                    helper.threshold=contour_points(:,ii);
                    all_contourlines{analyzed_d_prime_ix}{end+1}=helper;
                end
            end
            ix=ix+num_of_points+1;
        end
    
    % Set the colormap limits
    colormap(parula())
    caxisLimits = [0, ceil(max(max(all_Dprimes)))]; % Example limits
    colorbar()
    title(fig.Children(1),['d' sprintf( '\''' ) ])

    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
%     plot threshholds and contour lines for d'1,2,3
        colormarkers={':w','--w','-.w'};
        colormarkersk={':k','--k','-.k'};
        hs=[];
        for d_prime_i=[1,2,3]
            d_prime_pos=find(d_prime_i==analyzed_d_prime_array);
            if ~isempty(d_prime_pos)
                Cur_contourlines=all_contourlines{d_prime_pos};
                % check if the contour is a circle
                if ~isempty(Cur_contourlines) 
                    for kk=1:length(Cur_contourlines)
                        points= Cur_contourlines{kk}.contour_points;
                        plot( points(1,:),points(2,:),colormarkers{d_prime_i}, 'linewidth', 3)
                    end
                    hs(d_prime_i)=plot( 1,1,colormarkersk{d_prime_i}, 'linewidth', 3,'DisplayName',sprintf("d'=%i",d_prime_i));
                end
            end
        end
    lg=legend(hs,'Location','northwest','TextColor','k');
   
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel(x_label)
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')
    set(gca,'XTick',0:1:length(x_values),'XTickLabel',x_values)
elseif strcmp(mode,'dPrimeCum_contour')
    d_prime_results= calculateDprimeMultipleStimVars(IC,'increasingLvl', stim_criteria_array,t_start,t_stop);
    all_Dprimes_cumsum= d_prime_results{1}.all_Dprime_cumsum;
    % exclude impossible stimuli from plotting
    if isfield('impossibleStimuli',IC.C) % only works after calibration files have been checked in analysis
        if ~isempty(IC.C.impossibleStimuli)
            if IC.C.impossibleStimuli ~=1 % first one is not included anyway
                x_values(IC.C.impossibleStimuli)=[];
                all_Dprimes_cumsum(:,IC.C.impossibleStimuli-1)=[];
            end
        end
    end
    % d' cumsum values plot
    analyzed_d_prime_array=[-1:0.5:ceil(max(max(all_Dprimes_cumsum)))];
    fig = figure();
    hold on
    all_contourlines=cell(size(analyzed_d_prime_array));
    ContourMatrix=contourf(all_Dprimes_cumsum,[-1:0.5:ceil(max(max(all_Dprimes_cumsum)))]);


    %separate into inidividual contourlines and save according to
       % dPrime value
        ix=1;
        while ix<size(ContourMatrix,2)
            dPrime_level=ContourMatrix(1,ix);
            num_of_points=ContourMatrix(2,ix);
            contour_points=ContourMatrix(:,ix+1:ix+num_of_points);
%             fprintf('contour line for dPrime:%.1f with %i points \n',dPrime_level,num_of_points)
            % check if contourline is closed 
            if all(contour_points(:,1)==contour_points(:,end))
%                 fprintf('closed\n')
            else % only save non closed lines
                analyzed_d_prime_ix=find(analyzed_d_prime_array==dPrime_level);
                if ~isempty(analyzed_d_prime_ix)
                    [value,ii]=min(contour_points(1,:));
                    helper.contour_points=contour_points;
                    helper.threshold=contour_points(:,ii);
                    all_contourlines{analyzed_d_prime_ix}{end+1}=helper;
                end
            end
            ix=ix+num_of_points+1;
        end
    
    % Set the colormap limits
    colormap(parula())
    caxisLimits = [0, ceil(max(max(all_Dprimes_cumsum)))]; % Example limits
    colorbar()
    title(fig.Children(1),['cum. d' sprintf( '\''' ) ])

    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
%     plot threshholds and contour lines for d'1,2,3
        colormarkers={':w','--w','-.w'};
        colormarkersk={':k','--k','-.k'};
        hs=[];
        for d_prime_i=[1,2,3]
            d_prime_pos=find(d_prime_i==analyzed_d_prime_array);
            if ~isempty(d_prime_pos)
                Cur_contourlines=all_contourlines{d_prime_pos};
                % check if the contour is a circle
                if ~isempty(Cur_contourlines) 
                    for kk=1:length(Cur_contourlines)
                        points= Cur_contourlines{kk}.contour_points;
                        plot( points(1,:),points(2,:),colormarkers{d_prime_i}, 'linewidth', 3)
                    end
                    hs(d_prime_i)=plot( 1,1,colormarkersk{d_prime_i}, 'linewidth', 3,'DisplayName',sprintf("d'=%i",d_prime_i));
                end
            end
        end
    lg=legend(hs,'Location','northwest','TextColor','k');
   
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel(x_label)
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')
    set(gca,'XTick',0:1:length(x_values),'XTickLabel',x_values)
elseif strcmp(mode,'dPrimeCum_contour_logScale')
    d_prime_results= calculateDprimeMultipleStimVars(IC,'increasingLvl', stim_criteria_array,t_start,t_stop);
    all_Dprimes_cumsum= d_prime_results{1}.all_Dprime_cumsum;
    threshold=d_prime_results{1}.thresholds(find(d_prime_results{1}.analyzed_d_prime_array==1));
    if contains(IC.Stim.exp_type,'eCI')
        x_values=20*log10(x_values/threshold);
    elseif contains(IC.Stim.exp_type,'MX_tones')
        x_values=x_values-threshold;
    else
        x_values=10*log10(x_values/threshold);
    end   
    
    % exclude impossible stimuli from plotting
    if isfield('impossibleStimuli',IC.C) % only works after calibration files have been checked in analysis
        if ~isempty(IC.C.impossibleStimuli)
            if IC.C.impossibleStimuli ~=1 % first one is not included anyway
                x_values(IC.C.impossibleStimuli)=[];
                all_Dprimes_cumsum(:,IC.C.impossibleStimuli-1)=[];
            end
        end
    end
    % d' cumsum values plot
    analyzed_d_prime_array=[-1:0.5:ceil(max(max(all_Dprimes_cumsum)))];
    fig = figure();
    hold on
    all_contourlines=cell(size(analyzed_d_prime_array));
    ContourMatrix=contourf(x_values(2:end), IC.SL.all_electrodes+1 ,all_Dprimes_cumsum,[-1:0.5:ceil(max(max(all_Dprimes_cumsum)))]);


    %separate into inidividual contourlines and save according to
       % dPrime value
        ix=1;
        while ix<size(ContourMatrix,2)
            dPrime_level=ContourMatrix(1,ix);
            num_of_points=ContourMatrix(2,ix);
            contour_points=ContourMatrix(:,ix+1:ix+num_of_points);
%             fprintf('contour line for dPrime:%.1f with %i points \n',dPrime_level,num_of_points)
            % check if contourline is closed 
            if all(contour_points(:,1)==contour_points(:,end))
%                 fprintf('closed\n')
            else % only save non closed lines
                analyzed_d_prime_ix=find(analyzed_d_prime_array==dPrime_level);
                if ~isempty(analyzed_d_prime_ix)
                    [value,ii]=min(contour_points(1,:));
                    helper.contour_points=contour_points;
                    helper.threshold=contour_points(:,ii);
                    all_contourlines{analyzed_d_prime_ix}{end+1}=helper;
                end
            end
            ix=ix+num_of_points+1;
        end
    
    % Set the colormap limits
    colormap(parula())
    caxisLimits = [0, ceil(max(max(all_Dprimes_cumsum)))]; % Example limits
    colorbar()
    title(fig.Children(1),['cum. d' sprintf( '\''' ) ])

    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
%     plot threshholds and contour lines for d'1,2,3
        colormarkers={':w','--w','-.w'};
        colormarkersk={':k','--k','-.k'};
        hs=[];
        for d_prime_i=[1,2,3]
            d_prime_pos=find(d_prime_i==analyzed_d_prime_array);
            if ~isempty(d_prime_pos)
                Cur_contourlines=all_contourlines{d_prime_pos};
                % check if the contour is a circle
                if ~isempty(Cur_contourlines) 
                    for kk=1:length(Cur_contourlines)
                        points= Cur_contourlines{kk}.contour_points;
                        plot( points(1,:),points(2,:),colormarkers{d_prime_i}, 'linewidth', 3)
                    end
                    hs(d_prime_i)=plot( 1,1,colormarkersk{d_prime_i}, 'linewidth', 3,'DisplayName',sprintf("d'=%i",d_prime_i));
                end
            end
        end
    lg=legend(hs,'Location','northwest','TextColor','k');
   
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel("stimulus dB rel. d'1 threshold")
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')
%     set(gca,'XScale','log')
elseif strcmp(mode,'SR_contour_logScale')
    SR=calculateSpikeRate(IC,t_start,t_stop);
    StimIDs=getStimuliFromStimCriteriaArray(IC,stim_criteria_array);
    SR=SR(:,StimIDs);
    d_prime_results= calculateDprimeMultipleStimVars(IC,'baseline', stim_criteria_array,t_start,t_stop);
    threshold=d_prime_results{1}.thresholds(find(d_prime_results{1}.analyzed_d_prime_array==1));
    % transfer intensities into log scale and make sure not to get -inf
    x_values(find(x_values==0))=0.0001;
    
    if contains(IC.Stim.exp_type,'eCI')
        x_values=20*log10(x_values/threshold);
    elseif contains(IC.Stim.exp_type,'MX_tones')
        x_values=x_values-threshold;
    else
        x_values=10*log10(x_values/threshold);
    end   
    
   
    % d' cumsum values plot
    analyzed_SR_array=[0:50:ceil(max(max(SR)))];
    fig = figure();
    hold on
    all_contourlines=cell(size(analyzed_SR_array));
    ContourMatrix=contourf(x_values, IC.SL.all_electrodes+1 ,SR,analyzed_SR_array);


    %separate into inidividual contourlines and save according to
       % dPrime value
        ix=1;
        while ix<size(ContourMatrix,2)
            dPrime_level=ContourMatrix(1,ix);
            num_of_points=ContourMatrix(2,ix);
            contour_points=ContourMatrix(:,ix+1:ix+num_of_points);
%             fprintf('contour line for dPrime:%.1f with %i points \n',dPrime_level,num_of_points)
            % check if contourline is closed 
            if all(contour_points(:,1)==contour_points(:,end))
%                 fprintf('closed\n')
            else % only save non closed lines
                analyzed_SR_ix=find(analyzed_SR_array==dPrime_level);
                if ~isempty(analyzed_SR_ix)
                    [value,ii]=min(contour_points(1,:));
                    helper.contour_points=contour_points;
                    helper.threshold=contour_points(:,ii);
                    all_contourlines{analyzed_SR_ix}{end+1}=helper;
                end
            end
            ix=ix+num_of_points+1;
        end
    
    % Set the colormap limits
    colormap(parula())
    caxisLimits = [0, ceil(max(max(SR)))]; % Example limits
    colorbar()
    title(fig.Children(1),['SR [Hz]'  ])

    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
% %     plot threshholds and contour lines for d'1,2,3
%         colormarkers={':w','--w','-.w'};
%         colormarkersk={':k','--k','-.k'};
%         hs=[];
%         for SR_i=[100,150,200]
%             SR_pos=find(SR_i==analyzed_SR_array);
%             if ~isempty(SR_pos)
%                 Cur_contourlines=all_contourlines{SR_pos};
%                 % check if the contour is a circle
%                 if ~isempty(Cur_contourlines) 
%                     for kk=1:length(Cur_contourlines)
%                         points= Cur_contourlines{kk}.contour_points;
%                         plot( points(1,:),points(2,:),colormarkers{SR_i}, 'linewidth', 3)
%                     end
%                     hs(SR_i)=plot( 1,1,colormarkersk{SR_i}, 'linewidth', 3,'DisplayName',sprintf("SR'=%i",SR_i));
%                 end
%             end
%         end
%     lg=legend(hs,'Location','northwest','TextColor','k');
   
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel("stimulus dB rel. d'1 threshold")
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')
elseif strcmp(mode,'eSR_contour_logScale')
    [all_evoked_spike_rate] = calculateEvokedSpikeRate(IC,stim_criteria_array, t_start,t_stop );
    SR=all_evoked_spike_rate.meanEvokedSpikeRate;
    d_prime_results= calculateDprimeMultipleStimVars(IC,'baseline', stim_criteria_array,t_start,t_stop);
    threshold=d_prime_results{1}.thresholds(find(d_prime_results{1}.analyzed_d_prime_array==1));
    % transfer intensities into log scale and make sure not to get -inf
    x_values(find(x_values==0))=0.0001;
    
    if contains(IC.Stim.exp_type,'eCI')
        x_values=20*log10(x_values/threshold);
    elseif contains(IC.Stim.exp_type,'MX_tones')
        x_values=x_values-threshold;
    else
        x_values=10*log10(x_values/threshold);
    end   
    
   
    % d' cumsum values plot
    analyzed_SR_array=[-50:50:ceil(max(max(SR)))];
    fig = figure();
    hold on
    all_contourlines=cell(size(analyzed_SR_array));
    ContourMatrix=contourf(x_values, IC.SL.all_electrodes+1 ,SR,analyzed_SR_array);


    %separate into inidividual contourlines and save according to
       % dPrime value
        ix=1;
        while ix<size(ContourMatrix,2)
            dPrime_level=ContourMatrix(1,ix);
            num_of_points=ContourMatrix(2,ix);
            contour_points=ContourMatrix(:,ix+1:ix+num_of_points);
%             fprintf('contour line for dPrime:%.1f with %i points \n',dPrime_level,num_of_points)
            % check if contourline is closed 
            if all(contour_points(:,1)==contour_points(:,end))
%                 fprintf('closed\n')
            else % only save non closed lines
                analyzed_SR_ix=find(analyzed_SR_array==dPrime_level);
                if ~isempty(analyzed_SR_ix)
                    [value,ii]=min(contour_points(1,:));
                    helper.contour_points=contour_points;
                    helper.threshold=contour_points(:,ii);
                    all_contourlines{analyzed_SR_ix}{end+1}=helper;
                end
            end
            ix=ix+num_of_points+1;
        end
    
    % Set the colormap limits
    colormap(parula())
    caxisLimits = [0, ceil(max(max(SR)))]; % Example limits
    colorbar()
    title(fig.Children(1),['ER [Hz]'  ])

    if exist('clim')
        clim(caxisLimits)
    else
        caxis(caxisLimits)
    end
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel("stimulus dB rel. d'1 threshold")
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32],'YDir','reverse')

elseif strcmp(mode,'dPrimeBaseline')
    d_prime_results= calculateDprime(IC,'baseline',stim_criteria_array, t_start,t_stop);
    all_Dprime_array=d_prime_results.all_Dprime_array;
    % d' cumsum values plot
    fig = nonuniformHM(x_values',(all_electrodes+1)',all_Dprime_array);
    title(fig.Children(1),['d' sprintf( '\''' ) ])
    colormap(parula(10))
    % Set the colormap limits (with baseline d' analysis it is values
    % between 0 and 4.8
    caxisLimits=[0 5];
    if exist('clim')
            clim(caxisLimits)
        else
            caxis(caxisLimits)
        end
    title(IC.SeriesID, 'Interpreter', 'none')
    xlabel(x_label)
    ylabel('electrode #')
    %make y-axis more sparse for readability
    set(gca,'YTick', [1,8,16,24,32], 'YtickLabel', [1,8,16,24,32])
    set(gca,'XTick',x_values,'XTickLabel',x_values)


elseif strcmp(mode,'SR_MSV')
%     enablecache on
    fixedStimStimList_ix=stim_criteria_array(2,1);
    [meanSpikeRates, ~]  = calculateSpikeRate(IC,t_start,t_stop);
    fixed_stim=unique(OBJ_stimlist(stim_ID,fixedStimStimList_ix),'stable');
    fixed_stim_header =IC.Stim.stimheader{fixedStimStimList_ix};
    num_fixed_stim=length(fixed_stim);
    fh=[];% collect figure handles
    ah = [];% axes handles
    for fixed_stim_ix=1:num_fixed_stim
        cur_stim_ixs=stim_ID(ismember(stim_ID, find(OBJ_stimlist(:,fixedStimStimList_ix)==fixed_stim(fixed_stim_ix))));
        x_values=OBJ_stimlist(cur_stim_ixs,stim_criteria_array(1,1));
        [x_values_sorted, iXValues] = sort(x_values);
        f_sub = nonuniformHM(x_values_sorted',(all_electrodes+1)',meanSpikeRates(:,cur_stim_ixs(iXValues)));
        ah(fixed_stim_ix) = gca;
        title(f_sub.Children(1),"Spike Rate [Hz]")
        colormap("parula")
        % Set the colormap limits
        caxisLimits = [0; max(max(meanSpikeRates))]; % Example limits
        if exist('clim')
            clim(caxisLimits)
        else
            caxis(caxisLimits)
        end
%         title(sprintf('%s: %.1f',fixed_stim_header,fixed_stim(fixed_stim_ix)))
        title(sprintf('%.1f',fixed_stim(fixed_stim_ix)))
        xlabel(x_label)
        ylabel('electrode #')
        %make y-axis more sparse for readability
        set(gca,'YTick', [1,16,32], 'YtickLabel', [1,16,32])
        set(gca,'XTick',x_values_sorted,'XTickLabel',x_values_sorted)
        fh(fixed_stim_ix) = f_sub;
    end

    % childrenFig = get(gcf,'Children') ; % Copy the colorbar to the new figure
    % cb = childrenFig(1)


    %     if strcmp(excludeBadElecsIC,'on')
    %         bad_elecs = findBadElectrodes(IC,meanSpikeRates);
    %         % set bad electrodes to 0
    %         if ~isempty(bad_elecs)
    %             meanSpikeRates(bad_elecs,:)=0;
    %         end
    %     end
    v = version('-release');
    yearMatlab = str2num(v(1:4));
    switch yearMatlab
        

        case 2021

            fig =  figure();
%             tcl=tiledlayout(ff,'flow');
            for ii = 1:numel(ah)
                subplot(6,6,ii)
                % Copy the stored axes into the current subplot
                copyobj(allchild(ah(ii)), gca);
                % Adjust the properties of the new axes if needed
                %  tmpPosition = get(gca, 'Position')
                % set(gca, 'Position', 'tmpPosition');  % Match position of subplot

                set(gca, 'XLabel', get(ah(ii), 'XLabel'));
                set(gca, 'YLabel', get(ah(ii), 'YLabel'));
                title(gca, get(ah(ii), 'Title').String);

                % Optionally, adjust limits
                xlim(gca, get(ah(ii), 'XLim'));
                ylim(gca, get(ah(ii), 'YLim'));
                if ii == numel(ah)
                    %           cb_old = colorbar(ah(ii))
                    cb_new = colorbar(gca);
                    if exist('clim')
                        clim(caxisLimits)
                    else
                        caxis(caxisLimits)
                    end
                end
            end
            fig.Position=[83          42        1271         924];
        otherwise %2022 and newer
            fig=figure;
            tcl=tiledlayout(fig,'flow');
            for ii = 1:numel(fh)
                figure(fh(ii));
                ax=gca;
                ax.Parent=tcl;
                ax.Layout.Tile=ii;
                close(fh(ii))
            end
            fig.Position=[83          42        1271         924];
    
    end

elseif strcmp(mode,'dPrimeCum_MSV')
    all_d_prime_results= calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
    caxisLimits = [0, max(cellfun(@(x) ceil(max(max(x.all_Dprime_cumsum))),all_d_prime_results))]; % Example limits
    % create all individual figures
    fh=[];% collect figure handles
    ah = [];% axes handles
    for stim_ix=1:length(all_d_prime_results)
        d_prime_results=all_d_prime_results{stim_ix};
        all_Dprimes_cumsum= d_prime_results.all_Dprime_cumsum;
        x_values=d_prime_results.changing_var_values;
        stim_descr = sprintf('%.2f',d_prime_results.fixed_var_value);
        % d' cumsum values plot
        f_sub = nonuniformHM(x_values(2:end)',(all_electrodes+1)',all_Dprimes_cumsum);
        title(f_sub.Children(1),['cum. d' sprintf( '\''' )])
        ah(stim_ix) = gca;
        colormap(parula(2*ceil(caxisLimits(2))))
        % Set the colormap limits
        if exist('clim')
            c=colorbar;
            clim(caxisLimits)
            c.Ticks=0:1:caxisLimits(2);
        else
            caxis(caxisLimits)
        end
        title(stim_descr, 'Interpreter', 'none')
        xlabel(x_label)
        ylabel('electrode #')
        %make y-axis more sparse for readability
        set(gca,'YTick', 1:4:32, 'YtickLabel', 1:4:32)
        set(gca,'XTick',x_values,'XTickLabel',x_values)
        fh(stim_ix) = f_sub;
    end

    % join up all the figures in one
    v = version('-release');
    yearMatlab = str2num(v(1:4));
    switch yearMatlab
        case 2021

            fig=  figure();
%             tcl=tiledlayout(ff,'flow');
            for ii = 1:numel(ah)
                subplot(6,6,ii)
                % Copy the stored axes into the current subplot
                copyobj(allchild(ah(ii)), gca);
                % Adjust the properties of the new axes if needed
                %  tmpPosition = get(gca, 'Position')
                % set(gca, 'Position', 'tmpPosition');  % Match position of subplot

                set(gca, 'XLabel', get(ah(ii), 'XLabel'));
                set(gca, 'YLabel', get(ah(ii), 'YLabel'));
                title(gca, get(ah(ii), 'Title').String);

                % Optionally, adjust limits
                xlim(gca, get(ah(ii), 'XLim'));
                ylim(gca, get(ah(ii), 'YLim'));
                if ii == numel(ah)
                    %           cb_old = colorbar(ah(ii))
                    cb_new = colorbar(gca);
                    if exist('clim')
                        clim(caxisLimits)
                    else
                        caxis(caxisLimits)
                    end
                end
            end
            fig.Position=[83          42        1271         924];
    
        otherwise %2022 and newer
            fig=figure;
            tcl=tiledlayout(fig,'flow');
            for ii = 1:numel(fh)
                figure(fh(ii));
                ax=gca;
                ax.Parent=tcl;
                ax.Layout.Tile=ii;
                close(fh(ii))
            end
            fig.Position=[83          42        1271         924];
    end


    elseif strcmp(mode,'dPrimeBaseline_MSV')
        all_d_prime_results= calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
        caxisLimits = [0, 5]; % max d' value for basline is 4.3
        % create all individual figures
        fh=[];% collect figure handles
        ah = [];% axes handles
        for stim_ix=1:length(all_d_prime_results)
            d_prime_results=all_d_prime_results{stim_ix};
            all_Dprimes_array= d_prime_results.all_Dprime_array;
            x_values=d_prime_results.changing_var_values;
            stim_descr = sprintf('%.2f',d_prime_results.fixed_var_value);
            % d' cumsum values plot
            f_sub = nonuniformHM(x_values',(all_electrodes+1)',all_Dprimes_array);
            title(f_sub.Children(1),['d' sprintf( '\''' )])
            ah(stim_ix) = gca;
            colormap(parula(2*caxisLimits(2)))
            % Set the colormap limits
            if exist('clim')
                c=colorbar;
                clim(caxisLimits)
                c.Ticks=0:1:caxisLimits(2);
            else
                caxis(caxisLimits)
            end
            title(stim_descr, 'Interpreter', 'none')
            xlabel(x_label)
            ylabel('electrode #')
            %make y-axis more sparse for readability
            set(gca,'YTick', 1:4:32, 'YtickLabel', 1:4:32)
            set(gca,'XTick',x_values,'XTickLabel',x_values)
            fh(stim_ix) = f_sub;
        end
    
        % join up all the figures in one
        v = version('-release');
        yearMatlab = str2num(v(1:4));
        switch yearMatlab
            case 2021
                fig=  figure();
    %             tcl=tiledlayout(ff,'flow');
                for ii = 1:numel(ah)
                    subplot(6,6,ii)
                    % Copy the stored axes into the current subplot
                    copyobj(allchild(ah(ii)), gca);
                    % Adjust the properties of the new axes if needed
                    %  tmpPosition = get(gca, 'Position')
                    % set(gca, 'Position', 'tmpPosition');  % Match position of subplot
    
                    set(gca, 'XLabel', get(ah(ii), 'XLabel'));
                    set(gca, 'YLabel', get(ah(ii), 'YLabel'));
                    title(gca, get(ah(ii), 'Title').String);
    
                    % Optionally, adjust limits
                    xlim(gca, get(ah(ii), 'XLim'));
                    ylim(gca, get(ah(ii), 'YLim'));
                    if ii == numel(ah)
                        %           cb_old = colorbar(ah(ii))
                        cb_new = colorbar(gca);
                        if exist('clim')
                            clim(caxisLimits)
                        else
                            caxis(caxisLimits)
                        end
                    end
                end
                fig.Position=[83          42        1271         924];
            otherwise %2022 and newer
                fig=figure;
                tcl=tiledlayout(fig,'flow');
                for ii = 1:numel(fh)
                    figure(fh(ii));
                    ax=gca;
                    ax.Parent=tcl;
                    ax.Layout.Tile=ii;
                    close(fh(ii))
                end
                fig.Position=[83          42        1271         924];
        end

end



end
