function [L,LR] = listIcme (obj)
% anex\listIcme –lists all icmes in processedDataDir
% first check if there is already a list cached

%A. check cached list
if status_cache==1
    try
        load_name = 'List_IC.mat';
        load(fullfile(getProcessedDataDir(obj),load_name)),
        display('Processed data list loaded.')
        return
    catch 'list needs to be compiled'
    end
end
%B: go through the processed dir to generate the list
%here I should also chheck for type abr

% usually the rawDir wil, only have one session, but I am allowing for
% future exepriments
D = dir(fullfile(expProcDataDir,'ICME','IC'));
%D = D(3:end);%to avoid the . ..
icmeCount = 0;
icmeID = categorical() ;
for jj = 1 : numel(D)
    jj;
    %is it s a bera?
    tmp_name =  D(jj).name;%(end-8:end)
    if size(tmp_name,2)>2
        if tmp_name(1:3)=='IC_'
            icmeCount=icmeCount+1;
            icmeID(icmeCount) = D(jj).name(5+numel(char(obj.ExpID)):end-4);
            temp_icme = load(fullfile(D(jj).folder,D(jj).name));
            if isfield(temp_icme.IC.ExpInfo,'datetime')
                temp_dt = temp_icme.IC.ExpInfo.datetime;
                icmeDate(icmeCount) = datetime(temp_dt);%no
            else
                icmeDate(icmeCount) = datetime('1111-11-11');%put dummy value
            end
        end
    end
end
if exist('icmeDate')==0
    icmeDate=nan;
end
%make
L(1).IC_SeriesID = icmeID;
L(1).ExpID = string(obj.ExpID);
L(1).allDates_SU = icmeDate;%no
L(1).dateID_SU = min(L(1).allDates_SU);%no
% the generated list will be saved. IN cse there is a
% previous list, it will be replaced
save_name = 'List_IC.mat';
save(fullfile(getProcessedDataDir(obj),save_name),'L');
end


