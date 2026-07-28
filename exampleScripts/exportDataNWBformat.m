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

nwbFilename='GEK030_ABR_only.nwb';

ee2=createFeatherObjectsFromNWB(nwbFilename, nwbDir,'overwrite', true);



