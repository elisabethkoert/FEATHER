function allIcme (obj)
    % anex\allIcme finds all IC raw data log files and initializes the icme objects
    L = listIcRaw(obj);
    initIcmeFolder(obj);
    for ii = 1 : numel(L.IC_SeriesID)
        I = icme (obj,L.IC_SeriesID(ii),L.rawDataDir); % create object and assign the raw data directory. Tis will be used toimport the raw data.
        I = initIcme(I); % read in info from log file
        saveIcme(I); % save ICME
        fprintf('icme initialization done for %s \n',L.IC_SeriesID(ii))
    end
end