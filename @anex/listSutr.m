function [L,LR] = listSutr (obj)

% anex\listSutr - pending
%first check if there is already a list chched

%A. check cached list
if status_cache==1
    try
        load_name = 'List_SUTR.mat';
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
D = dir(expProcDataDir);
%D = D(3:end);%to avoid the . ..
sutrCount = 0;
sutrID = categorical() ;
for jj = 1 : numel(D)
    jj
    %is it s a bera?
    tmp_name =  D(jj).name;%(end-8:end)
    if size(tmp_name,2)>=2
        if tmp_name(1:2)=='T_'
            sutrCount=sutrCount+1;
            sutrID(sutrCount) = D(jj).name(4+numel(char(obj.ExpID)):end-4);
            temp_sutr = load(fullfile(D(jj).folder,D(jj).name));
            temp_dt = temp_sutr.T.ExpInfo.c;
            sutrDate(sutrCount) = datetime(temp_dt);%no
        end
    end
end
if exist('sutrDate')==0
    sutrDate=nan;
end
%make E
L(1).SU_SeriesID = sutrID;
L(1).ExpID = string(obj.ExpID);
L(1).allDates_SU = sutrDate;%no
L(1).dateID_SU = min(L(1).allDates_SU);%no
% the generated list will be saved. IN cse there is a
% previous list,, it will be replaced
save_name = 'List_SUTR.mat';
save(fullfile(getProcessedDataDir(obj),save_name),'L');
end


