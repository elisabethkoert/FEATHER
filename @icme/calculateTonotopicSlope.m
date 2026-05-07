function [tonotopy_array, tonotopy_slope,elec_best_freq_array,elec_freq_thr_array,varargout] = calculateTonotopicSlope(obj,generate_plot,mode,d_prime_thr)
% icme\calculateTonotopicSlope calculates the tonotopic slope based on the d' analysis for each frequency
% this script calculates cum d_prime results , and then goes through
% each presented frequency and looks up the best electrode which is the
% lowest threshold to reach d'=d_prime_thr , the slope is fitted, outliers
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
% tonotopy_array( num_frequencies x3 floats): first column pure tone
%    frequency, second column best electrode id, third column threshold for
%    d'=1 [dB]
% tonotopy_slope(float/ list of floats) slope [oct/mm] 
% elec_best_freq_array (n_elecs x 3 array) first colllumn electrode IDs
%   1:1:32, second column threshold min [dB SPL], third collumn frequency for min.
%   threshold [Hz]
% elec_freq_thr_array (n_elecs x n_freq) to hold the d'=1 thresholds in dB SPL 
% varargout:
%   num_removed_outliers (int) numebr of outliers removed when fitting the
%       slope, measurement for numebr of frequencies that are not nicely
%       represented on the tontoopic axes

if ~exist('generate_plot','var') 
    generate_plot=0;
end
if ~exist('mode','var')
    mode='increasingLvl';
end
if ~exist('d_prime_thr','var') 
    d_prime_thr=2;
end

% check if we have a tonotopy script as the IC object
if ~strcmp(obj.Stim.exp_type,'MX_tones')
    tonotopy_array=[];
    tonotopy_slope=NaN;
    elec_best_freq_array=[];
    elec_freq_thr_array=[];
    num_removed_outliers=[];
    disp(' tontotopy slope calculation called for a non tontotopy script!!!')
    return
end

num_outlier_removals=2;
num_removed_outliers=0; % counter  to return afterwards
outlier_removal_thr=2;
stim_criteria_array=[4,0,90;1,125,32000];
t_start=5; % corresponding to t_on t_off in PSTH of pure tone stimuli
t_stop=120;


% first test if enable cache is on and load any existing data
save_name = sprintf("%s_tonotopy_res_dprimethr_%i_mode_%s.mat",obj.SeriesID,d_prime_thr,mode);
if strcmpi(enablecache,'on') && isfile(fullfile(expProcDataDir,'ICME',save_name))
     load(fullfile(expProcDataDir,'ICME',save_name));
     fprintf('tonotopy results loaded for %s \n',obj.SeriesID)
     if nargout >= 5
        varargout{1} = num_removed_outliers;
    end
    
else
    
    all_d_prime_results = calculateDprimeMultipleStimVars(obj,mode,stim_criteria_array,t_start,t_stop);
    % prep array (nelecsxnfrequ to hold the d'=1 threhsolds for each
    % electrode and frequency)
    elec_freq_thr_array=zeros(length(obj.SL.all_electrodes),length(all_d_prime_results));
    % prep array to hold tonotopy results
    tonotopy_array =zeros(length(all_d_prime_results),3); %frequency, electrode, threshold
    for stim_ix=1:length(all_d_prime_results)
        d_prime_results=all_d_prime_results{stim_ix};
        tonotopy_array(stim_ix,1)= d_prime_results.fixed_var_value;
        analyzed_d_prime_array = d_prime_results.analyzed_d_prime_array;
        d_prime_thr_ix=find(analyzed_d_prime_array==d_prime_thr);
        
         if strcmp(mode,'increasingLvl')
             thresholds_by_channel=d_prime_results.thresholds_by_channel_Cum;
             elec_freq_thr_array(:,stim_ix)=d_prime_results.thresholds_by_channel_Cum(:,d_prime_thr_ix);
        elseif strcmp(mode,'baseline')
            thresholds_by_channel=d_prime_results.thresholds_by_channel_base;
             % save results for getting the best freq per electrode later
            elec_freq_thr_array(:,stim_ix)=d_prime_results.thresholds_by_channel_base(:,d_prime_thr_ix);
        else
            error('unknown mode')
         end
        threshold_min=min(thresholds_by_channel(:,d_prime_thr_ix));
        if isnan(threshold_min)
            tonotopy_array(stim_ix,2:3)=NaN;
        else
            thr_elecs=find(thresholds_by_channel(:,d_prime_thr_ix)==threshold_min);
            tonotopy_array(stim_ix,2)=mean(thr_elecs);
            tonotopy_array(stim_ix,3)=threshold_min;
        end         
    end
    
    temp_tonotopy_array=tonotopy_array;
    nan_ixs=find(isnan(temp_tonotopy_array(:,2)));
    temp_tonotopy_array(nan_ixs,:)=[];

    CFs_kHz=temp_tonotopy_array(:,1)/1000;
    CFs_oct=log2(CFs_kHz/.500);
    depth=temp_tonotopy_array(:,2)*0.05;
    dist_on_elec_mm=temp_tonotopy_array(:,2)*0.05;
            
    p= polyfit(CFs_oct,dist_on_elec_mm,1);
    tonotopy_slope=1/p(1); % oct/mm

    %remove outliers and refit
    for rep=1:num_outlier_removals 
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
    

    [values,ixs]=min(elec_freq_thr_array,[],2);
    mean_best_freq=[];
    for eleci=1:size(elec_freq_thr_array,1)
        all_ixs=find(elec_freq_thr_array(eleci,:)==values(eleci));
        new_ixs = [all_ixs((diff([all_ixs]) == 1)),all_ixs(find(diff([all_ixs]) ~= 1,1))];
        mean_best_freq(eleci)=mean(tonotopy_array(new_ixs,1));
    end
    elec_best_freq_array=[obj.SL.all_electrodes+1,values,tonotopy_array(ixs,1),mean_best_freq'];


    %save the output
    save_name = sprintf("%s_tonotopy_res_dprimethr_%i_mode_%s.mat",obj.SeriesID,d_prime_thr,mode);
    %test if there is alreadz a directory for SR, otherwise make it
    if  ~isfolder(fullfile(expProcDataDir,'ICME'))
        mkdir(fullfile(expProcDataDir,'ICME'));
        save(fullfile(expProcDataDir,'ICME',save_name),'tonotopy_array','tonotopy_slope','elec_best_freq_array','elec_freq_thr_array','num_removed_outliers');
    elseif  isfolder(fullfile(expProcDataDir,'ICME')) == 1
        save(fullfile(expProcDataDir,'ICME',save_name),'tonotopy_array','tonotopy_slope','elec_best_freq_array','elec_freq_thr_array','num_removed_outliers');
    end

end

if generate_plot==1
        figure
        hold on
        temp_tonotopy_array=tonotopy_array;
        nan_ixs=find(isnan(temp_tonotopy_array(:,2)));
        temp_tonotopy_array(nan_ixs,:)=[];
        CFs_kHz=temp_tonotopy_array(:,1)/1000;
        CFs_oct=log2(CFs_kHz/.500);
        depth=temp_tonotopy_array(:,2)*0.05;
        p= polyfit(CFs_oct,depth,1);
        tonotopy_slope=1/p(1); % oct/mm
        % plot
        scatter(CFs_oct, depth,80, 'k.','HandleVisibility','off');
        plot(CFs_oct,polyval(p,CFs_oct),'DisplayName',strcat(obj.ExpID,': ',num2str(tonotopy_slope,'%.1f'),' oct/mm'));
       
         %remove outliers and refit
        for rep=1:num_outlier_removals
            y_fit=polyval(p,CFs_oct);
            residuals=depth-y_fit;
            sigma=std(residuals);
            outliers=abs(residuals)>2*sigma;
            if any(outliers)
                scatter(CFs_oct(outliers),depth(outliers),'r','HandleVisibility','off')
                CFs_oct=CFs_oct(~outliers);
                depth=depth(~outliers);
                p= polyfit(CFs_oct,depth,1);
                tonotopy_slope=1/p(1); % oct/mm
                plot(CFs_oct,polyval(p,CFs_oct),'DisplayName',strcat(obj.ExpID,': ',num2str(tonotopy_slope,'%.1f'),' oct/mm outliersRemoved ',num2str(rep)));
            end
        end
        
        ylabel('depth on elec. array [mm]'); 
        xlabel('CF [kHz]');
        set(gca, 'XTick', [CFs_oct(1:2:end)]')
        xticklabels(num2str([CFs_kHz(1:2:end)],'%.1f'))
    %     ylim([ 3.3]); 
        xlim([-0.5,6.5])
        set(gca,'Ydir','reverse');
        legend('Location','best')
    %     title( strcat("tonotopy slope for ",IC.SeriesID,': ',num2str(tonotopy_slope,'%.2f'),' oct/mm'),'Interpreter','none')
        hold off
    
    end


       


        

end


        