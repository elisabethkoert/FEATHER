classdef expsess %< anexp
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        ExpID string;
        Experimenter string;
        RawDataDir string;
        AnExp anexp;

    end

    methods
        %constructor
        function obj = expsess(anexp_Tag, RawDataDir, Experimenter)

            %obtained from user input
            obj.AnExp = anexp_Tag;
            obj.RawDataDir = RawDataDir;
            obj.Experimenter = Experimenter;

            %hardcoded - obtained from the anex that is tagged with this
            %expsess
            obj.ExpID = anexp_Tag.ExpID;
        end


    end
end