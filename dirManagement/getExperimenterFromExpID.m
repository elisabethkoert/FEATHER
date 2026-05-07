function [Experimenter_ID] = getExperimenterFromExpID(ExpID)
%getExperimenterFromExpID Little helper to extract experimenter name
%   input:
%       ExpID: String name of the experiment
%   output:
%       Experimenter_ID: char

    if contains(ExpID,'gjg')
        Experimenter_ID='JG';
    elseif contains(ExpID,'GEK')
         Experimenter_ID='EK';
    elseif contains(ExpID,'gth')
         Experimenter_ID='TH';
    elseif contains(ExpID,'GAD')||contains(ExpID,'GMM')
         Experimenter_ID='MM';
    elseif contains(ExpID,'gfe')
         Experimenter_ID='FE';
    else 
        ExpID=char(ExpID);
        Experimenter_ID=upper(ExpID(2:3));
    end

end