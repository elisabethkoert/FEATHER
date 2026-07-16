function result = runHistoPipeline(ExpID)
% runHistoPipeline - GUI-free histology pipeline: registers the
% NintendoRes raw directory, creates histimg objects from all available
% .csv exports, applies the pre-recorded chooseHistImgToUse fixture, and
% computes the anex-wide summary via getHistoResults.

ExperimenterID = getExperimenterFromExpID(ExpID);
rawDataDir = [testRawDataRoot, ExpID];
histoDir = [rawDataDir, "Histo"];

ee = getOrCreateTestAnex(ExpID, ExperimenterID, histoDir, "NintendoRes");

enablecache off
initHistoFolder(ee);

HistImgsRaw = listHistImgsRaw(ee);
result = struct('ExpID', ExpID);
result.numRawImages = numel(HistImgsRaw.HistImg_SeriesID);

NintendoRes_ix = find([ee.RawDataDir.type] == "NintendoRes");
D_Nintendo = ee.RawDataDir(NintendoRes_ix);

for img_ix = 1:numel(HistImgsRaw.HistImg_SeriesID)
    histImg = histimg(ee, string(HistImgsRaw.HistImg_SeriesID(img_ix)), ...
        D_Nintendo, HistImgsRaw.Filenames{img_ix});
    [histImg, check] = readNintendoResults(histImg);
    if check == 1
        saveHistimg(histImg);
    end
end

copyUserInputFixtures(ExpID, ExperimenterID);

histoUserInputFile = fullfile(expProcDataDir(ExperimenterID,ExpID),'HISTO', ...
    sprintf('HistoUserInput_%s.mat', ExpID));
result.hasHistoUserInput = isfile(histoUserInputFile);

if result.hasHistoUserInput
    enablecache off
    result.HistoRes = getHistoResults(ee);
end

end