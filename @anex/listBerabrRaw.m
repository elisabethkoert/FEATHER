function L = listBerabrRaw (obj)
            % anex\listBerabr lists all berabrs in rawDataDir
            %first check if there is already a list cached

            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_ABR_raw.mat';
                    load(fullfile(getProcessedDataDir(obj),load_name)),
                    disp('Raw list loaded.')
                catch 'list needs to be compiled';
                end
            end
            %B: go through the rawdir to generate the list
            %here I should also chheck for type abr
            for ii = 1 : numel(obj.RawDataDir)
                if  obj.RawDataDir(ii).type == "ABR"
                    % usually the rawDir wil, only have one session, but I am allowing for
                    % future exepriments
                    D = dir(gen_dir_name(obj.RawDataDir(ii).dir));
                    %D = D(3:end);%to avoid the . ..
                    beraCount = 0;
                    beraID = categorical() ;
                    for jj = 1 : numel(D)
                        %is it s a bera?
                        tmp_name =  D(jj).name;%(end-8:end)
                        if size(tmp_name,2 ) >=8 &&  ~isempty(intersect( str2double(tmp_name(1)),[0:9]))
                            if  sum(tmp_name(end-7:end) == 'BERA.mat')==8
                                beraCount=beraCount+1;
                                beraID(beraCount) = D(jj).name(1:end-4);
                                temp_bera = load(fullfile(D(jj).folder,D(jj).name));
                                temp_dt = temp_bera.ExpInfo.c;
                                beraDate(beraCount) = datetime(temp_dt);%no
                            end
                        end
                    end

                    if exist('beraDate')==0
                        beraDate=nan;
                    end
                    %make E
                    L(ii).ABR_SeriesID = beraID;
                    L(ii).ExpID = string(obj.ExpID);
                    L(ii).allDates_ABR = beraDate;%no
                    L(ii).dateID_ABR = min(L(ii).allDates_ABR);%no
                    L(ii).rawDataDir = obj.RawDataDir(ii);
                end
            end
            % the generated list will be saved. IN cse there is a
            % previous list,, it will be replaced
            save_name = 'List_ABR_raw.mat';
            save(fullfile(getProcessedDataDir(obj),save_name),'L');
        end