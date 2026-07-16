function ee = getOrCreateTestAnex(ExpID, ExperimenterID, rawDataDir, dataType)
% getOrCreateTestAnex - loads the anex for ExpID/ExperimenterID under the
% TEST user if a processed anex already exists (e.g. created by a
% different modality's test run for the same experiment), otherwise
% creates it fresh. Either way, ensures a RawDataDir entry of type
% dataType pointing at rawDataDir exists on the returned anex.
%
% Relies on the anex() constructor correctly throwing when enablecache
% is on but no processed anex exists yet (see the fix applied to
% @anex/anex.m's constructor catch block).

enablecache on
try
    ee = anex(ExpID, ExperimenterID);
    hasType = any([ee.RawDataDir.type] == dataType);
    if ~hasType
        enablecache off
        D_cur = ee.RawDataDir;
        D_cur(end+1).dir = rawDataDir;
        D_cur(end).type = dataType;
        ee = setRawDataDir(ee, D_cur);
        saveAnex(ee);
    end
catch
    enablecache off
    D = struct('dir', {rawDataDir}, 'type', {dataType});
    ee = anex(ExpID, ExperimenterID, D);
    initProcessedExp(ee);
    saveAnex(ee);
end
end