%% example script explaining how to work with the NWB format
% you need to have the MATNWB toolbox pulled to an accessile location on
% your computer


% start by cleaning up your workspace
clearvars -except ukonmap; close all;

%% add matnwb toolbox that allows for loading and saving in the NWB data format
nwb_path = 'C:\Users\koert.GWDG\FoldersUnderGitControl\matnwb';
addpath(genpath(nwb_path));


%% Export FEATHER into NWB format
ExpID = "GEK030";
experimenterID = "EK";
outDir = 'C:\Users\koert.GWDG\localData\NWBdata';

enablecache on
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);


% export every ABR, IC and Histoimage it finds for this experiment
nwb = exportFeatherToNWB(ee,'outputDir',outDir);
% sanity check
printAllNWBTables(nwb);

% export only interesting ABRs
Bs_to_Export={};
res=ee.intensityThreshold('Acoustic');
Bs_to_Export{end+1}=char(res.B.SeriesID);
res=ee.intensityThreshold('Optical');
Bs_to_Export{end+1}=char(res.B.SeriesID);

ICs={'GEK030_0001','GEK030_0003'};

% Export only specific ABRs and ICs
nwbABROnly = exportFeatherToNWB(ee, ...
    'exportHisto', false, ...
    'exportIC', false, ...
    'abrSeriesIDs', Bs_to_Export, ...
    'outputDir',outDir,...
    'filename','GEK030_ABR_only.nwb' );

printAllNWBTables(nwbABROnly);

%% load NWB data into FEATHER
userID('NWBTEST') % makes sure you do not overwrite your already processed data

nwbDir = 'C:\Users\koert.GWDG\localData\NWBdata';


ExpID = "GEK030";
nwbFilename=sprintf('%s.nwb', ExpID);


ee = createFeatherObjectsFromNWB(nwbFilename, nwbDir,'overwrite', true);

%% test Bera functions
% threshold calcuation
enablecache off % make sure you load raw data
[ExpIntThrAcoustic] = intensityThreshold(ee, 'Acoustic');
[ExpIntThrOptical] = intensityThreshold(ee, 'Optical');

% GUI interaction
enablecache on
exploreBerabr(ee)
userberabrOD(ee)

% example plot
enablecache('on') % load already processed data
Bs=listBerabr(ee); % get a list of all berabr object

% load a single ABR recording and plot every second trace
B=loadBerabr(berabr(ee,string(Bs.ABR_SeriesID(1))));
figure
hold on
for ii =1:2:B.nTraces 
    plot(B.F(ii).t*1e3, B.F(ii).ABR*1e6);
end
xlabel('Time (ms)')
ylabel('Amplitude (\muV)','interpreter','Tex')
title('aABR traces')

%% test icme functions

% get thresholds
enablecache off
% optic all RW 200 µm fibers
dPrimeMode='baseline';
optThr=intensityThresholdIC(ee,  dPrimeMode);
% acoustic for each frequency
acoustThr=intensityThresholdIC(ee,'baseline','MX_tones',[4,0,90;1,500,32000]);

% GUI interactions
ICuserInput(ee)

% example processing for pulse intensity protocol/ SoE
IC_SeriesID='GEK030_0004';
t_start=3;
t_stop=25;
enablecache on
IC=loadIcme(icme(ee,IC_SeriesID));
[meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,t_start,t_stop); % get spikerates
stim_criteria_array=[1,0,60;3,1,1]; % 0 to 30 mW, 1 ms stimuli
d_prime_results = calculateDprimeMultipleStimVars(IC,'increasingLvl',stim_criteria_array,t_start,t_stop);
plotHeatmapsIC(IC,'SR',stim_criteria_array,t_start,t_stop)
