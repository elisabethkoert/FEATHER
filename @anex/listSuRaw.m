function [L,LR] = listSuRaw (obj)
% anex\listSuRaw - complies a list of all the SU measurements in the raw
% data folder. Only SU measaurements are presented. 
% L : the list sorted according to acquisition time 
% LR  the list as retrieved fromt he raw directory

%first check if there is already a list chched

%A. check cached list
if status_cache==1
    try
        load_name = 'List_SU_raw.mat';
        load(fullfile(getProcessedDataDir(obj),load_name)),
        disp('Raw list loaded.')
        return
    catch 'SU list needs to be compiled';
    end
end
%B: go through the rawdir to generate the list
%here I should also chheck for type abr
for ii = 1 : numel(obj.RawDataDir)
    if  obj.RawDataDir(ii).type == "SU"
        % usually the rawDir wil, only have one session, but I am allowing for
        % future exepriments
        D = dir(gen_dir_name(obj.RawDataDir(ii).dir));
        DSU = obj.RawDataDir(ii).dir;
        %D = D(3:end);%to avoid the . ..
        suCount = 0;
        suID = categorical() ;
        for jj = 1 : numel(D)
            %is it s a bera?
            tmp_name =  D(jj).name;%(end-8:end)
            if size(tmp_name,2 ) >=12 &&  ~isempty(intersect( str2double(tmp_name(1)),[0:9]))
                if  sum(tmp_name(end-6:end) == '-SU.mat')==7
                    jj
                    suCount=suCount+1;
                    suID(suCount) = D(jj).name(1:end-4);
                    temp_su = load(fullfile(D(jj).folder,D(jj).name));
                    temp_dt = temp_su.ExpInfo.c;
                    beraDate(suCount) = datetime(temp_dt);%no
                end
            end
        end

        if exist('beraDate')==0
            beraDate=nan;
        end
        %make L
        LR.SU_SeriesID = suID;
        LR.ExpID = string(obj.ExpID);
        LR.allDates_SU = beraDate;%no
        LR.dateID_SU = min(LR.allDates_SU);%no
        LR.rawDataDir = DSU;

        [~,iSorted] = sort(LR.allDates_SU);

        L.SU_SeriesID =   LR.SU_SeriesID(iSorted);
        L.ExpID = LR.ExpID;
        L.allDates_SU =  LR.allDates_SU(iSorted);%no
        L.dateID_SU = LR.dateID_SU;%no
        L.rawDataDir = DSU;

%         %make L
%         LR(ii).SU_SeriesID = suID;
%         LR(ii).ExpID = string(obj.ExpID);
%         LR(ii).allDates_SU = beraDate;%no
%         LR(ii).dateID_SU = min(LR(ii).allDates_SU);%no
%         LR(ii).rawDataDir = DSU;
% 
%         [~,iSorted] = sort(LR(ii).allDates_SU);
% 
%         L(ii).SU_SeriesID =   LR(ii).SU_SeriesID(iSorted);
%         L(ii).ExpID = LR(ii).ExpID;
%         L(ii).allDates_SU =  LR(ii).allDates_SU(iSorted);%no
%         L(ii).dateID_SU = LR(ii).dateID_SU;%no
%         L(ii).rawDataDir = DSU;


    end
end
% the generated list will be saved. IN cse there is a
% previous list,, it will be replaced

save_name = 'List_SU_raw.mat';
save(fullfile(getProcessedDataDir(obj),save_name),'L','LR');
end