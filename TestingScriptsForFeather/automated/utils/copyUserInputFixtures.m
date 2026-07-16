function ok = copyUserInputFixtures(ExpID, ExperimenterID)
% copyUserInputFixtures - copies pre-recorded user-input annotation files
% from <rawData>/<ExpID>/UserInputCopies/ into the processed-data folder,
% so automated tests bypass GUI interaction entirely.
%
% Must be called with the relevant init*Folder already having run
% (initProcessedExp / initIcmeFolder / initHistoFolder as appropriate),
% since ICME/ and HISTO/ subfolders must already exist as copy targets.
%
% Returns ok=true if at least one fixture file was found/copied.

srcDir = gen_dir_name([testRawDataRoot, ExpID, "UserInputCopies"]);
ok = false;
if ~isfolder(srcDir)
    return
end

destRoot = expProcDataDir(ExperimenterID, ExpID);

% ABR fixtures -> root of processed folder
ok = localCopy(fullfile(srcDir, sprintf('ODui_%s.mat', ExpID)), destRoot) || ok;
Wfiles = dir(fullfile(srcDir, sprintf('W_%s_*.mat', ExpID)));
for k = 1:numel(Wfiles)
    ok = localCopy(fullfile(Wfiles(k).folder, Wfiles(k).name), destRoot) || ok;
end

% IC fixture -> processed/ICME/
icDest = fullfile(destRoot,'ICME');
if ~isfolder(icDest); mkdir(icDest); end
ok = localCopy(fullfile(srcDir, sprintf('ICUserInput_%s.mat', ExpID)), icDest) || ok;

% Histo fixture -> processed/HISTO/
histDest = fullfile(destRoot,'HISTO');
if ~isfolder(histDest); mkdir(histDest); end
ok = localCopy(fullfile(srcDir, sprintf('HistoUserInput_%s.mat', ExpID)), histDest) || ok;

end
function didCopy = localCopy(src, destDir)
didCopy = isfile(src);
if didCopy
    copyfile(src, destDir);
end
end