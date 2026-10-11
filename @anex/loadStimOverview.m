function [stim_list_all, stim_list_header] = loadStimOverview(ee, ExpType)
% anex\loadStimOverview - loads the overview of IC experiments recorded for an
% animal and a specific experiment type. The overview is built and saved by
% create_overview; if it does not exist yet, or predates the recording-number
% column, it is rebuilt here so that a caller does not have to know whether
% that step has been run.
%
% Input:
%   ee (anex) animal object
%   ExpType (char) experiment type to load, one at a time, e.g. 'Single_NB'
%
% Output:
%   stim_list_all (MxN double) the stimuli of every recording of that type.
%       The first N-1 columns are the stimulus parameters; the LAST column is
%       the recording number, i.e. the trailing number of the SeriesID, so
%           sprintf('%s_%04d', ee.ExpID, value)
%       gives the recording a row came from.
%   stim_list_header (1xN cell) name of each column, last 'IC_recording_number'
%
% see also create_overview

% named explicitly rather than relying on expProcDataDir still holding this
% animal from an earlier call, which would otherwise read another animal's
% overview whenever the caller had not set it
procDir = expProcDataDir(ee.ExperimenterID, ee.ExpID);

save_name_stimlist = strcat("Stimlist_Overview_", ee.ExpID, "_", ExpType, ".mat");
overviewFile = fullfile(procDir, 'ICME', 'Overviews', save_name_stimlist);

rebuild = true;
if isfile(overviewFile)
    S = load(overviewFile);
    % Overviews written before the last column became the recording number
    % hold a position in listIcme there instead. Those resolve to a different
    % recording in any store missing an animal's earliest recordings, and they
    % carry no stim_list_header, which is how they are recognised and replaced.
    if isfield(S, 'stim_list_all') && isfield(S, 'stim_list_header') && ...
            ~isempty(S.stim_list_header) && ...
            strcmp(S.stim_list_header{end}, 'IC_recording_number')
        stim_list_all    = S.stim_list_all;
        stim_list_header = S.stim_list_header;
        rebuild = false;
    else
        fprintf(['loadStimOverview: %s %s overview predates the recording-number ' ...
                 'column, rebuilding it.\n'], ee.ExpID, ExpType);
    end
end

if rebuild
    [stim_list_all, stim_list_header] = create_overview(ee, {char(ExpType)});
end
end
