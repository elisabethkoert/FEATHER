%% This script is run first to set up the toolbox
clear all; close all; clear global;

%% setting up the feather toolbox
% add the toolbox path to your MATLAB
tb_path = 'C:\Users\koert.GWDG\FoldersUnderGitControl\feather\invivoEphysFEATHER';
addpath(genpath(tb_path));

%% set the data paths for raw and processed data
% raw data mapping
map_raw_data = 'W:\UKON100';
ukonmap(map_raw_data);
% processed data mapping
tmp_processed_data_map = 'Z:\UKON100';
processedDataMap(tmp_processed_data_map);
% if you have a specific path to the processed data, set it. 
% Here we just load and set the IAN standard as an example.
p=processedDataDirPath('get');
processedDataDirPath('set', p);

userID('EK'); % this is the user ID, or the analyzer

% set enable cache, this is a persistent variable to ensure control over the 
% caching behavior of the analysis, if set to on already processed data gets
% loaded if available, if set to off we reanalyse from scratch and overwrite 
% saved processed data
enablecache ('on'); 
