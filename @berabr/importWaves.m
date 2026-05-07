function W = importWaves (B)
% berabr\import_waves imports the user wave annotations that are stored in
% the same processed data directory, following BERA and EXPERIMENT naming.
if numel(B )==1
    import_name = strcat(expProcDataDir,"\W_",B.ExpID,"_",B.SeriesID,".mat");
    if isfile(import_name)
        tmpW = open(import_name);% this will be W
        W = tmpW.W;
    else
        W=[];
        fprintf('no W_ file found for %s',B.SeriesID)
    end
elseif numel(B)>1
    for ii = 1 : numel(B)
        import_name = strcat(expProcDataDir,"\W_",B(ii).ExpID,"_",B(ii).SeriesID,".mat");
        if isfile(import_name)
            tmpW = open(import_name);% this will be W
            W(ii) = tmpW;
        else
            W=[];
            fprintf('no W_ file found for %s',B.SeriesID)
        end

    end
end