function allBerabr (obj)
    % anex\allBerabr finds all ABR raw data files and initializes the berabr objects
    L = listBerabrRaw(obj);
    for ii = 1 : numel(L.ABR_SeriesID)
        b = berabr (obj,L.ABR_SeriesID(ii),L.rawDataDir); %assign the raw data directory. Tis will be used toimport the raw data.
        b = initBerabr(b);
        ii;
    end
end