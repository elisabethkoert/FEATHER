function [stim_list_all, stim_list_header] = create_overview(ee, Exp_type)
% anex\create_overview - builds the overview stimlist for one or more IC
% experiment types of an animal and saves it in ICME\Overviews.
% Caching has no input on this function to keep its use simple; loading is
% done by loadStimOverview, which calls this function when the overview it
% wants does not exist yet.
%
% Input:
%   ee (anex) animal the overviews are built for
%   Exp_type (cell of char | char) experiment types to build, one per row,
%       e.g. {'Single_NB'}. Pass 'all' to build every type listed in the user
%       input table; the returned array is then the one of the last type.
%
% Output:
%   stim_list_all (MxN double) the stimuli of every recording of that type,
%       stacked. The first N-1 columns are the stimulus parameters of
%       IC.Stim.stimlist; the LAST column is the recording number, i.e. the
%       trailing number of the recording's SeriesID.
%   stim_list_header (1xN cell) name of each column, last entry
%       'IC_recording_number'. It is saved with the array and is what
%       loadStimOverview uses to recognise an up-to-date overview.
%
% The recording number follows the same convention as the animal lists, so a
% caller turns a value from the last column straight into a SeriesID with
%   sprintf('%s_%04d', ee.ExpID, value)
% and never has to know a recording's position in listIcme. Overviews written
% before this change stored that position instead, which resolves to the wrong
% recording in any store that does not hold an animal's earliest recordings.
%
% see also loadStimOverview

%% user input table, which names every recording and its experiment type
in_dir_name = fullfile(expProcDataDir(ee.ExperimenterID, ee.ExpID), 'ICME', ...
    strcat("ICUserInput_", ee.ExpID, ".mat"));
try
    load(in_dir_name);          %#ok<LOAD> loads UT
catch
    waitfor(ICuserInput(ee))    % create the UT if it does not exist yet
    load(in_dir_name);          %#ok<LOAD>
end

col_series = 1;                                             % SeriesID
col_type   = find(contains(UT.fieldNames, 'ExpType'), 1);
col_use    = find(contains(UT.fieldNames, 'Use'), 1);

if ischar(Exp_type) && strcmp(Exp_type, 'all')
    all_exp_types = unique(UT.data(:, col_type));
else
    all_exp_types = cellstr(Exp_type);
end
good_exp = find([UT.data{:, col_use}] > -1);

enablecache on
outDir = fullfile(expProcDataDir(ee.ExperimenterID, ee.ExpID), 'ICME', 'Overviews');
if ~isfolder(outDir), mkdir(outDir); end

%% one overview per requested experiment type
for is_type = 1:numel(all_exp_types)

    ut_rows = find(cellfun(@(x) isequal(x, all_exp_types{is_type}), {UT.data{:, col_type}}));
    ut_rows = ut_rows(ismember(ut_rows, good_exp));
    if isempty(ut_rows)
        warning('anex:create_overview:noRecordings', ...
            '%s has no usable recordings of type %s', ee.ExpID, all_exp_types{is_type});
        continue
    end

    % recordings are named, not addressed by their position in listIcme, so
    % the overview comes out right against any store that holds them
    seriesIDs = string(UT.data(ut_rows, col_series));
    all_icme  = arrayfun(@(s) loadIcme(icme(ee, s)), seriesIDs);

    stim_list_cell   = arrayfun(@(x) x.Stim.stimlist, all_icme, 'UniformOutput', false);
    stim_list_header = all_icme(1).Stim.stimheader;

    for is_rec = 1:numel(stim_list_cell)
        rec_no = local_recordingNumber(seriesIDs(is_rec));
        stim_list_cell{is_rec}(:, end+1) = ...
            repmat(rec_no, size(stim_list_cell{is_rec}, 1), 1); %#ok<AGROW>
    end
    stim_list_header{1, end+1} = 'IC_recording_number'; %#ok<AGROW>

    stim_list_all = cell2mat(stim_list_cell(:));

    save_name_stimlist = strcat("Stimlist_Overview_", ee.ExpID, "_", ...
        all_exp_types{is_type}, ".mat");
    save(fullfile(outDir, save_name_stimlist), 'stim_list_all', 'stim_list_header');
end
end

% -----------------------------------------------------------------------------
function n = local_recordingNumber(seriesID)
% Trailing number of <animal>_<number>.
tok = regexp(char(seriesID), '(\d+)\s*$', 'tokens', 'once');
if isempty(tok)
    error('anex:create_overview:seriesID', ...
        'cannot read a recording number from SeriesID "%s"', char(seriesID));
end
n = str2double(tok{1});
end
