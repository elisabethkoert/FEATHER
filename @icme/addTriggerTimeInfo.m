function obj = addTriggerTimeInfo(obj)
% icme/addTriggerTimeInfo - retrofits obj.SL.Trigger for icme objects that
% were processed BEFORE trigger timestamps were persisted alongside the
% spikelist (i.e. anything processed before generateSLfromRawNlxData_
% baseline_global.m started saving Trigger - see patch notes). Re-parses
% the raw .nev event file via parseNlxTriggerInfo, WITHOUT re-running
% spike extraction, and stores the result in obj.SL.Trigger.
% input:  
%   obj (icme) with obj.SL already populated (spik_list_all etc.)
% output: 
%   obj (icme) with obj.SL.Trigger populated
% Usage (raw data must still be reachable via obj.D.dir):
%   IC = loadIcme(icme(ee, seriesID));
%   IC = addTriggerTimeInfo(IC);
%   saveIcme(IC);

if ~isfield(obj.SL,'spik_list_all')
    error('icme:addTriggerTimeInfo:noSL', ...
        '%s: obj.SL has no spik_list_all - run ExtractMUAfromRawDataIntoSL first.', obj.SeriesID)
end
obj.SL.Trigger = parseNlxTriggerInfo(obj);
fprintf('%s: trigger timing info added (%d trials).\n', obj.SeriesID, obj.SL.Trigger.NrTrigger)
end