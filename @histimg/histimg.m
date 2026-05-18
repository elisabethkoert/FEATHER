classdef histimg
    %HISTIMG histology data for a single image set (usually 40x from 1 cochela turn)
    %   A HISTIMG object contains the results from the Nintendo Histology analysis 
    % as well as the raw data folder and imaging settings for one image set (usually SGNs from 
    %  1 turn of a cochlea imaged with 40x oil objective)

    properties
        ExpID string % eg. GEK001
        SeriesID string % eg. MID_40x_V1
        D struct % Directories where the image rawdata & Nintendo analysis is stored
        filename string
        side string % L/R
        turn string % apex/mid/base
        nCells double
        version double
        nPosCells double
        volume double % full 3D volume around all detected cells
        areaSlice double % area of the full volume intersected with a single center slice
        density double % SGNs/10^5 µm3
        densityTransduced double % SGNs/10^5 µm3
        transductionRate double 
        gfpThreshhold double
        numPlanesVolume double % one plane is 1 µm thick
        density2D double % SGNs/10^4  by division of Volume with num of planes
        density2Dslice double % in SGNs/10^4   µm2 by separate readout from one slice in stack


    end

    methods
        function obj = histimg(ee,SeriesID,D,filename)
            %HISTIMG Construct an instance of this class or loads an
            % existing object
            %   Creates the HISTIMG directly connected to an anex, the
            %   SeriesID has to follow the format L_mid with an optional
            %   versin if more than 1 exists eg. L_mid_V3
             if  status_cache == 1  % if caching is enabled, I will import hte anex, including the raw directories :)
                obj.ExpID = ee.ExpID;
                obj.filename=filename;
                obj.SeriesID = SeriesID;
                try  obj = loadHistImg(obj);
                catch 'Caching is on, but no processed data are there. try enablecache(off)';
                end

            else
                obj.ExpID = ee.ExpID;
                obj.SeriesID = SeriesID;
                
                if nargin>2 &&  exist('D','var')
                    obj.D = D;
                end
                if nargin>2 && exist('filename','var')
                    obj.filename=filename;
                end
                % get info such as side and version from the SeriesID
                descr2=split(SeriesID,'_');
                % check for L/R
                if length(descr2{1})==2 % cur out the 1/2 in front of the side if it exists
                    descr2{1}=descr2{1}(end);
                end
                obj.side=descr2{1};

                % check for turn
                turns={'apex','mid','base'};
                for turn_ix=1:3
                    check=any(cellfun(@(x) strcmp(x,turns{turn_ix}),descr2));
                    if check == 1
                        obj.turn=turns{turn_ix};
                    end
                end

                % check for version
                img_version=1;
                if any(cellfun(@(x) contains(x, 'v'), descr2))
                    vIndices = (cellfun(@(x) contains(x, 'v'), descr2));
                    img_version= str2num(descr2{vIndices}(2));
                end
                obj.version=img_version;
             end
        end

        function [obj,check] = readNintendoResults(obj)
            %readNintendoResults reads the results from the nintendo excel
            % sheet - only works for EK style HistObj, else call
            % readNintendoResultsAll(ee) on the whole anex
            %   This functin reads the Nintendo analysis results from a
            %   generated excel sheet from the "NintendoRes" Data directory already specified in
            %   the HistImg object and stores the nintendo results in the HistImg object, 
            %  if this function fails along the way (eg. because a specific area was not imaged) it returns check = 0

            check=0;
            dir_ix = [];
            for ix_tmp = 1:length(obj.D)
                if strcmp(obj.D(ix_tmp).type, "NintendoRes")
                    dir_ix = [dir_ix ix_tmp];
                end
            end
            file_path=gen_dir_name(obj.D(dir_ix).dir);
            animal_number=char(obj.ExpID);
            animal_number=string(animal_number(4:end));
            file=dir(fullfile(file_path, obj.filename));
            % old stuff
%             files_Wanted = {};
%             img_desc=split(obj.SeriesID,'_');
%             for i = 1:length(files)
%                 filename = lower(files(i).name);  % convert to lower case for comparison
%                 if contains(files(i).name, lowercase(obj.SeriesID))
%                     files_Wanted{end+1} = files(i).name;
%                 end
%             end
            % check if we got exactly one file
            if isempty(file)
                disp('Error no Nintendo csvfile found') % ToDo actual error
                return
            elseif length(file)==1
                % check if there is no ambiguity
                filename=file.name;        
            else
                disp('Error problems reading in the Nintendo csv file, too many files')% ToDo actual error
                return
            end                 
            data=readtable(fullfile(file_path,filename),'Delimiter',',');
            
%            
            obj.nCells              = data.AllSGNs;
            obj.nPosCells           = data.No_Positive;
            obj.volume              = data.Volume_ROI_microm3_;
            obj.density             = (data.AllSGNs)/data.Volume_ROI_microm3_*10^(5);
            obj.densityTransduced   =(data.No_Positive)/data.Volume_ROI_microm3_*10^(5);
            obj.transductionRate    =data.No_Positive/data.AllSGNs;
            
            if any("usedGFPThreshold" == string(data.Properties.VariableNames))
                obj.gfpThreshhold   = data.usedGFPThreshold;
            else
                obj.gfpThreshhold   = NaN;
            end
            if any("Volume_Slice_microm3_" == string(data.Properties.VariableNames))
                obj.density2Dslice           = (data.AllSGNsSlice)/data.Volume_Slice_microm3_*10^(4); % slice is 1 µm thick to Volume in µm3 per slice is acutally area in µm2
                obj.areaSlice               = data.Volume_Slice_microm3_;
            else
                obj.density2Dslice   = NaN;
                obj.areaSlice       =NaN;
            end

            if any("numPlanesVolume" == string(data.Properties.VariableNames)) && any("Volume_ROI_microm3_" == string(data.Properties.VariableNames))
                obj.numPlanesVolume   = data.numPlanesVolume;
                % devide volume in µm3 by num of planes (each 1 µm thick)
                % for 2D area in µm2, gives density in SGNs/1000µm2
                obj.density2D=(data.AllSGNs)/(data.Volume_ROI_microm3_/data.numPlanesVolume)*1000;
            else
                obj.numPlanesVolume   =  NaN;
                obj.density2D=NaN;
            end


            
            check = 1; % if return happened earlier this will stay 0
        end
        
        function saveHistimg(obj)
            % histimg\saveHistimg - stores the histimg data in the PorcessedDataDir
            if  status_cache==0 % only overwrite files if cache is off
                save_name = strcat("H_",obj.ExpID,"_",obj.SeriesID,".mat");
                testSafeDir(save_name)
                H = obj;
                save(fullfile(expProcDataDir,'HISTO',save_name),'H');
            end
        end

        function obj = loadHistImg(obj)
            % histimg\loadHistimg - loads the histimg data from the PorcessedDataDir
            load_name = strcat("H_",obj.ExpID,"_",obj.SeriesID,".mat");
            H = obj;
            LO = load(fullfile(expProcDataDir(),'HISTO',load_name),'H');%loaded object
            obj = LO.H;
        end
        
        function obj = setRawDataDir (obj, updateRawDataDir)
            % histImg\setRawDataDir update the rawDataDirectory
            % variable type - struct

            obj.D= updateRawDataDir;
              
        end


        function obj = readMicroscopeSettings(obj)
            % histimg\readMicroscopeSettings not yet done
            % settings if saved with the raw data
            % ToDo write function
        end

        
    end
end
