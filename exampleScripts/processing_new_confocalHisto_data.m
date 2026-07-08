%% This is an example on how to analyse new histology results obtained with the confocal microscope and Arivis pipeline
% we assume that the anex was already initialized during the ABR analysis
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

% initiate the histimg objects and fill in the results from the
% Arivis/Nintendo pipeline
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

% get the results from L & R cochlea from all turns and save in the
% processed data dir
enablecache off
HistoRes=getHistoResults(ee);
