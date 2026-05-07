clear all; close all; clear global;
% toolbox filepath
tb_path =  horzcat('C:\Users\Administrator\Desktop\GitFolders\FEATHER\invivoephysfeather'); % DS WS
addpath(genpath(tb_path));
% ukon drive mapping
tmp_ukonmap = 'Z:\UKON100';
ukonmap(tmp_ukonmap);
% set UserID for this analysis to determine where processed data gets
% stored
userID('EK'); 


%% test an experiment that has 2 Lasertypes
ExpID='gth212308';
Experimenter_ID='TH';

rawDatadir=  ["archiv","systems","AllDataTypesForAnalysisTests","gth212308"];
experimenterID('test');

enablecache off % make sure you load raw data
D(1).dir =rawDatadir;
D(1).type ="ABR";
ee = anex(ExpID, experimenterID, D);
ee = setAnimalSpecies(ee,'gerbil');
initProcessedExp(ee) % creates save folder
initKiwi(ee)
saveAnex(ee);%updates the ee

% %% ABR data input and thresholding
enablecache off % make sure you load raw data
allBerabr(ee) % handles preprocessing for all expeirments in this folder (G0XX)
waitfor(exploreBerabr(ee) )%opens GUI to click on waves
waitfor(userberabrOD(ee))% add density filters manually in a GUI
setCalibrationBeraFromLaserControl(ee)
enablecache off % make sure you load raw data
[ExpIntThrAcoustic] = intensityThreshold(ee, 'Acoustic')
[ExpIntThrOptical] = intensityThreshold(ee, 'Optical')
saveAnex(ee);%updates the ee

% IC data analysis
D_cur=ee.RawDataDir;
D_cur(end+1).dir=ee.RawDataDir(find([ee.RawDataDir.type]=='ABR')).dir;
D_cur(end).type = "IC" ;
ee = setRawDataDir(ee,D_cur);
saveAnex(ee);
enablecache off
allIcme(ee) %  preprocessing/loading all the .m log files and creating Icme objects containing this info 
waitfor(ICuserInput(ee))
calibDir=ee.RawDataDir(find([ee.RawDataDir.type]=='IC')).dir;
enablecache off
    
% load the user input table
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
load(in_dir_name);%loads UT, containing user input and stimulus types for each icme
    
enablecache on
L =listIcme(ee);
analysis_failed_list={};
for ii = 1: numel(L.IC_SeriesID)
    ix_in_UT= cellfun(@(x) strcmp( x ,string(L.IC_SeriesID(ii))),UT.data(:,find(contains(UT.fieldNames,'SeriesID'))));
    if UT.data{ix_in_UT,find(contains(UT.fieldNames,'Use'))}== -1  % skip the experiments marked as bad
        continue
    end
    % load existing icme object
    enablecache on
    IC=loadIcme(icme(ee,string(L.IC_SeriesID(ii))));
    disp(L.IC_SeriesID(ii))
    %read in claibration
    enablecache off
    OD=UT.data{ix_in_UT,find(contains(UT.fieldNames,'Filter'))};
    ComPort=UT.data{ix_in_UT,find(contains(UT.fieldNames,'Port'))};
    IC= getCalibration(IC,OD,ComPort) ;
     % IC= calculateCalibration(IC,OD,ComPort) ; % if not read in during experiment like in BERA
    saveIcme(IC);              
    % initializing the SL from raw data (needs Workstation or veryyy slow)
    %skip this part if RESORT file already exists in the processed data
    %dir
    try
        enablecache off
        IC = ExtractMUAfromRawDataIntoSL(IC);       
        saveIcme(IC);
    catch
        analysis_failed_list{end+1}=IC.SeriesID;
    end
  
end

% get IC thresholds
enablecache off
[ExpIntThrAcoustic] = intensityThresholdIC(ee,'increasingLvl','OBIS_LS594_PulseTrain_LaserPower')
[ExpIntThrAcoustic] = intensityThresholdIC(ee,'increasingLvl','DarkRedLaser_PulseTrain_Amp')
  


