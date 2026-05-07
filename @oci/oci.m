classdef oci
    % oci contain the relevant information for each oci that we have
    properties
        ociID %
        ociNumber %
        ociManufacturerName % the name the
        date %
        type % creeLED, uLED, waveguide
        wavelength %
        emitters %
        pitch %
        circuitry %
        images %
        radiantFlux %
        batch %
        dir
    end

    methods
        %constructor
        function obj = oci (ociID) %
            obj.ociID = ociID;
            try obj = loadOci(obc)
            end
        end
        %
        function obj = initOci(obj)
            % oci\initOci
            saveOci(obj)
        end
        %
        function obj = saveOci(obj)
            % berabr\saveBerabr - stores the bearabr data in the PorcessedDataDir
            if  status_cache==0
                %                 save_name = strcat("B_",obj.ExpID,"_",obj.SeriesID,".mat");
                %                 testSafeDir(save_name)
                %                 B = obj;
                %                 B.R=[]; %empty the raw data to save only the feather
                %                 save(fullfile(expProcDataDir,save_name),'B');
            end
        end
        %
        function obj = getDir(oci)
        end
        %
        function obj = loadDefault(obj)
        end
        %
        function obj = loadCalib(obj,dirCalib)
        end
        %
        function obj = loadCircuitry(obj)
        end
        %
        function getPitch(obj)
            % there should  be a gui, import one image and do it there
        end
        %
        function updateLog(obj)
        end
        %
        function plotCircuitry(obj)
        end
    end
end