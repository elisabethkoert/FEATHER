%% this is an example script on how to use FEATHER locally 
% you need to have a local drive/data folder that contains both your raw data and
% the processed data directory with your usersdata somewhere along its path
% the structure shoudl look like this
%--your local disc/fodler
% ------ rawData
% ------------Animal1
%-------------Animal2
%--------processedData
%-------------XYdata
%-------------EKdata

clear all; close all; clear global;

% FEATHER toolbox filepath
% tb_path =  horzcat('C:\Users\Administrator\Desktop\GitFolders\FEATHER\invivoephysfeather'); % DS WS
tb_path = 'C:\Users\koert.GWDG\FoldersUnderGitControl\feather\invivoEphysFEATHER'; % EK office PC

addpath(genpath(tb_path));

% map to your local disc or a higher up folder that is still part of both
% the raw and processed data directories
tmp_ukonmap = 'C:';
ukonmap(tmp_ukonmap);

% change the default processed data dir path starting from your ukonmap
% local folder
 processedDataDirPath('set', 'Users\koert.GWDG\localData\processedData')

% set UserID for this analysis to determine where processed data gets
% stored
userID('EK'); 

%% Get info for the animal
ExpID='GEK030';
 % path parts from the UKONMAP to the raw data
rawDatadir=  ["Users","koert.GWDG","localData","rawData","GEK030"];
experimenterID='test';

enablecache off % make sure you load raw data
D(1).dir =rawDatadir;
D(1).type ="ABR";
ee = anex(ExpID, experimenterID, D);
D = expProcDataDir(experimenterID,ExpID)
initProcessedExp(ee) % creates save folder
saveAnex(ee);%updates the ee

%% load existing Anex
enablecache on
ee = anex(ExpID, 'test'); 
ee=loadAnex(ee);

%% test ABR analysis
enablecache off % make sure you load raw data
allBerabr(ee) % handles preprocessing for all expeirments in this folder (G0XX)
exploreBerabr(ee) %opens GUI to click on waves



% and continue with analysis as normal

