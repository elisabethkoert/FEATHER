function tf = hasRawData(ExpID, modality)
% hasRawData - quick check for presence of raw data of a given modality
% for one candidate experiment. Used for TestParameter discovery.
folder = gen_dir_name([testRawDataRoot, ExpID]);
if ~isfolder(folder)
    tf = false; return
end
switch modality
    case 'ABR'
        tf = ~isempty(dir(fullfile(folder,'*BERA.mat')));
    case 'IC'
        tf = ~isempty(dir(fullfile(folder, [char(ExpID) '_*.m'])));
    case 'Histo'
        tf = isfolder(fullfile(folder,'Histo')) && ...
             ~isempty(dir(fullfile(folder,'Histo','*.csv')));
    otherwise
        error('hasRawData:unknownModality','unknown modality %s',modality);
end
end