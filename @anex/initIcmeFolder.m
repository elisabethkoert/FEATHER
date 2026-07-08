function initIcmeFolder (obj)
    % anex/initIcmeFolder initializes the ICME subfolder in the ProcessedDataDir
    testSafeDir (fullfile(getProcessedDataDir(obj),'ICME','IC'));
    if  isfolder(fullfile(getProcessedDataDir(obj),'ICME','IC')) == 0
        mkdir(fullfile(getProcessedDataDir(obj),'ICME','IC'));
        saveAnex(obj);
    elseif  isfolder(fullfile(getProcessedDataDir(obj),'ICME','IC')) == 1
        warning('Experiment is already initialized, overwrite aborted.');
    end
end