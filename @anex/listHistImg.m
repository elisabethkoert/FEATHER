function L = listHistImg (obj, rewrite_list)
            % anex\listHistimg lists all histimgs in processedDataDir
            % first check if there is already a list and use this as long as
            % rewrite_list does not exist
            if nargin < 2
                rewrite_list = 0;
            end
            initHistoFolder(obj)% create folder substructure if necessary
            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_Hist.mat';
                    load(fullfile(getProcessedDataDir(obj),'HISTO',load_name)),
                    display('Processed data list loaded.')
                    if rewrite_list==0
                        return
                    end
                catch 'list needs to be compiled'
                end
            end

            %B: go through the processed dir to generate the list

            % usually the rawDir wil, only have one session, but I am allowing for
            % future exepriments
            D = dir(fullfile(expProcDataDir,'HISTO'));
            %D = D(3:end);%to avoid the . ..
            Count = 0;
            ImgID = categorical() ;
            ImgSides = categorical();
            ImgTurns = categorical();
            ImgVersions = [];
            for jj = 1 : numel(D)
                %is it s a bera?
                tmp_name =  D(jj).name;%(end-8:end)
                if size(tmp_name,2)>=2
                    if tmp_name(1:2)=='H_'
                        Count=Count+1;
                        temp_histImg = load(fullfile(D(jj).folder,D(jj).name));
                        ImgID(Count) = temp_histImg.H.SeriesID;
                        ImgSides(Count) = temp_histImg.H.side;
                        ImgTurns(Count) = temp_histImg.H.turn;
                        ImgVersions(Count) = temp_histImg.H.version;
                    end
                end
            end

            %make E
            L(1).HistImg_SeriesID = ImgID;
            L(1).ExpID = string(obj.ExpID);
            L(1).Sides = ImgSides;
            L(1).Turns = ImgTurns;
            L(1).Versions = ImgVersions;%no
            % the generated list will be saved. IN cse there is a
            % previous list,, it will be replaced
            save_name = 'List_Hist.mat';
            save(fullfile(getProcessedDataDir(obj),'HISTO',save_name),'L');
end