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
        %% get methods
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
        %% set methods
        %-----------------------------------------------------------------%

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



        %% folder management

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
        %% save and laod object

        %-----------------------------------------------------------------%
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

