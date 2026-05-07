function [L,LR] = listIcRaw (ee)
% anex\listIcRaw lists all icmes in rawDataDir based on ExpControl log files
% complies a list of all the IC measurements in the raw
% data folder. Only IC experiemnt control output files are presented.
% L : the list sorted according to acquisition time
% LR  the list as retrieved from the raw directory

%first check if there is already a list cached

%A. check cached list
if status_cache==1
    try
        load_name = 'List_IC_raw.mat';
        load(fullfile(getProcessedDataDir(ee),load_name)),
        disp('Raw list loaded.')
        return
    catch 'IC list needs to be compiled';
    end
end
%B: go through the rawdir to generate the list

tmpExpName = char(ee.ExpID); %I use this for vharacter comparisons, the name i stored as a string in

for ii = 1 : numel(ee.RawDataDir)
    if  ee.RawDataDir(ii).type == "IC"
        % usually the rawDir wil, only have one session, but I am allowing for
        % future exepriments
        D = dir(gen_dir_name(ee.RawDataDir(ii).dir));
        %D = D(3:end);%to avoid the . ..
        icCount = 0;
        icID = categorical() ;
        for jj = 1 : numel(D)
            %is it s a bera?
            tmp_name =  D(jj).name;%(end-8:end)
            % test that the first characters match the exepriment name
            if size(tmp_name,2 )>strlength(ee.ExpID) &  isempty(intersect( str2double(tmp_name(1)),[0:9]))
                if   startsWith(tmp_name(1:strlength(ee.ExpID)),ee.ExpID) ...
                        & ~isnan( str2double(tmp_name(end-5:end-2)))...
                        & startsWith(tmp_name(end-1:end),'.m')
                    jj;
                    icCount=icCount+1;
                    icID(icCount) = D(jj).name(1:end-2);
                    run(fullfile(D(jj).folder,D(jj).name));%here comes the interesting part
                    temp_ic=ans;% important part, could I do it more safely? As the data are a function, it is stored in the ans.
                    temp_dt = temp_ic.datetime;
                    icDate(icCount) = datetime(temp_dt);%no
                end
            end

        end
        if exist('icDate')==0
            icDate=nan;
        end

        %make L
        LR.IC_SeriesID = icID;
        LR.ExpID = string(ee.ExpID);
        LR.allDates_IC = icDate;%no
        LR.dateID_IC = min(LR.allDates_IC);%no
        LR.rawDataDir = ee.RawDataDir(ii);

        [~,iSorted] = sort(LR.allDates_IC);

        L.IC_SeriesID =   LR.IC_SeriesID(iSorted);
        L.ExpID = LR.ExpID;
        L.allDates_IC =  LR.allDates_IC(iSorted);%no
        L.dateID_IC = LR.dateID_IC;%no
        L.rawDataDir = ee.RawDataDir(ii);


    end
end
% the generated list will be saved. IN cse there is a
% previous list,, it will be replaced

save_name = 'List_IC_raw.mat';
save(fullfile(getProcessedDataDir(ee),save_name),'L','LR');
end