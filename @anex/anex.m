classdef anex
    % ANEX - all the information associated with an animal experiment
    %   An ANEX object will contain the Name and the species of the
    %   animal.  The data  can be abr, SU SGN, IC, histology etc. It can
    %   happen that differnet days different data were collected. The anexp
    %   class should be able to give me an overview of all the data types
    %   and the meta data associated with each experimental session.
    %   Different experimental sessions can be subclasses of the anexp
    %   class. That is for chronic experiments.
    %
    %   ee = anex(ExpID,ExperimenterID,RawDataDir)
    %   ee = anex('mth133887', 'AV,  D)
    %   note that the dirRaw should not include the mapped drive.
    %   D.dir = "archiv\systems\2023\01\AV\avt002"
    %   D.type = "ABR"
    %
    %   developed by Anna Vavakou 2022

    properties (SetAccess=private)
        ExpID string ; % Exp/Animal ID eg. GEK111
        Species string ; % mouse/ gerbil ...
        ExperimenterID string ; % experimenter eg. EK
        UserID string ; % analyst
        RawDataDir struct;
        ExpMetaData struct; % this is to append experimental metadata
    end

    methods

        %% anex Constructor
        %-----------------------------------------------------------------%

        function obj = anex(ExpID,ExperimenterID,tmpRawDataDir)

            if  status_cache == 1  % if caching is enabled, I will import hte anex, including the raw directories :)
                obj.ExpID = ExpID;
                obj.ExperimenterID = upper(ExperimenterID);
                expProcDataDir(ExperimenterID,ExpID);
                try  obj = loadAnex(obj);
                catch 'Caching is on, but no processed data are there. try enablecache(off)';
                end

            else

                obj.ExpID = ExpID;
                obj.UserID = userID;
                obj.ExperimenterID = upper(ExperimenterID);
                % call the persistent variable expProcDataDir so that the
                % values are updated
                expProcDataDir(ExperimenterID,ExpID);
                

                testSafeDir ( expProcDataDir );
                obj.RawDataDir = tmpRawDataDir;%  gen_dir_name (fullfile(tmpRawDataDir(ii).dir, obj.ExpID )); %the RawDataDir is generated, and it includees the experiemnet name, as to avoid associating data with wrong exepriments
            end
        end
        %% set methods
        %-----------------------------------------------------------------%
        function D = getSUrawDir (obj)
            % anex\getSUrawDir Finds the SU directory in case of multiple rawDataDirs
            for ii = 1 : numel(obj.RawDataDir)
                switch obj.RawDataDir(ii).type
                    case  "SU"
                        D = obj.RawDataDir(ii).dir;
                end
            end
        end
        function D = getABRrawDir (obj)
            % anex\getABRrawDir Finds the ABR directory in case of multiple rawDataDirs
            for ii = 1 : numel(obj.RawDataDir)
                switch obj.RawDataDir(ii).type
                    case  "ABR"
                        D = obj.RawDataDir(ii).dir;
                end
            end
        end
        function D = getICrawDir (obj)
            % anex\getICrawDir Finds the IC directory in case of multiple rawDataDirs
            for ii = 1 : numel(obj.RawDataDir)
                switch obj.RawDataDir(ii).type
                    case  "IC"
                        D = obj.RawDataDir(ii).dir;
                end
            end
        end

        function G = getProcessedDataDir (obj)
            % anex\getProcessedDataDir - method of anex. Calls
            % the persistent variable expProcDataDir. Note tha tthe
            % expProcDataDir can be channged within and outside the anex
            % class.
            G = expProcDataDir;
        end
        function setProcessedDataDir (~, updateProcDataDir)
            % anex\setProcessedDataDir - method of anex. It allows you to update the
            % ProcessedDataDirectory, in case the exeprimenter the analyzer
            % and the user are an unexpected combinaiton,
            % variable type - string
            testSafeDir ( updateProcDataDir );
            expProcDataDir([],[],updateProcDataDir)
        end
        function obj = setAnimalSpecies(obj, Species)
            obj.Species = Species;
        end
        function obj = setExperimenterID(obj, ExperimenterID)
            obj.ExperimenterID = ExperimenterID;
        end
        function obj = setRawDataDir (obj, updateRawDataDir)
            % anex\setRawDataDir - method of anex. It allows you to update the
            % rawDataDirectory, in case there are more than one
            % experimental sessions.
            % variable type - struct

            for ii = 1 : numel(updateRawDataDir)
                obj.RawDataDir = updateRawDataDir; % force a change
%                 if any(contains(updateRawDataDir(ii).dir,obj.ExpID))
%                     obj.RawDataDir = updateRawDataDir;
%                 else
%                     warning(sprintf('%sthe raw  data directory does not contain the experiment name. Operation aborted. Are you sure you know what you are doing?',obj.ExpID))
%                 end
            end
        end
        function obj = setUserID (obj)
            % anex\setUserID - method of anex. It allows you to update the
            % userID with the current person that works on the analysis of an
            % anex, nice to update regularily if mutliple people work on
            % something
            % variable type - string
            obj.UserID=userID();
        end
        function obj = setExpMetaData (obj, updateExpMetaData)
            % anex\setExpMetaData - method of anex. It allows you to update the
            % ExpMetaData.
            % variable type - structure
            obj.ExpMetaData = updateExpMetaData;
        end

        %% databasing
        %-----------------------------------------------------------------%
        function L = listBerabrRaw (obj)
            % anex\listBerabr lists all berabrs in rawDataDir
            %first check if there is already a list cached

            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_ABR_raw.mat';
                    load(fullfile(getProcessedDataDir(obj),load_name)),
                    disp('Raw list loaded.')
                catch 'list needs to be compiled';
                end
            end
            %B: go through the rawdir to generate the list
            %here I should also chheck for type abr
            for ii = 1 : numel(obj.RawDataDir)
                if  obj.RawDataDir(ii).type == "ABR"
                    % usually the rawDir wil, only have one session, but I am allowing for
                    % future exepriments
                    D = dir(gen_dir_name(obj.RawDataDir(ii).dir));
                    %D = D(3:end);%to avoid the . ..
                    beraCount = 0;
                    beraID = categorical() ;
                    for jj = 1 : numel(D)
                        %is it s a bera?
                        tmp_name =  D(jj).name;%(end-8:end)
                        if size(tmp_name,2 ) >=8 &&  ~isempty(intersect( str2double(tmp_name(1)),[0:9]))
                            if  sum(tmp_name(end-7:end) == 'BERA.mat')==8
                                beraCount=beraCount+1;
                                beraID(beraCount) = D(jj).name(1:end-4);
                                temp_bera = load(fullfile(D(jj).folder,D(jj).name));
                                temp_dt = temp_bera.ExpInfo.c;
                                beraDate(beraCount) = datetime(temp_dt);%no
                            end
                        end
                    end

                    if exist('beraDate')==0
                        beraDate=nan;
                    end
                    %make E
                    L(ii).ABR_SeriesID = beraID;
                    L(ii).ExpID = string(obj.ExpID);
                    L(ii).allDates_ABR = beraDate;%no
                    L(ii).dateID_ABR = min(L(ii).allDates_ABR);%no
                    L(ii).rawDataDir = obj.RawDataDir(ii);
                end
            end
            % the generated list will be saved. IN cse there is a
            % previous list,, it will be replaced
            save_name = 'List_ABR_raw.mat';
            save(fullfile(getProcessedDataDir(obj),save_name),'L');
        end

        function L = listBerabr (obj)
            % anex\listBerabr lists all berabrs inProcessedDataDir
            %first check if there is already a list chched

            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_ABR.mat';
                    load(fullfile(getProcessedDataDir(obj),load_name)),
                    display('Processed data list loaded.')
                catch 'list needs to be compiled'
                end
            end
            %B: go through the processed dir to generate the list
            %here I should also chheck for type abr

            % usually the rawDir wil, only have one session, but I am allowing for
            % future exepriments
            D = dir(expProcDataDir);
            %D = D(3:end);%to avoid the . ..
            beraCount = 0;
            beraID = categorical() ;
            for jj = 1 : numel(D)
                %is it s a bera?
                tmp_name =  D(jj).name;%(end-8:end)
                if size(tmp_name,2)>=2
                    if tmp_name(1:2)=='B_'
                        beraCount=beraCount+1;
                        beraID(beraCount) = D(jj).name(4+numel(char(obj.ExpID)):end-4);
                        temp_bera = load(fullfile(D(jj).folder,D(jj).name));
                        temp_dt = temp_bera.B.ExpInfo.c;
                        beraDate(beraCount) = datetime(temp_dt);%no
                    end
                end
            end
            if exist('beraDate')==0
                beraDate=nan;
            end
            %make E
            L(1).ABR_SeriesID = beraID;
            L(1).ExpID = string(obj.ExpID);
            L(1).allDates_ABR = beraDate;%no
            L(1).dateID_ABR = min(L(1).allDates_ABR);%no
            % the generated list will be saved. IN cse there is a
            % previous list,, it will be replaced
            save_name = 'List_ABR.mat';
            save(fullfile(getProcessedDataDir(obj),save_name),'L');
        end

        function L = listHistImgsRaw (obj)
            % anex\listHistImgsRaw lists all histimgs in rawDataDir
            % goes through the folder containing the Nintendo results and
            % checks how many HistIMgs are associated to an experiment and
            % makes a list of the names
            initHistoFolder(obj)% create folder substructure if necessary
            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_Hist_raw.mat';
                    load(fullfile(getProcessedDataDir(obj),'HISTO',load_name)),
                    disp('Raw list loaded.')
                catch 'list needs to be compiled';
                end
            elseif status_cache==0
                %B: go through the rawdir to generate the list
                L=[];
                for ii = 1 : numel(obj.RawDataDir)
                    if  obj.RawDataDir(ii).type == "NintendoRes"
                        % usually the rawDir wil, only have one session, but I am allowing for
                        % future exepriments
                        D = dir(gen_dir_name(obj.RawDataDir(ii).dir));
                        %D = D(3:end);%to avoid the . ..
                        HistImgsCount = 0;
                        SeriesID = categorical();
                        ImgSides = categorical();
                        ImgTurns = categorical();
                        ImgVersions = [];
                        ImgFilenames={};
                        % the naming conventions are different, JG only has
                        % animal number in histo, EK has GEKXXX

                        ExpID=obj.ExpID;
                        if obj.ExperimenterID == 'JG'
                            ExpID=char(obj.ExpID);
                            ExpID=string(ExpID(4:end));
                        end
                        for jj = 1 : numel(D)
                            %is it s a bera?
                            tmp_name =  D(jj).name;  %(end-8:end);
                            if contains(tmp_name,ExpID) && contains(tmp_name,'.csv')
                                HistImgsCount=HistImgsCount+1;
                                ImgFilenames{HistImgsCount}=tmp_name;
                                tmp_name=strrep(tmp_name,'.csv','');
                                descr=split(tmp_name,'-');
                                descr2=split(descr{1},'_');
                                descr2(1)=[]; % remove ExpID
                                % check for L/R

                                if ~isempty(descr2)
                                    if any(cellfun(@(x) contains(x,'L'),descr2))
                                        ImgSides(HistImgsCount)='L';
                                    elseif any(cellfun(@(x) contains(x,'R'),descr2))
                                        ImgSides(HistImgsCount)='R';
                                    end

                                else
                                    if contains(tmp_name,'L')
                                        ImgSides(HistImgsCount)='L';
                                    end
                                    if contains(tmp_name,'R')
                                        ImgSides(HistImgsCount)='R';
                                    end
                                end

                                % check for turn

                                if contains(tmp_name,'ap','IgnoreCase',true)
                                    ImgTurns(HistImgsCount)='apex';
                                end
                                if contains(tmp_name,'bas','IgnoreCase',true)
                                    ImgTurns(HistImgsCount)='base';
                                end
                                if contains(tmp_name,'med','IgnoreCase',true)||contains(tmp_name,'mid','IgnoreCase',true)
                                    ImgTurns(HistImgsCount)='mid';
                                end



                                % check for version
                                img_version=1;
                                if ~isempty(descr2)
                                    if any(cellfun(@(x) contains(x, 'v'), descr2))
                                        vIndices = (cellfun(@(x) contains(x, 'v'), descr2));
                                        img_version= str2num(descr2{vIndices}(2));
                                    end

                                else
                                    if contains(tmp_name,'v2')
                                        img_version=2;
                                    end
                                end
                                ImgVersions(HistImgsCount)=img_version;

                                SeriesID(HistImgsCount)=strjoin({char(ImgSides(HistImgsCount)),char(ImgTurns(HistImgsCount)),sprintf('v%i', ImgVersions(HistImgsCount)),'40x'},'_');



                            end
                        end

                        %make List
                        L(1).HistImg_SeriesID = SeriesID;
                        L(1).ExpID = string(obj.ExpID);
                        L(1).Sides = ImgSides;
                        L(1).Turns = ImgTurns;
                        L(1).Versions = ImgVersions;
                        L(1).Filenames=ImgFilenames;
                    end
                end
                % the generated list will be saved. IN cse there is a
                % previous list,, it will be replaced
                save_name = 'List_Hist_raw.mat';
                save(fullfile(getProcessedDataDir(obj),'HISTO',save_name),'L');
            end
        end

        function L = listHistImg (obj, rewrite_list)
            % anex\listHistimg lists all histimgs in processedDataDir
            % first check if there is already a list and use this as long as
            % rewrite_list does not exist
            if nargin < 2
                rewrite_list = 0;
            end
            initHistoFolder(obj)% create folder substructure if necessary
            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_Hist.mat';
                    load(fullfile(getProcessedDataDir(obj),'HISTO',load_name)),
                    display('Processed data list loaded.')
                    if rewrite_list==0
                        return
                    end
                catch 'list needs to be compiled'
                end
            end

            %B: go through the processed dir to generate the list

            % usually the rawDir wil, only have one session, but I am allowing for
            % future exepriments
            D = dir(fullfile(expProcDataDir,'HISTO'));
            %D = D(3:end);%to avoid the . ..
            Count = 0;
            ImgID = categorical() ;
            ImgSides = categorical();
            ImgTurns = categorical();
            ImgVersions = [];
            for jj = 1 : numel(D)
                %is it s a bera?
                tmp_name =  D(jj).name;%(end-8:end)
                if size(tmp_name,2)>=2
                    if tmp_name(1:2)=='H_'
                        Count=Count+1;
                        temp_histImg = load(fullfile(D(jj).folder,D(jj).name));
                        ImgID(Count) = temp_histImg.H.SeriesID;
                        ImgSides(Count) = temp_histImg.H.side;
                        ImgTurns(Count) = temp_histImg.H.turn;
                        ImgVersions(Count) = temp_histImg.H.version;
                    end
                end
            end

            %make E
            L(1).HistImg_SeriesID = ImgID;
            L(1).ExpID = string(obj.ExpID);
            L(1).Sides = ImgSides;
            L(1).Turns = ImgTurns;
            L(1).Versions = ImgVersions;%no
            % the generated list will be saved. IN cse there is a
            % previous list,, it will be replaced
            save_name = 'List_Hist.mat';
            save(fullfile(getProcessedDataDir(obj),'HISTO',save_name),'L');
        end




        % preprocessing
        function allBerabr (obj)
            % anex\allBerabr finds all ABR raw data files and initializes the berabr objects
            L = listBerabrRaw(obj);
            for ii = 1 : numel(L.ABR_SeriesID)
                b = berabr (obj,L.ABR_SeriesID(ii),L.rawDataDir); %assign the raw data directory. Tis will be used toimport the raw data.
                b = initBerabr(b);
                ii;
            end
        end
        % preprocessing
        function allSutr (obj, indexFirst)
            % preproces the sutr of ee. In case there is a secodn
            % argument, that would be the first index number, along the
            % list, to begint he preprocessing.
            enablecache on
            L = listSuRaw(obj);
            enablecache off
            if nargin == 1;
                indexFirst = 1;
            end
            for ii = indexFirst : numel(L.SU_SeriesID) %1
                ii;
                T = sutr(obj,L.SU_SeriesID(ii));% L.SU_SeriesID(1))
                T = loadRaw(T);
                T = assignSU(T);
                T = stim(T)
                T = processSutr(T);
                T = updateII(T)
                T;
                saveSutr(T);
            end
        end

        % preprocessing
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


        function allSunit(obj)
            for ii = 1 : numel(obj.ExpMetaData.Units)
                su = sunit (obj,ii); %assign the raw data directory. Tis will be used toimport the raw data.
                saveSunit(su);
                ii;
            end
        end

        %% control caching

        %-----------------------------------------------------------------%

        % initialize a new experiment folder in the processed data file
        function initProcessedExp (obj)
            % anex\initProcessedExp - Generates a directory for processed experiment data.
            % This will take into acount the
            % ExperimenterID as defined in the anex object property. It is
            % not possible to implement changes in the archiv domain.
            % status_cache
            %if the follder does not exist, make it!
            %Add safety for archiv
            testSafeDir ( getProcessedDataDir(obj));
            if  isfolder(getProcessedDataDir(obj)) == 0
                mkdir(getProcessedDataDir(obj));
                saveAnex(obj);
            elseif  isfolder(getProcessedDataDir(obj)) == 1
                warning('Experiment is already initialized, overwrite aborted.');
            end
        end
        %
        function saveAnex(obj)
            % anex\saveAnex - stores the anex data in the ProcessedDataDir
            testSafeDir ( getProcessedDataDir(obj));
            save_name = strcat("E_",obj.ExpID,".mat");
            E = obj;
            save(fullfile(getProcessedDataDir(obj),save_name),'E');
        end
        %
        function obj = loadAnex(obj)
            % anex\loadAnex - loads the anex data from the PorcessedDataDir
            load_name = strcat("E_",obj.ExpID,".mat");
            E = obj;
            LO = load(fullfile(getProcessedDataDir(obj),load_name),'E');%loaded object
            obj = LO.E;
            %             experimenterID(obj.ExperimenterID);% achtung 17.12.2024
        end


    end



end

