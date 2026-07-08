function L = listBerabr (obj)
            % anex\listBerabr lists all berabrs inProcessedDataDir
            %first check if there is already a list chched

            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_ABR.mat';
                    load(fullfile(getProcessedDataDir(obj),load_name)),
                    display('Processed data list loaded.')
                catch 'list needs to be compiled'
                end
            end
            %B: go through the processed dir to generate the list
            %here I should also chheck for type abr

            % usually the rawDir wil, only have one session, but I am allowing for
            % future exepriments
            D = dir(expProcDataDir);
            %D = D(3:end);%to avoid the . ..
            beraCount = 0;
            beraID = categorical() ;
            for jj = 1 : numel(D)
                %is it s a bera?
                tmp_name =  D(jj).name;%(end-8:end)
                if size(tmp_name,2)>=2
                    if tmp_name(1:2)=='B_'
                        beraCount=beraCount+1;
                        beraID(beraCount) = D(jj).name(4+numel(char(obj.ExpID)):end-4);
                        temp_bera = load(fullfile(D(jj).folder,D(jj).name));
                        temp_dt = temp_bera.B.ExpInfo.c;
                        beraDate(beraCount) = datetime(temp_dt);%no
                    end
                end
            end
            if exist('beraDate')==0
                beraDate=nan;
            end
            %make E
            L(1).ABR_SeriesID = beraID;
            L(1).ExpID = string(obj.ExpID);
            L(1).allDates_ABR = beraDate;%no
            L(1).dateID_ABR = min(L(1).allDates_ABR);%no
            % the generated list will be saved. IN cse there is a
            % previous list,, it will be replaced
            save_name = 'List_ABR.mat';
            save(fullfile(getProcessedDataDir(obj),save_name),'L');
        end