function generateCandidateExperimentList(modality)
% generateCandidateExperimentList - DISCOVERY HELPER, run manually in the
% console. Scans testRawDataRoot for experiments that appear to have raw
% data of the given modality, and prints a ready-to-paste cell array.
%
% This does NOT modify TestExperimentRegistry.m - review the printed
% list and copy/edit entries into that file by hand.
%
%   generateCandidateExperimentList('ABR')
%   generateCandidateExperimentList('IC')
%   generateCandidateExperimentList('Histo')

root = gen_dir_name(testRawDataRoot);
D = dir(root);
D = D([D.isdir] & ~ismember({D.name},{'.','..'}));

found = {};
for i = 1:numel(D)
    ExpID = D(i).name;
    if strcmpi(ExpID,'UserInputCopies'), continue; end
    if hasRawData(ExpID, modality)
        found{end+1} = ExpID; %#ok<AGROW>
    end
end

fprintf('\nCandidate %s experiments found under %s:\n', modality, strjoin(testRawDataRoot,'/'));
fprintf('  %s\n', strjoin(found, ', '));
fprintf('\nPaste into TestExperimentRegistry.m, case ''%s'':\n', modality);
fprintf('    list = {%s};\n\n', ...
    strjoin(cellfun(@(x) ['''' x ''''], found, 'UniformOutput', false), ','));
end