%% This is an example on how to analyse new IC data
% we assume that the anex was already initialized during ghte ABR analysis
% for now it only works for users of the IAN that have access to our test
% raw data stored on the UKON

% start by cleaning up your workspace
clearvars -except ukonmap; close all;



%% load existing Anex
ExpID='GEK030';
experimenterID='test';
enablecache on
ee = anex(ExpID, 'test'); 
ee=loadAnex(ee);

%% add raw data dir
% ususally we keep IC data in the same dir as ABR data so we can copy the
% path
D_cur=ee.RawDataDir;
D_cur(end+1).dir=ee.RawDataDir(find([ee.RawDataDir.type]=='ABR')).dir;
D_cur(end).type = "IC" ;
ee = setRawDataDir(ee,D_cur);
saveAnex(ee);

%% initialise ICME objects from raw data .m log files
enablecache off
allIcme(ee) %  preprocessing/loading all the .m log files
waitfor(ICuserInput(ee)) % give user input (eg. which filter has been used, saved in a separate user input table)
saveAnex(ee); % updates the ee

% load the user input table
enablecache on
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
load(in_dir_name);%loads UT, containing user input and stimulus types for each icme


%% run spike extraction and add calibration for each icme
enablecache on
L =listIcme(ee);
for ii = 1: numel(L.IC_SeriesID)
    ix_in_UT= cellfun(@(x) strcmp( x ,string(L.IC_SeriesID(ii))),UT.data(:,find(contains(UT.fieldNames,'SeriesID'))));
    if UT.data{ix_in_UT,find(contains(UT.fieldNames,'Use'))}== -1  % skip the experiments marked as bad
        continue
    end
    % load existing icme object
    enablecache on
    IC=loadIcme(icme(ee,string(L.IC_SeriesID(ii))));
    disp(L.IC_SeriesID(ii))
    %% read in the calibration/calcualte the calibration 
    % if the ExpControl vesion used the correct calibrated stimuli, we
    % only read in the calibration files to store within the ICME data
    % structure
    enablecache off
    OD=UT.data{ix_in_UT,find(contains(UT.fieldNames,'Filter'))};
    ComPort=UT.data{ix_in_UT,find(contains(UT.fieldNames,'Port'))};
    IC= getCalibration(IC,OD,ComPort) ;
    saveIcme(IC);

    %% extract the MU activity from the raw data, needs a WS 
   enablecache off
   IC = ExtractMUAfromRawDataIntoSL(IC);
   saveIcme(IC);
end

%% get thresholds

enablecache off  % this gets saved in the processed data dir so cache on would just load previous results
% optic all RW 200 µm fibers
dPrimeMode='baseline';
optThr=intensityThresholdIC(ee,  dPrimeMode);
dPrimeMode='increasingLvl';
optThr=intensityThresholdIC(ee,  dPrimeMode);
% acoustic for each frequency
acoustThr=intensityThresholdIC(ee,'baseline','MX_tones',[4,0,90;1,500,32000]);

 
%% example processing for pulse intensity protocol/ SoE
IC_SeriesID='GEK030_0004';
t_start=3;
t_stop=25;
enablecache on
IC=loadIcme(icme(ee,IC_SeriesID));


% calculate SoE
[meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,t_start,t_stop); % get spikerates
stim_criteria_array=[1,0,60;3,1,1]; % 0 to 30 mW, 1 ms stimuli
d_prime_results = calculateDprime(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
d_prime_results = calculateDprime(IC,'baseline',stim_criteria_array,t_start,t_stop);
elecs=getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop);
plotHeatmapsIC(IC,'SR',stim_criteria_array,t_start,t_stop)
plotHeatmapsIC(IC,'dPrimeCum',stim_criteria_array,t_start,t_stop)
plotHeatmapsIC(IC,'dPrimeBaseline',stim_criteria_array,t_start,t_stop)
% SoE caclulation
all_SoE_results_Contour = calculateSOEContourlinesMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
all_SoE_results_Contour_baseline = calculateSOEContourlinesMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
% get responsive units & plot PSTH (only from responsive units)
psth_t_start = -10;  % time before stimulus onset
psth_t_stop  = 60; % time after stimulus onset
PSTH_binsize = 0.25; % 0.25 ms used in Maria Michael 2023 paper
plot_bool=1; % to create figures or just do the temporal analysis
artefact_removal=1;
stimdur_ix=10; %[s]
[PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,psth_t_start,psth_t_stop,PSTH_binsize )
    

%% example processing for tonotopy experiment
 IC_SeriesID='GEK030_0001';
 t_start=5;
 t_stop=125;
% load existing icme object
 enablecache on
 IC=loadIcme(icme(ee,IC_SeriesID));
 % calculate spike rate in a specific time window for all presented stimuli
 [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,t_start,t_stop); % get spikerates
 
 % look only at 1 frequency
 stim_criteria_array=[4,0,90;1,16000,16000]; % only 16 kHz stimuli, all SPL intensities 

% check if this stimulus was used and where it is in the stim-list
used_stimuli=getStimuliFromStimCriteriaArray(IC,stim_criteria_array);

 % calculate  the evoked spike rate 
 % (rate after trigger - rate in same time window before trigger)
 [ evokedSpikeRate]  = calculateEvokedSpikeRate(IC,stim_criteria_array,t_start,t_stop); 

 % get responsive electrodes (that have a d'>1 when comparing the onset
% response in 2-25 ms after trigger with the baseline time window before
% trigger
[responsive_units] = getResponsiveUnits(IC,stim_criteria_array);


% quickly plot different heatmaps  (check the function for all options)
plotHeatmapsIC(IC, 'SR',stim_criteria_array,t_start,t_stop); % plot SR
plotHeatmapsIC(IC, 'SR_contour_logScale',stim_criteria_array,t_start,t_stop); % plot SR
plotHeatmapsIC(IC, 'dPrimeCum',stim_criteria_array,t_start,t_stop); % plot dPrimes cumulative sum
plotHeatmapsIC(IC, 'dPrimeBaseline',stim_criteria_array,t_start,t_stop); % plot dPrimes baseline
plotHeatmapsIC(IC, 'dPrimeBase_contour',stim_criteria_array,t_start,t_stop); % plot dPrimes baseline

% change the stim-criteria-array to cover a range of frequencies
stim_criteria_array=[4,0,90;1,500,32000];
plotHeatmapsIC(IC, 'SR_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
plotHeatmapsIC(IC, 'dPrimeCum_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes


% calculate d prime by comparing spike rate distributions
[all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
[all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
   
% calculate spread of excitation
all_SoE_results = calculateSOEMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
all_SoE_results_baseline = calculateSOEMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
% interpolate values using contourlines
all_SoE_results_Contour = calculateSOEContourlinesMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
all_SoE_results_Contour_baseline = calculateSOEContourlinesMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);

% plot PSTH
stim_criteria_array=[1,4000,4000;4,50,80]; % (collum in stimlist, min value, max value) exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
artefact_removal=0;
stimdur_ix=3; % where in the stimlist the duration is
elecs=1:1:32; 
t_start = -10;  % time before stimulus onset
t_stop  =  150; % time after stimulus onset
PSTH_binsize = 0.25; % 0.25 ms used in Maria Michael 2023 paper
plot_bool=1; % to create figures or just do the temporal analysis
normalize_plot=1;
[PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,t_start,t_stop,PSTH_binsize,normalize_plot )

% actual tonotopy analysis 
%  sort by freq and go for d'=1 treshold (our default)
plot_bool=1;
d_prime_thr=1;
mode='increasingLvl';
[tonotopy_array_byFreq1, tonotopy_slope,elec_best_freq_array,elec_freq_thr_array] =calculateTonotopicSlope(IC,plot_bool,mode,d_prime_thr);

% sort by electrode this one autumatically plots heatmaps if
% plotbool is true
d_prime_thr=2;
mode='increasingLvl';
[tonotopy_array3, tonotopy_slope3,elec_best_freq_array3,elec_freq_thr_array3]=calculateTonotopicSlopeSortedbyElectrode(IC,plot_bool,mode,d_prime_thr);


%% example processing for repRate experiment
IC_SeriesID='GEK030_0007';
t_start=3;
t_stop=125;
% load existing icme object
  enablecache on
 IC=loadIcme(icme(ee,IC_SeriesID));
% make a raster plot (only some elecs becasue otherwise too many
% points in  plot
stim_criteria_array=[4,10,300;1,30,34]; % look at stimulli between 10 and 500 Hz in the range of 30-34 mW 
elecs=[22,23];
[fig] = makeRasterPlot(IC,stim_criteria_array,elecs);
    
    % plot PSTH for one rate with artefact removal
    rate=20;
    stim_criteria_array=[4,rate,rate;1,30,34]; % look at stimulli between 10 and 500 Hz
    elecs = getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop);
    stimdur_ix=10;
    t_start = -10;  % time before stimulus onset
    t_stop  =  115; % time after stimulus onset
    PSTH_binsize = 0.5; % 0.25 ms used in Maria Michael 2023 paper
    plot_bool=1; % to create figures or just do the temporal analysis 
    artefact_removal=1;
    [PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,t_start,t_stop,PSTH_binsize );
    % without artefact removal
    artefact_removal=0;
    [PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,t_start,t_stop,PSTH_binsize );
    % plot SR and d' plots 
    stim_criteria_array=[4,10,500;1,30,34]; % look at stimulli between 10 and 500 Hz in the range of 30-34 mW 
    plotHeatmapsIC(IC,'SR',stim_criteria_array,t_start,t_stop) % plot
    plotHeatmapsIC(IC,'dPrimeBaseline',stim_criteria_array,t_start,t_stop) % plot
   
        % whole analysis
        stim_criteria_array=[4,10,300;1,30,34]; % look at stimulli between 10 and 500 Hz in the range of 30-34 mW 
        t_start=0;
        t_stop=115;
        elecs = getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop);
        % calculate important parameters
        [rates,meanSpikeRates_respUnits,SpikesPerStimulus_respUnits,VS_array_respUnits,cutoff_fqs,all_phases] = runRepRateAnalysis(IC,stim_criteria_array,t_start,t_stop,elecs);
        num_responsive_units=size(SpikesPerStimulus_respUnits,1);
        % plot
        figure
        subplot(2,2,1)
        errorbar(rates,mean(SpikesPerStimulus_respUnits),std(SpikesPerStimulus_respUnits),'r','HandleVisibility','on','DisplayName',sprintf('f-Chrimson %i MUs',num_responsive_units))
        ylabel('spikes per stimulus')
        xlabel('stimulation rate [Hz]')
        legend()
        title(IC.SeriesID,'Interpreter','none')
        subplot(2, 2, 2); 
        hold on;
        [cdfhandle, cdfstats] = cdfplot(cutoff_fqs); 
        cdfhandle.Color='r';
        title('cut-off frequency')
        xlabel('stimulation rate [Hz]'); 
        ylabel('fraction of units');
        set(gca, 'ytick', [0:0.2:1]); 
        subplot(2,2,3)
        errorbar(rates,mean(VS_array_respUnits),std(VS_array_respUnits),'r')
        ylabel('VS')
        xlabel('stimulation rate [Hz]')
        subplot(2,2,4)
        errorbar(rates,mean(meanSpikeRates_respUnits),std(meanSpikeRates_respUnits),'r')
        ylabel('spikerate [Hz]')
        xlabel('stimulation rate [Hz]')
        
    

%% example processing for pulse dur experiment
  IC_SeriesID='GEK030_0006';
 t_start=3;
 t_stop=30;
% load existing icme object
enablecache on
IC=loadIcme(icme(ee,IC_SeriesID));
% analyse the d' and plot for only the duration changing (by
% filtering for a specific intensity
stim_criteria_array=[3,0,5;1,16,16];% changing pulse dur, intensity fixed to 16 mW
elecs=getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop);
d_prime_results= calculateDprime(IC,'increasingLvl',stim_criteria_array,t_start,t_stop); 
d_prime_results= calculateDprime(IC,'baseline',stim_criteria_array,t_start,t_stop);
plotHeatmapsIC(IC,'SR',stim_criteria_array,t_start,t_stop)
plotHeatmapsIC(IC,'dPrimeCum',stim_criteria_array,t_start,t_stop)
plotHeatmapsIC(IC,'dPrimeBaseline',stim_criteria_array,t_start,t_stop)
y_label='stim duration [ms]';
[fig] = makeRasterPlot(IC,stim_criteria_array,elecs,y_label);

% analyse with pulse- dur as x-axis but all intensities at once
stim_criteria_array=[3,0,5;1,0,32];
fig_dp =plotHeatmapsIC(IC, 'SR_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes

% analyse with pulse- amp as x-axis separated by pulse dur
stim_criteria_array=[1,0,32;3,0,5];
fig_dp =plotHeatmapsIC(IC, 'SR_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
   
   

