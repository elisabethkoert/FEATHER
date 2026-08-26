function [stim_list_all]=create_overview(ee,Exp_type)
% This is a function to create overview stim lists and overview Spike lists
% for all IC Experiment types in the anex. Caching does not have an input
% on this function to make the use easier. For loading the overviews a
% separate function is implemented.
%Inputs
% ee: anex objecto for which the overviews are supposed to be created
% Exp_Type: Cell array containing the experiment types as chars in separate rows for

% experimetns of one type.
% spik_list_overview Overview (Double array) containing the spik lists for all experiments
% of one type .
% Load UT Table 
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
try 
    %attemts to load the UT 
    load(in_dir_name);%loads UT, containing user input and stimulus types for each icme
catch
    waitfor(ICuserInput(ee)) % create the UT if it is not existing yet
    load(in_dir_name);
end
if strcmp(Exp_type,'all')
    all_exp_types=unique(UT.data(:,find(contains(UT.fieldNames,'ExpType'))));
else
   all_exp_types=Exp_type;
end
good_exp=find( [UT.data{:,find(contains(UT.fieldNames,'Use'))}]>-1);
enablecache on
L =listIcme(ee);
%% Loop through all experiments types and load the right icmes 
for ii=1:numel(all_exp_types)
    icme_ix=find(cellfun(@(x) isequal(x,all_exp_types{ii}), {UT.data{:,find(contains(UT.fieldNames,'ExpType'))}}));
    icme_ix=icme_ix(ismember(icme_ix,good_exp));
    [all_icme]=arrayfun(@(x) loadIcme(icme(ee,string(L.IC_SeriesID(x)))),icme_ix);
    stim_list_cell=arrayfun(@(x) x.Stim.stimlist,all_icme,'UniformOutput',false);
    stim_list_header=all_icme(1,1).Stim.stimheader;
    stim_list_all=cell2mat(stim_list_cell');
    % spik=list_overview=arrayfun(@(x) x.Stim.stimlist,all_icme);
    %% Saving of the right files 
    save_name_stimlist = strcat("Stimlist_Overview_",ee.ExpID,"_",all_exp_types{ii},".mat");
    %test if there is alreadz a directory for SR, otherwise make it
    if  ~isfolder(fullfile(expProcDataDir,'ICME','Overviews'))
        mkdir(fullfile(expProcDataDir,'ICME','Overviews'));
        save(fullfile(expProcDataDir,'ICME','Overviews',save_name_stimlist),'stim_list_all');
    elseif  isfolder(fullfile(expProcDataDir,'ICME','Overviews')) == 1
        save(fullfile(expProcDataDir,'ICME','Overviews',save_name_stimlist),'stim_list_all');
    end

end
clear('ii');
clear('jj');
end
    
    