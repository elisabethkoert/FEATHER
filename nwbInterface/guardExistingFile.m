function guardExistingFile(filepath, overwrite, label)
% guardExistingFile  Hard-errors if filepath already exists and overwrite is
% not true.  Mirrors the pattern of initProcessedExp/initIcmeFolder but is
% stricter (hard error, not warning) so that a wrong processed-data
% directory or UserID slip-up is caught immediately rather than silently
% destroying existing data.
%
% Inputs:
%   filepath  (char|string)  Full path of the file to check.
%   overwrite (logical)      If true the guard is skipped.
%   label     (char|string)  Human-readable label used in the error message.
%
% Usage (inside import pipeline):
%   guardExistingFile(fullfile(procDir,'E_GEK030.mat'), false, 'anex GEK030')

if overwrite
    return
end

if isfile(filepath)
    error('FEATHER:NWBImport:fileExists', ...
        ['%s already exists and overwrite is false.\n' ...
         'Either delete the existing file, move to a different processed-data\n' ...
         'directory, or call createFeatherObjectsFromNWB with ''overwrite'',true.\n' ...
         'File: %s'], label, filepath);
end
end