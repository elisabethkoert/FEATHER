function initHistoFolder(obj)
    % anex/initHistoFolder initializes the HISTO subfolder in the ProcessedDataDir
    testSafeDir (fullfile(getProcessedDataDir(obj),'HISTO'));
    if  isfolder(fullfile(getProcessedDataDir(obj),'HISTO')) == 0
        mkdir(fullfile(getProcessedDataDir(obj),'HISTO'));
        saveAnex(obj);
    elseif  isfolder(fullfile(getProcessedDataDir(obj),'HISTO')) == 1
        warning('Experiment is already initialized, overwrite aborted.');
    end
end