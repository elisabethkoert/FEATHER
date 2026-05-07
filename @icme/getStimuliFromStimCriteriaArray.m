function varargout= getStimuliFromStimCriteriaArray(obj,stim_criteria_array)
% icme\getStimuliFromStimCriteriaArray applies the stim criteria array to
% filter the used stimuli for one icme
% input:
%   obj (icme) IC recording object, 
%   stim_criteria_array: (nx3 array floats) helper to identify wanted stimuli [collum in stimlist, min value, max value]
%      the first row describes the main stimulus variable from which the
%      intensity can be given out as an optional output as well
% output: 
%   stim_IDs (double)) list of stimuli that fulfill the stim_criteria array
%   stimuli (list of doubles) Applied stimulus values for each of the
%       stimuli that are left after filtering
    
    nargoutchk(0,2);  % allow up to 2 outputs

    
    % check if the calibrated StimList exists
    if isfield(obj.C,'stimlistCal')
        OBJ_stimlist=obj.C.stimlistCal;
    else
        OBJ_stimlist=obj.Stim.stimlist;
    end

    % figure out which stimuli are investigated
    stim_IDs=1:1:length(OBJ_stimlist(:,1));
    for jj=1:size(stim_criteria_array,1)
        stim_ID_1=find(OBJ_stimlist(:,stim_criteria_array(jj,1))>=stim_criteria_array(jj,2));
        stim_IDs = stim_IDs(ismember(stim_IDs, stim_ID_1));
        stim_ID_2=find(OBJ_stimlist(:,stim_criteria_array(jj,1))<=stim_criteria_array(jj,3));
        stim_IDs = stim_IDs(ismember(stim_IDs, stim_ID_2));
    end

    changing_var_ix=stim_criteria_array(1,1);%SPL dB
    stimuli = OBJ_stimlist(stim_IDs, changing_var_ix); % tonotopy this is dB

    % always return first output if requested
    if nargout >= 1
        varargout{1} = stim_IDs;
    end

    % second output: the used stimlist rows
    if nargout >= 2
        varargout{2} = stimuli;
    end

end