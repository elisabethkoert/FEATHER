function [tonotopy_array, tonotopy_slope,elec_best_freq_array,elec_freq_thr_array,varargout] = calculateTonotopicSlopeSortedbyElectrode(obj,generate_plot,mode,d_prime_thr)
% icme\calculateTonotopicSlopeSortedByElectrode calculates the tonotopic slope based on the d' analysis for each electrode
% this script calculates cum d_prime results , and then goes through
% each presented electrode and looks up the best frequency which is the
% lowest threshold to reach d'=d_prime_thr, if mutliple frequencies hav ethe same threshold it takes the mean, the slope is fitted, outliers
% (abs(residuals)>2*std(residuals)) from the fit are calculated and removed
% 2 times iteratively
% input:
% obj (icme) IC recording object, best from a MX_tones protocol
% generate_plot (bool): allows for plotting of the resulting slope, usually
%    initialized as FALSE
% mode (string): type of d prime analysis to perform
%   'increasingLvl'/'baseline'
% d_prime_thr (float): threshold to look to determine the best
% electrode/frequency
%
% output:
% tonotopy_array(numelectrodes x4 floats): first best
%    frequency [Hz] , second column electrode id, third column threshold for
%    d'=d'_thr [dB], fourth collumn interpolated best frequency [Hz] for the
%    electrode after outlier removal
% tonotopy_slope(float/ list of floats) slope [oct/mm] 
% elec_best_freq_array (n_elecs x 3 array) array giving info for each frequency presented, first collumn mean best
% electrode, second column threshold min [dB SPL], third collumn presented
% frequency [Hz]
% elec_freq_thr_array (n_elecs x n_freq to hold the d'=1 thresholds in dB SPL 
% varargout: (only taken when at least 5 outputs are required)
%   num_removed_outliers (int) numebr of outliers removed when fitting the
%       slope, measurement for numebr of electrodes that are not nicely
%       represented on the tontoopic axes
if ~exist('generate_plot','var') 
    generate_plot=0;
end
if ~exist('mode','var') 
    mode='baseline';
end
if ~exist('d_prime_thr','var') 
    d_prime_thr=1;
end

% check if we have a tonotopy script as the IC object
if ~strcmp(obj.Stim.exp_type,'MX_tones')
    tonotopy_array=[];
    tonotopy_slope=NaN;
    elec_best_freq_array=[];
    elec_freq_thr_array=[];
    num_removed_outliers=[];
    if nargout >= 5
        varargout{1} = num_removed_outliers;
    end
    disp(' tontotopy slope calculation called for a non tontotopy script!!!')
    return
end

num_outlier_removals=2;
num_removed_outliers=0; % counter  to return afterwards
outlier_removal_thr=2;

% first test if enable cache is on and load any existing data
save_name = sprintf("%s_tonotopy_res_SortedByElec_dprimethr_%i_mode_%s.mat",obj.SeriesID,d_prime_thr,mode);
if strcmpi(enablecache,'on') && isfile(fullfile(expProcDataDir,'ICME',save_name))
        load(fullfile(expProcDataDir,'ICME',save_name));
        fprintf('tonotopy results loaded for %s \n',obj.SeriesID)
    if nargout >= 5
        varargout{1} = num_removed_outliers;
    end
    
else % recalcualte bc n



    %  % if loading did not work or enablecache is off calculate the
    %  tonotopic slope
    stim_criteria_array=[4,0,90;1,125,32000];
    t_start=5; % corresponding to t_on t_off in PSTH of pure tone stimuli
    t_stop=120;
    all_d_prime_results = calculateDprimeMultipleStimVars(obj,mode,stim_criteria_array,t_start,t_stop);
   
    % resort by electrode
    used_frequencies=cellfun(@(x) [x.fixed_var_value],all_d_prime_results);
    all_d_prime_results_byElectrode =cell(1,32);% cellfun(@(x) struct('all_Dprime_cumsum', zeros(length(all_d_prime_results), length(all_d_prime_results{1}.stimuli))), cell(1, length(obj.SL.all_electrodes)), 'UniformOutput', false);
    for i = 1:length(obj.SL.all_electrodes)
        for j = 1:length(all_d_prime_results)
            all_d_prime_results_byElectrode{i}.all_Dprime_cumsum(j, :) = all_d_prime_results{j}.all_Dprime_cumsum(i, :);
            all_d_prime_results_byElectrode{i}.all_Dprime_array(j, :) = all_d_prime_results{j}.all_Dprime_array(i, :);
            all_d_prime_results_byElectrode{i}.thresholds_by_channel_Cum(j, :) = all_d_prime_results{j}.thresholds_by_channel_Cum(i, :);
            all_d_prime_results_byElectrode{i}.thresholds_by_channel_base(j, :) = all_d_prime_results{j}.thresholds_by_channel_base(i, :);
        end
        all_d_prime_results_byElectrode{i}.frequencies=used_frequencies;
        all_d_prime_results_byElectrode{i}.t_start=all_d_prime_results{1}.t_start;
        all_d_prime_results_byElectrode{i}.t_stop=all_d_prime_results{1}.t_stop;
        all_d_prime_results_byElectrode{i}.mode=all_d_prime_results{1}.mode;
        all_d_prime_results_byElectrode{i}.stimuli=all_d_prime_results{1}.changing_var_values;
        all_d_prime_results_byElectrode{i}.changing_var_header=all_d_prime_results{1}.changing_var_header;
        all_d_prime_results_byElectrode{i}.analyzed_d_prime_array=all_d_prime_results{1}.analyzed_d_prime_array;
        all_d_prime_results_byElectrode{i}.fixed_stim=i;
        all_d_prime_results_byElectrode{i}.fixed_stim_header='Electrode ID';
    end
    
    
    % prep array (nelecsxnfrequ to hold the d'=1 threhsolds for each
    % electrode and frequency)
    elec_freq_thr_array=zeros(length(obj.SL.all_electrodes),length(used_frequencies));
    % prep array to hold tonotopy results
    tonotopy_array =zeros(length(all_d_prime_results_byElectrode),4); %electrode, frequency, threshold
    % loop through electrodes
    for elec_ix=1:length(obj.SL.all_electrodes)
        d_prime_results=all_d_prime_results_byElectrode{elec_ix};
        tonotopy_array(elec_ix,2)= d_prime_results.fixed_stim;
        analyzed_d_prime_array = d_prime_results.analyzed_d_prime_array;
        d_prime_thr_ix=find(analyzed_d_prime_array==d_prime_thr);
        % find bestfrequency for the electrode
        if strcmp(mode,'increasingLvl')
             thresholds_by_channel=d_prime_results.thresholds_by_channel_Cum;
             elec_freq_thr_array(elec_ix,:)=d_prime_results.thresholds_by_channel_Cum(:,d_prime_thr_ix);
        elseif strcmp(mode,'baseline')
            thresholds_by_channel=d_prime_results.thresholds_by_channel_base;
             % save results for getting the best freq per electrode later
            elec_freq_thr_array(elec_ix,:)=d_prime_results.thresholds_by_channel_base(:,d_prime_thr_ix);
        else
            error('unknown mode')
        end
        threshold_min=min(thresholds_by_channel(:,d_prime_thr_ix));
        if isnan(threshold_min)
            tonotopy_array(elec_ix,[1,3])=NaN;
        else
            ixs=find(thresholds_by_channel(:,d_prime_thr_ix)==threshold_min);
%             tonotopy_array(elec_ix,1)=mean(used_frequencies(ixs));
            tonotopy_array(elec_ix,1) = exp(mean(log(used_frequencies(ixs))));
            tonotopy_array(elec_ix,3)=threshold_min;
        end         
    end

    % fit a slope
    temp_tonotopy_array=tonotopy_array;
    nan_ixs=find(isnan(temp_tonotopy_array(:,1)));
    temp_tonotopy_array(nan_ixs,:)=[];

    CFs_kHz=temp_tonotopy_array(:,1)/1000;
    CFs_oct=log2(CFs_kHz/.500);
    depth=temp_tonotopy_array(:,2)*0.05;
    dist_on_elec_mm=temp_tonotopy_array(:,2)*0.05;
            
    p= polyfit(CFs_oct,dist_on_elec_mm,1);
    tonotopy_slope=1/p(1); % oct/mm

    %remove outliers and refit
    for rep=1:num_outlier_removals % reiterate twice to make sure zou get them
        y_fit=polyval(p,CFs_oct);
        residuals=depth-y_fit;
        sigma=std(residuals);
        outliers=abs(residuals)>outlier_removal_thr*sigma;
        num_removed_outliers=num_removed_outliers+sum(outliers);
        if any(outliers)
            CFs_oct=CFs_oct(~outliers);
            depth=depth(~outliers);
            p= polyfit(CFs_oct,depth,1);
            tonotopy_slope=1/p(1); % oct/mm
        end
    end

    if nargout >= 5
        varargout{1} = num_removed_outliers;
    end
    
    % add a collumn in the tonotopy array that has the interpolated
    % frequency based on this slope:
    p2= polyfit(depth,CFs_oct,1);
    CF_interp_oct=polyval(p2,tonotopy_array(:,2)*0.05);
    CFs_interp_Hz=500.*2.^(CF_interp_oct);
    tonotopy_array(:,4)=CFs_interp_Hz;

    % make an array where you get the threshold for each presented
    % frequency
    [values,ixs]=min(elec_freq_thr_array,[],1);
    mean_best_elec=[];
    for freqi=1:size(elec_freq_thr_array,2)
        all_ixs=find(elec_freq_thr_array(:,freqi)==values(freqi));
        mean_best_elec(freqi)=mean(all_ixs);
    end
    elec_best_freq_array=[mean_best_elec',values',used_frequencies'];

    %save the output
    save_name = sprintf("%s_tonotopy_res_SortedByElec_dprimethr_%i_mode_%s.mat",obj.SeriesID,d_prime_thr,mode);
    %test if there is alreadz a directory for SR, otherwise make it
    if  ~isfolder(fullfile(expProcDataDir,'ICME'))
        mkdir(fullfile(expProcDataDir,'ICME'));
        save(fullfile(expProcDataDir,'ICME',save_name),'tonotopy_array','tonotopy_slope','elec_best_freq_array','elec_freq_thr_array','all_d_prime_results_byElectrode','num_removed_outliers');
    elseif  isfolder(fullfile(expProcDataDir,'ICME')) == 1
        save(fullfile(expProcDataDir,'ICME',save_name),'tonotopy_array','tonotopy_slope','elec_best_freq_array','elec_freq_thr_array','all_d_prime_results_byElectrode','num_removed_outliers');
    end

end

if generate_plot==1
        figure
        hold on
        temp_tonotopy_array=tonotopy_array;
        nan_ixs=find(isnan(temp_tonotopy_array(:,1)));
        temp_tonotopy_array(nan_ixs,:)=[];
        CFs_kHz=temp_tonotopy_array(:,1)/1000;
        CFs_oct=log2(CFs_kHz/.500);
        depth=temp_tonotopy_array(:,2)*0.05;
        p= polyfit(CFs_oct,depth,1);
        tonotopy_slope=1/p(1); % oct/mm

        % get interpoalted values
        CFs_interpolated_kHz=temp_tonotopy_array(:,4)/1000;
        CFs_interpolated_oct=log2(CFs_interpolated_kHz/.500);

        
        % plot actual frequency-best electrode association from d' analysis
        scatter(CFs_oct, depth,80, 'k.','HandleVisibility','off');
        % plot fit nr1
        plot(CFs_oct,polyval(p,CFs_oct),'DisplayName',strcat(obj.ExpID,': ',num2str(tonotopy_slope,'%.1f'),' oct/mm'));
       % plot interpolated best freqeuncies for each eelctrode
%        scatter(CFs_interpolated_oct, depth,30, 'ro','HandleVisibility','off');


         %remove outliers and refit , mark outliers with circle, plot new
         %fitted line
        for rep=1:num_outlier_removals 
            y_fit=polyval(p,CFs_oct);
            residuals=depth-y_fit;
            sigma=std(residuals);
            outliers=abs(residuals)>outlier_removal_thr*sigma;
            if any(outliers)
                scatter(CFs_oct(outliers),depth(outliers),'HandleVisibility','off')
                CFs_oct=CFs_oct(~outliers);
                depth=depth(~outliers);
                p= polyfit(CFs_oct,depth,1);
                tonotopy_slope=1/p(1); % oct/mm
                plot(CFs_oct,polyval(p,CFs_oct),'DisplayName',strcat(obj.ExpID,': ',num2str(tonotopy_slope,'%.1f'),' oct/mm outliersRemoved ',num2str(rep)));
            end
        end
        

        ylabel('depth on elec. array [mm]'); 
        xlabel('CF [kHz]');
        xTickLabels_=get(gca,'XTickLabel');
        xTickLabels_kHz=cellfun(@(x)  2.^str2num(x) * 0.500,xTickLabels_ );
        xticklabels(num2str(xTickLabels_kHz));

    %     ylim([ 3.3]); 
        xlim([-0.5,6.5])
        set(gca,'Ydir','reverse');
        legend('Location','best')
    %     title( strcat("tonotopy slope for ",IC.SeriesID,': ',num2str(tonotopy_slope,'%.2f'),' oct/mm'),'Interpreter','none')
        hold off
    

        %% heatmaps
             if strcmp(mode,'increasingLvl')
                           caxisLimits = [0, max(cellfun(@(x) ceil(max(max(x.all_Dprime_cumsum))),all_d_prime_results_byElectrode))]; % Example limits
           elseif strcmp(mode,'baseline')
               caxisLimits = [0,5];
             end
         % create all individual figures
            fh=[];% collect figure handles
            ah = [];% axes handles
            for elec_ix=1:length(all_d_prime_results_byElectrode)
                d_prime_results=all_d_prime_results_byElectrode{elec_ix};
                SPLs=d_prime_results.stimuli;
                frequencies=d_prime_results.frequencies;
                frequencies_octaves=log2(frequencies/.500);
                stim_descr = sprintf('Elec. %i',d_prime_results.fixed_stim);
                 if strcmp(mode,'increasingLvl')
                      all_Dprimes_array= d_prime_results.all_Dprime_cumsum;
                      y_values=SPLs(2:end)';
                  elseif strcmp(mode,'baseline')
                      all_Dprimes_array= d_prime_results.all_Dprime_array;
                      y_values=SPLs(2:end)';
                 end

                
                % d' cumsum values plot
                f_sub = nonuniformHM(frequencies_octaves,y_values,flip(all_Dprimes_array'));
                title(f_sub.Children(1),['mean cum. d' sprintf( '\''' )])
                ah(elec_ix) = gca;
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
                xlabel('CF [kHz]')
                ylabel('intensity [dB SPL]')
                %make y-axis more sparse for readability
                set(gca,'yTick',y_values,'YTickLabel',flip(y_values))
                set(gca,'XTick',frequencies_octaves(1:4:end),'XTickLabel',frequencies(1:4:end)/1000)
                fh(elec_ix) = f_sub;
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

