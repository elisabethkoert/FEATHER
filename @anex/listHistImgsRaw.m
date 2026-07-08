function L = listHistImgsRaw (obj)
            % anex\listHistImgsRaw lists all histimgs in rawDataDir
            % goes through the folder containing the Nintendo results and
            % checks how many HistIMgs are associated to an experiment and
            % makes a list of the names
            initHistoFolder(obj)% create folder substructure if necessary
            %A. check cached list
            if status_cache==1
                try
                    load_name = 'List_Hist_raw.mat';
                    load(fullfile(getProcessedDataDir(obj),'HISTO',load_name)),
                    disp('Raw list loaded.')
                catch 'list needs to be compiled';
                end
            elseif status_cache==0
                %B: go through the rawdir to generate the list
                L=[];
                for ii = 1 : numel(obj.RawDataDir)
                    if  obj.RawDataDir(ii).type == "NintendoRes"
                        % usually the rawDir wil, only have one session, but I am allowing for
                        % future exepriments
                        D = dir(gen_dir_name(obj.RawDataDir(ii).dir));
                        %D = D(3:end);%to avoid the . ..
                        HistImgsCount = 0;
                        SeriesID = categorical();
                        ImgSides = categorical();
                        ImgTurns = categorical();
                        ImgVersions = [];
                        ImgFilenames={};
                        % the naming conventions are different, JG only has
                        % animal number in histo, EK has GEKXXX

                        ExpID=obj.ExpID;
                        if obj.ExperimenterID == 'JG'
                            ExpID=char(obj.ExpID);
                            ExpID=string(ExpID(4:end));
                        end
                        for jj = 1 : numel(D)
                            %is it s a bera?
                            tmp_name =  D(jj).name;  %(end-8:end);
                            if contains(tmp_name,ExpID) && contains(tmp_name,'.csv')
                                HistImgsCount=HistImgsCount+1;
                                ImgFilenames{HistImgsCount}=tmp_name;
                                tmp_name=strrep(tmp_name,'.csv','');
                                descr=split(tmp_name,'-');
                                descr2=split(descr{1},'_');
                                descr2(1)=[]; % remove ExpID
                                % check for L/R

                                if ~isempty(descr2)
                                    if any(cellfun(@(x) contains(x,'L'),descr2))
                                        ImgSides(HistImgsCount)='L';
                                    elseif any(cellfun(@(x) contains(x,'R'),descr2))
                                        ImgSides(HistImgsCount)='R';
                                    end

                                else
                                    if contains(tmp_name,'L')
                                        ImgSides(HistImgsCount)='L';
                                    end
                                    if contains(tmp_name,'R')
                                        ImgSides(HistImgsCount)='R';
                                    end
                                end

                                % check for turn

                                if contains(tmp_name,'ap','IgnoreCase',true)
                                    ImgTurns(HistImgsCount)='apex';
                                end
                                if contains(tmp_name,'bas','IgnoreCase',true)
                                    ImgTurns(HistImgsCount)='base';
                                end
                                if contains(tmp_name,'med','IgnoreCase',true)||contains(tmp_name,'mid','IgnoreCase',true)
                                    ImgTurns(HistImgsCount)='mid';
                                end



                                % check for version
                                img_version=1;
                                if ~isempty(descr2)
                                    if any(cellfun(@(x) contains(x, 'v'), descr2))
                                        vIndices = (cellfun(@(x) contains(x, 'v'), descr2));
                                        img_version= str2num(descr2{vIndices}(2));
                                    end

                                else
                                    if contains(tmp_name,'v2')
                                        img_version=2;
                                    end
                                end
                                ImgVersions(HistImgsCount)=img_version;

                                SeriesID(HistImgsCount)=strjoin({char(ImgSides(HistImgsCount)),char(ImgTurns(HistImgsCount)),sprintf('v%i', ImgVersions(HistImgsCount)),'40x'},'_');



                            end
                        end

                        %make List
                        L(1).HistImg_SeriesID = SeriesID;
                        L(1).ExpID = string(obj.ExpID);
                        L(1).Sides = ImgSides;
                        L(1).Turns = ImgTurns;
                        L(1).Versions = ImgVersions;
                        L(1).Filenames=ImgFilenames;
                    end
                end
                % the generated list will be saved. IN cse there is a
                % previous list,, it will be replaced
                save_name = 'List_Hist_raw.mat';
                save(fullfile(getProcessedDataDir(obj),'HISTO',save_name),'L');
            end
end