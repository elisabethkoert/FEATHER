classdef berabr
    % BERABR - all the ABR measurements acquired using the BERA software
    %   A BERABR object contains the associated Expeirment name and the
    %   series ID string of the bera name. This can be easily derived from
    %   the list_abrbera.
    %   B = berabr (ee, SeriesID )


    properties (SetAccess=private)
        ExpID string
        SeriesID string
        ExpInfo struct % compatible with GH variable name, not anex relevant
        nTraces double
        Stim struct
        R struct % Raw data
        F struct % Feather, processed data
        C struct % Calibraition file
        D struct % Directory where the rawdata is stored.
    end

    methods
        %constructor
        function obj = berabr (ee, SeriesID, D) %it was E instead of ee in the past, see if it casues an error
            obj.ExpID = ee.ExpID;
            obj.SeriesID = SeriesID;
            if nargin>2 && ~isempty(D)
                obj.D = D;
            end
        end
        %
        function obj = initBerabr(obj)
            % berabr\initBerabr to be used for preprocessing.
            % Default filtering properties are 300 3000Hz
            % These can be adjusted for individual beras if need be.

            obj = loadRaw (obj);
            obj = stim (obj);
            % obj = computeFeather(obj); %
            obj = processBerabr(obj); %
            saveBerabr(obj)
        end
        function obj = setRawDataDir (obj, updateRawDataDir)
            % berabr\setRawDataDir It allows you to update the
            % rawDataDirectory
            % variable type - struct

            for ii = 1 : numel(updateRawDataDir)
                if any(contains(updateRawDataDir(ii).dir,obj.ExpID))
                    obj.D= updateRawDataDir;
                else
                    warning('the raw  data directory does not contain the expID. Operation aborted. Are you sure you know what you are doing?')
                end
            end
        end
        function obj = loadRaw (obj)
            % berabr\loadRaw - loads the raw data from the
            % directory stored in property 'D' of Bera

            load_name = strcat(obj.SeriesID,".mat");
            LoadAll = load(fullfile(gen_dir_name(obj.D.dir),load_name));%loaded object

            obj.ExpInfo = LoadAll.ExpInfo;
            obj.R = LoadAll.IsData;

            % here I should correct for the probelm in the conversion that GH had n
            % January 2023, when TH began using the green Oxxius laser. For some
            % experiments, BERAdat is ofund in the ExpInfo structure but not in the
            % IsData structure. For consistency reasons, I test for that and I copy the
            % BERAdat structure inthe IsData. Subsequently, I remove it from ExpInfo
            % field of the berabr to avoid storing heavy data.


            for ii = 1 : size (obj.R,2)


                % check if there is a BERAdat - otherwise harvest it from the
                % ExpInfo.NIdata - 'convert' part of GH code.
                % This conversion will NOT be stored with the raw data.
                noFieldBERAdat=0; if ~isfield(obj.R(1,1),'BERAdat'); disp('no field BERAdat'); noFieldBERAdat=1; end
                %     if isfield(obj.R(1,1),'BERAdat') & isempty(obj.R(1,1).BERAdat); disp('empty field BERAdat'); noFieldBERAdat=1; end
                %^ that is for one expriment where there is an IsData.BERAdat but it is empty, when that is not the case in the ExpInfo.Dat

                if noFieldBERAdat
                    for iBERAdat= 1:size(obj.R,2)
                        try
                            obj.R(iBERAdat).BERAdat(:) = obj.ExpInfo.Dat.NIdata(iBERAdat).BERAdat(:);
                        catch
                            'no BERAdat in the ExpInfo.Dat.NIdata'
                        end
                    end
                end
            end

            if isfield(obj.ExpInfo,'Dat')
                obj.ExpInfo = rmfield(obj.ExpInfo,'Dat'); %this would be to decrease the processed data size
                % obj.ExpInfo = rmfield(obj.ExpInfo,'Stimulus');
            end
            obj.nTraces = size(obj.R,2);
        end
        %
        function saveBerabr(obj)
            % berabr\saveBerabr - stores the bearabr data in the PorcessedDataDir
            if  status_cache==0
                save_name = strcat("B_",obj.ExpID,"_",obj.SeriesID,".mat");
                testSafeDir(save_name)
                B = obj;
                B.R=[]; %empty the raw data to save only the feather
                save(fullfile(expProcDataDir,save_name),'B');
            end
        end
        %
        function obj = loadBerabr(obj)
            % berabr\loadBerabr - loads the bearabr data from the PorcessedDataDir
            load_name = strcat("B_",obj.ExpID,"_",obj.SeriesID,".mat");
            B = obj;
            LO = load(fullfile(expProcDataDir(),load_name),'B');%loaded object
            obj = LO.B;

        end

        %% utilities
        function [string_structure] = ttlString (obj)
            % berab\ttlString - generates a title string and legendf that can be usedd
            % as an iput when plotting the Berabrs.

            switch obj.Stim(1).modality
                case 'Acoustic'
                    ttl_mod = 'aABR';
                    measUintInt = 'dB SPL';

                case 'Optical'
                    ttl_mod = 'oABR';
                    measUintInt = 'mW';

                case 'Electric'
                    ttl_mod = 'eABR';
                    measUintInt = 'mV';
            end

            if obj.Stim(1).protocol~=' '
                switch obj.Stim(1).protocol
                    case 'I'
                        stim_str = 'var. Intensity';
                        prtclMeasUnit = measUintInt;

                    case 'D'
                        stim_str = 'var. Duration';
                        prtclMeasUnit = 'ms';

                    case 'R'
                        stim_str = 'var. RepRate';
                        prtclMeasUnit = 'Hz';
                end
            else
                stim_str = [];
                prtclMeasUnit = [];
            end

            string_structure.ExpModStim = strcat(obj.ExpID, ", ", ttl_mod, ", ", stim_str);
            string_structure.ExpSeriesModStim = strcat(obj.ExpID, ", ",obj.SeriesID, ", ", ttl_mod, ", ", stim_str);
            string_structure.measUintInt = measUintInt;
            string_structure.prtclMeasUnit = prtclMeasUnit;
            string_structure.E_SID_P_H = strcat(obj.ExpID, ", ",obj.SeriesID, ", ", ttl_mod, ", ", stim_str,", ", strip(obj.Stim(1).stimulusHardware,"both")); ;
            string_structure.E_SID_P_H_M = strcat(obj.ExpID, ", ",obj.SeriesID, ", ", ttl_mod, ", ", stim_str,", ", strip(obj.Stim(1).stimulusHardware,"both"),", ", strip(obj.Stim(1).mode,"both")); ;

        end
        function obj = inverseBerabr (obj)
            % berabr/inverseBerabr is used to inverset he feather ABR
            % data. This is to compensate for arbitrary placement of
            % recording electrodes, against conventions.
            for ii = 1:numel(obj.F)
                obj.F(ii).ABR = -obj.F(ii).ABR;
            end
        end

        function obj = nanBerabr (obj, ii)
            % berabr/nanBerabr selectively nanifies the ii trace.
            obj.F(ii).ABR = nan;
            obj.F(ii).ABReven = nan;
            obj.F(ii).ABRodd = nan;
            obj.F(ii).t = nan;
        end

        %% calibration
        function obj = setC(obj,C)
            obj.C = C;
        end

    end
    %%
end




















