% THis scirpt can be run to test the analysis after git merges
% it currently contains the detailed ABR, IC and Histo analysis for one example
% experiment (GEK030), 

% make sure the toolbox and UKON is mapped correctly in your current MATLAB window
clear all; close all; clear global;

% toolbox filepath
% tb_path =  horzcat('C:\Users\Administrator\Desktop\GitFolders\FEATHER\invivoephysfeather'); % DS WS
tb_path = 'C:\Users\koert.GWDG\FoldersUnderGitControl\feather\invivoEphysFEATHER'; % EK office PC

addpath(genpath(tb_path));

% ukon100 drive mapping
tmp_ukonmap = 'Z:\UKON100';
ukonmap(tmp_ukonmap);

% set UserID for this analysis to determine where processed data gets
% stored
userID('EK'); 





%% Get info for the animal
ExpID='GEK030';
 % path parts from the UKONMAP to the raw data
rawDatadir=  ["archiv","systems","AllDataTypesForAnalysisTests","GEK030"];
experimenterID='test';


%% create new Anex (since usually analysis starts with ABR)
enablecache off % make sure you load raw data
D(1).dir =rawDatadir;
D(1).type ="ABR";
ee = anex(ExpID, experimenterID, D);
ee = setAnimalSpecies(ee,'dinosaur'); % just making sure the correct anex gets loaded =)
initProcessedExp(ee) % creates save folder
initKiwi(ee) % notes file for the anex
saveAnex(ee);%updates the ee

%% load existing Anex
enablecache on
ee = anex(ExpID, 'test'); 
ee=loadAnex(ee);

%% test ABR analysis
enablecache off % make sure you load raw data
allBerabr(ee) % handles preprocessing for all expeirments in this folder (G0XX)
waitfor(exploreBerabr(ee) )%opens GUI to click on waves
waitfor(userberabrOD(ee))% add density filters manually in a GUI

% beraABR values are never ead in during stimulation so the calibrated
% stimulus list needs to be interpolated
setCalibrationBeraFromLaserControl(ee)
enablecache off % make sure you load raw data
[ExpIntThrAcoustic] = intensityThreshold(ee, 'Acoustic')
[ExpIntThrOptical] = intensityThreshold(ee, 'Optical')

saveAnex(ee);%updates the ee

% get the max P1N1 amplitude for a specific sitmulation type over all BERABRs
[MaxABRValues] = ABRMaxWaveValues(ee, 'Acoustic');
[MaxABRValues] = ABRMaxWaveValues(ee, 'Optical');


% options to work with analysed ABR data
enablecache on % make sure you load raw data
Bs=listBerabr(ee);
aABR=loadBerabr(berabr(ee,string(Bs.ABR_SeriesID(2))));
aABR.Stim.intensity % presented intensities in %
% aABR.C.Ical %presented intensities in mW, does not work for acoustic yet
aABR.ExpInfo.ProtokollSetting
aABR.Stim.modality % gives acoustiv vs optical
aABR.plotBerabr
aABR.ttlString


%% analysing IC data
% add raw data dir
D_cur=ee.RawDataDir;
D_cur(end+1).dir=ee.RawDataDir(find([ee.RawDataDir.type]=='ABR')).dir;
D_cur(end).type = "IC" ;
ee = setRawDataDir(ee,D_cur);
saveAnex(ee);

% initialise ICME objects from raw data .m log files (fillst the icme.stim with stim info)
enablecache off
allIcme(ee) %  preprocessing/loading all the .m log files and creating Icme objects containing this info 

% give user input (eg. which filter has been used, saved in a sepearte user input table)
waitfor(ICuserInput(ee))




% load the user input table
enablecache on
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
load(in_dir_name);%loads UT, containing user input and stimulus types for each icme


% run spike extraction and add calibration for each icme
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






 %% pulse intensity protocol/ SoE
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
SoE_results=calculateSOE(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
SoE_results=calculateSOE(IC,'baseline',stim_criteria_array,t_start,t_stop);
% get responsive units & plot PSTH (only from responsive units)
psth_t_start = -10;  % time before stimulus onset
psth_t_stop  = 60; % time after stimulus onset
PSTH_binsize = 0.25; % 0.25 ms used in Maria Michael 2023 paper
plot_bool=1; % to create figures or just do the temporal analysis
artefact_removal=1;
stimdur_ix=10; %[s]
[PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,psth_t_start,psth_t_stop,PSTH_binsize )
    


 %% tonotopy experiment
 IC_SeriesID='GEK030_0001';
 t_start=5;
 t_stop=125;
% load existing icme object
  enablecache on
 IC=loadIcme(icme(ee,IC_SeriesID));
 [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,t_start,t_stop); % get spikerates
 
 % look only at 1 frequency
 stim_criteria_array=[4,0,90;1,16000,16000]; % only 16 kHz stimuli, all SPL intensities 
 fig_dp =plotHeatmapsIC(IC, 'SR',stim_criteria_array,t_start,t_stop); % plot SR
fig_dp2 =plotHeatmapsIC(IC, 'SR_MSV',stim_criteria_array,t_start,t_stop); % plot SR, same plot but different funciton called that allows for plotting multiple freqs
fig_dp =plotHeatmapsIC(IC, 'dPrimeCum',stim_criteria_array,t_start,t_stop); % plot dPrimes cumulative sum
fig_dp2 =plotHeatmapsIC(IC, 'dPrimeCum_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes cumulative sum
fig_dp =plotHeatmapsIC(IC, 'dPrimeBaseline',stim_criteria_array,t_start,t_stop); % plot dPrimes baseline
fig_dp =plotHeatmapsIC(IC, 'dPrimeBaseline_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes baseline



 % range of stimuli 
stim_criteria_array=[4,0,90;1,500,32000];
fig_dp =plotHeatmapsIC(IC, 'SR_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
[all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
[all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
fig_dp =plotHeatmapsIC(IC, 'dPrimeCum_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
fig_dp =plotHeatmapsIC(IC, 'dPrimeBaseline_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
       
% SoE
all_SoE_results = calculateSOEMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
all_SoE_results_baseline = calculateSOEMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
all_SoE_results_Contour = calculateSOEContourlinesMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
all_SoE_results_Contour_baseline = calculateSOEContourlinesMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
all_SoE_results_Contour_atBE = calculateSOEContourlinesMultipleStimVarsAtBE(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
all_SoE_results_Contour_baseline_atBE = calculateSOEContourlinesMultipleStimVarsAtBE(IC,'baseline',stim_criteria_array,t_start,t_stop);

 % PSTH
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


% tonotopy analysis 
%  sort by freq and go for d'=1 treshold
plot_bool=1;
d_prime_thr=1;
mode='increasingLvl';
[tonotopy_array_byFreq1, tonotopy_slope,elec_best_freq_array,elec_freq_thr_array] =calculateTonotopicSlope(IC,plot_bool,mode,d_prime_thr);
% sort by freq and go for d'=2 treshold
d_prime_thr=2;
mode='increasingLvl';
[tonotopy_array_byFreq2, tonotopy_slope,elec_best_freq_array,elec_freq_thr_array] =calculateTonotopicSlope(IC,plot_bool,mode,d_prime_thr);

% sort by electrode this one autumatically plots heatmaps if
% plotbool is on
d_prime_thr=2;
mode='increasingLvl';
[tonotopy_array3, tonotopy_slope3,elec_best_freq_array3,elec_freq_thr_array3]=calculateTonotopicSlopeSortedbyElectrode(IC,plot_bool,mode,d_prime_thr);

        


   

    %% repRate experiment
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
    stim_criteria_array=[4,rate,rate]; % look at stimulli between 10 and 500 Hz
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
        
    

    %% pulse dur experiment
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
    [all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
    [all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
    fig_dp =plotHeatmapsIC(IC, 'dPrimeCum_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
    fig_dp =plotHeatmapsIC(IC, 'dPrimeBaseline_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes

    % analyse with pulse- amp as x-axis separated by pulse dur
    stim_criteria_array=[1,0,32;3,0,5];
    fig_dp =plotHeatmapsIC(IC, 'SR_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
    [all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
    [all_d_prime_results] = calculateDprimeMultipleStimVars(IC,'baseline',stim_criteria_array,t_start,t_stop);
    fig_dp =plotHeatmapsIC(IC, 'dPrimeCum_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes
    fig_dp =plotHeatmapsIC(IC, 'dPrimeBaseline_MSV',stim_criteria_array,t_start,t_stop); % plot dPrimes

    % get responsive units & plot PSTH (only from responsive units)
    stim_criteria_array=[1,5,32;3,2,2];
    elecs=getResponsiveUnits(IC,stim_criteria_array,t_start,t_stop); 
    t_start = -10;  % time before stimulus onset
    t_stop  = 60; % time after stimulus onset
    PSTH_binsize = 0.25; % 0.25 ms used in Maria Michael 2023 paper
    plot_bool=1; % to create figures or just do the temporal analysis
    artefact_removal=1;
    stimdur_ix=10; %[s]
    [PSTH_norm,PSTH,bin_centers,resp_idx, t_onset,t_offset,peak_response_time] = calculatePSTH(IC,stim_criteria_array,elecs,plot_bool,artefact_removal,stimdur_ix,t_start,t_stop,PSTH_binsize );





% get thresholds for IC
enablecache off
dPrimeMode='baseline'
intensityThresholdIC(ee,  dPrimeMode)

dPrimeMode='increasingLvl'
intensityThresholdIC(ee,  dPrimeMode)

intensityThresholdIC(ee,'baseline','MX_tones',[4,0,90;1,500,32000])


%% test histo analysis
% add the histo dir if it does not exist
D_cur=ee.RawDataDir;
histoDir= ["archiv","systems","AllDataTypesForAnalysisTests","GEK030","Histo"];
ix=find(strcmp([D_cur.type],'NintendoRes'));
if ~isempty(ix)
    D_cur(ix).dir=histoDir;
else
    D_cur(end+1).dir=histoDir;
    D_cur(end).type = "NintendoRes" ;
end
ee = setRawDataDir(ee,D_cur);
saveAnex(ee);
enablecache off
initHistoFolder(ee)

% actually analyse the histo data by creating histimg objects for all
% existing analysed images
enablecache off
HistImgsRaw=listHistImgsRaw(ee);
list_cochleae_pos=HistImgsRaw.HistImg_SeriesID;
NintendoRes_ix = find([ee.RawDataDir.type] == "NintendoRes");
D_Nintendo=ee.RawDataDir(NintendoRes_ix);
for img_ix=1:length(list_cochleae_pos)
    histImg=histimg(ee,string(list_cochleae_pos(img_ix)),D_Nintendo,HistImgsRaw.Filenames{img_ix});
    [histImg,check]=readNintendoResults(histImg);
    if check==1
        saveHistimg(histImg);
    end
end

enablecache off
% make overview list of availabilities
HistImgs=listHistImg(ee);
waitfor(chooseHistImgToUse(ee))% user input
enablecache off

HistoRes=getHistoResults(ee);

%% load & process a second anex with IC recordings

ExpID='gjg131644';
experimenterID='test';
rawDatadir=  ["archiv","systems","AllDataTypesForAnalysisTests","gjg131644"];

%% create new Anex (since usually analysis starts with ABR)
enablecache off % make sure you load raw data
D(1).dir =rawDatadir;
D(1).type ="ABR";
D(2).dir =rawDatadir;
D(2).type ="IC";
ee = anex(ExpID, experimenterID, D);
ee = setAnimalSpecies(ee,'gerbil');
initProcessedExp(ee) % creates save folder
saveAnex(ee);%updates the ee

enablecache on
ee = loadAnex(anex(ExpID, experimenterID));

%% test ABR analysis
enablecache off % make sure you load raw data
allBerabr(ee) % handles preprocessing for all expeirments in this folder (G0XX)
waitfor(exploreBerabr(ee) )%opens GUI to click on waves
waitfor(userberabrOD(ee))% add density filters manually in a GUI
setCalibrationBeraFromLaserControl(ee)
enablecache off % make sure you load raw data
[ExpIntThrAcoustic] = intensityThreshold(ee, 'Acoustic')
[ExpIntThrOptical] = intensityThreshold(ee, 'Optical')
saveAnex(ee);%updates the ee

% short IC analysis 
enablecache off
allIcme(ee) %  preprocessing/loading all the .m log files and creating Icme objects containing this info 
% give user input (eg. which filter has been used, saved in a sepearte user input table)
waitfor(ICuserInput(ee)) % calibration not done tick needs to be marked

enablecache on
% load the user input table
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
load(in_dir_name);%loads UT, containi

% run spike extraction and add calibration for each icme
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
    %% calcualte the calibration 

    % If the ExpControl Version only used Laser Power % as output, we need
    % to interpolate the actual intensity values from the calibration file
    % not the case for this test data
    enablecache off
    OD=UT.data{ix_in_UT,find(contains(UT.fieldNames,'Filter'))};
    ComPort=UT.data{ix_in_UT,find(contains(UT.fieldNames,'Port'))};
    IC= calculateCalibration(IC,OD,ComPort);
   

    %% extract the MU activity from the raw data 
   enablecache off
   IC = ExtractMUAfromRawDataIntoSL(IC);
   saveIcme(IC);
end


%% run functions on multpile experiments
ExpIDs={'gjg131644','GEK030'};

ee_list={};
for exp_i=1:length(ExpIDs)
    % load experiment
    ExpID=ExpIDs{exp_i};
    enablecache on
    ee = loadAnex(anex(ExpID, 'test'));
    ee_list{exp_i}=ee
end

% plot PSTH for single 1 ms pulses
Exp_type='OBIS_LS594_PulseTrain_Attenuation';
stim_criteria_array=[1,0,60;3,1,1]; % (collum in stimlist, min value, max value) exp. [1,5,60;3,1,1] a pulse btw 5 and 60 mW with a duration of 1 ms
artefact_removal=1;
stimdur=1/1000; % [s]
t_start = -10;  % time before stimulus onset
t_stop  =  50; % time after stimulus onset
PSTH_binsize = 0.25; % 0.25 ms used in Maria Michael 2023 paper
plot_bool=1; % to create figures or just do the temporal analysis
[PSTH_norm,PSTH,bin_centers,resp_idx,t_onset,t_offset,peak_response_time] = calculatePSTHanex(ee_list,Exp_type,stim_criteria_array,plot_bool,artefact_removal,stimdur,t_start,t_stop,PSTH_binsize);

% plot repRate PSTHs
for rate=[20,100,300]
    Exp_type='OBIS_LS594_PulseTrain_f_train';
    stim_criteria_array=[1,30,34;4,rate,rate]; % (collum in stimlist, min value, max value) exp. [1,500,32000;4,50,90] a pure tone btw 500 and 32000 Hz with 50-90 dB
    artefact_removal=1;
    stim_dur=0.1; 
    t_start = -10;  % time before stimulus onset
    t_stop  =  150; % time after stimulus onset
    PSTH_binsize = 0.25; % 0.25 ms used in Maria Michael 2023 paper
    plot_bool=1; % to create figures or just do the temporal analysis
    [PSTH_norm,PSTH,bin_centers,resp_idx,t_onset,t_offset,peak_response_time] = calculatePSTHanex(ee_list,Exp_type,stim_criteria_array,plot_bool,artefact_removal,stim_dur,t_start,t_stop,PSTH_binsize);
    h1=get(gca,'title').String;
    new_title=[num2str(rate) ' Hz: '  h1];
    title(new_title)
end

