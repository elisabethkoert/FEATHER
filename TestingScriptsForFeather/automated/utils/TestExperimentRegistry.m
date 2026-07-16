function paramStruct = TestExperimentRegistry(modality)
% TestExperimentRegistry - MANUALLY CURATED list of experiments to run in
% the automated FEATHER test suite, per modality (ABR / IC / Histo).
%
% Edit the cell arrays below by hand to add/remove experiments. Use
% generateCandidateExperimentList(modality) to get a scan-based starting
% point of what raw data is actually available, then copy/adjust entries
% here as you see fit - this file is intentionally NOT auto-generated.
switch modality
    case 'ABR'
        list = {'GEK030','gjg131644','gth212308'};
    case 'IC'
        list = {'GEK030','gjg131644','gth212308','gna192119'};
    case 'Histo'
        list ={'GEK030','gjg131644'};
    otherwise
        error('TestExperimentRegistry:unknownModality','unknown modality %s',modality);
end

paramStruct = struct();
for i = 1:numel(list)
    paramStruct.(matlab.lang.makeValidName(list{i})) = list{i};
end
end