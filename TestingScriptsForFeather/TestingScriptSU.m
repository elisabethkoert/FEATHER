clear all; close all; clear global;
% toolbox filepath
tb_path =  horzcat('C:\Users\Administrator\Desktop\GitFolders\FEATHER\invivoephysfeather'); % DS WS
addpath(genpath(tb_path));

% ukon drive mapping to UKON100 on COmputer
tmp_ukonmap = 'Z:';
ukonmap(tmp_ukonmap);

% set UserID for this analysis to determine where processed data gets
% stored
userID('EK'); 

%% Get info for the animal
%W:\archiv\systems\2023\10\AV\mav181065
ExpID='mav181065';
rawDatadir=  ["archiv","systems","AllDataTypesForAnalysisTests","mav181065"];
experimenterID('test');


%% create new Anex 
enablecache off % make sure you load raw data
D(1).dir =rawDatadir;
D(1).type ="ABR";
D(2).dir =rawDatadir;
D(2).type ="SU";
ee = anex(ExpID, experimenterID, D);
ee = setAnimalSpecies(ee,'mouse');
initProcessedExp(ee) % creates save folder
saveAnex(ee);%updates the ee

%%
enablecache on
ee = anex(ExpID, 'test'); 
ee=loadAnex(ee);

%%
enablecache off
L = listSuRaw(ee)
enablecache on
uiSU(ee)%unit assignemnt
enablecache on
ee=loadAnex(ee);
uiSUee(ee)%there you might need to manually set the cache on and off and then check that the anx file has been updated - tgis info is stored in the E_ structure
enablecache off
allSunit(ee)
allSutr (ee)
% calibration
winopenR(ee) %copy the calibration in the processed data file
winopenP(ee)
userberabrOD(ee)%for optical green laser measurements, jsut export the empty table. its vestigual
% setCalibration2(ee,[])%for abr
setCalibrationSU(ee,[])% for SU
%GUIs to play
exploreSU(ee)






