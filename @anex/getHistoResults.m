function [HistoRes] = getHistoResults(ee)
    % anex\getHistoResults This function summarizes the transduction rate and SGN
    % density for an anex from the individual HisImg datasets

    HistoRes=[]; %return empty if no image data exists yet
    if status_cache==1
        try
            load_name = 'HistoRes.mat';
            load(fullfile(getProcessedDataDir(ee),'HISTO',load_name)),
            disp('HistoRes loaded.')
        catch 'HistoRes need to be compiled';
        end
    elseif status_cache==0
        sides={'L','R'};
        turns={'apex','mid','base'};
    %             % load HistImgs list
    %             HistImgs=listHistImg(obj,0);
        % load user input table
        in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID  ,ee.ExpID),'HISTO',strcat("HistoUserInput_",ee.ExpID, ".mat"));
        load(in_dir_name,'HistoTable');
        if ~isempty(HistoTable.data(:,1)) % make sure that any histoResults exist if the 
            for i = 1:length(sides)
                for j = 1:length(turns)
                    % prefill the object with NAN
                    HistoRes.(sides{i}).(turns{j}).density=NaN;
                    HistoRes.(sides{i}).(turns{j}).densityTransduced=NaN;
                    HistoRes.(sides{i}).(turns{j}).densityNintendoStyle=NaN;
                    HistoRes.(sides{i}).(turns{j}).densityTransducedNintendoStyle=NaN;
                    HistoRes.(sides{i}).(turns{j}).transductionRate=NaN;
                    HistoRes.(sides{i}).(turns{j}).nCells=NaN; 
                    HistoRes.(sides{i}).(turns{j}).areaSlice=NaN;
                    HistoRes.(sides{i}).(turns{j}).areaSliceNintendoStyle=NaN;
                    HistoRes.(sides{i}).(turns{j}).ImageSeriesID=NaN;
                    HistoRes.(sides{i}).(turns{j}).densityNintendoStyle2D=NaN;
                    HistoRes.(sides{i}).(turns{j}).density2D =NaN;
                    HistoRes.(sides{i}).(turns{j}).density2Dslice =NaN;
                    HistoRes.(sides{i}).(turns{j}).densityNintendoStyle2Dslice =NaN;
                    HistoRes.(sides{i}).(turns{j}).numPlanesVolume=NaN; 
                    %check if there exists an image 
                    ix = find(cellfun(@(x) strcmp(x,sides{i}),HistoTable.data(:,2))& ...
                        cellfun(@(x) strcmp(x,turns{j}),HistoTable.data(:,3))&...
                        cellfun(@(x) x==1,HistoTable.data(:,4)) );
    
                    if ~isempty(ix)
                        if length(ix)==1
                            histImg=loadHistImg(histimg(ee,HistoTable.data(ix,1)));
                            HistoRes.(sides{i}).(turns{j}).density=histImg.density;
                            HistoRes.(sides{i}).(turns{j}).densityTransduced=histImg.densityTransduced;
                            HistoRes.(sides{i}).(turns{j}).transductionRate=histImg.transductionRate;
                            HistoRes.(sides{i}).(turns{j}).nCells=histImg.nCells;
                            HistoRes.(sides{i}).(turns{j}).areaSlice=histImg.areaSlice;
                            HistoRes.(sides{i}).(turns{j}).areaSliceNintendoStyle=histImg.areaSliceNintendoStyle;
                            HistoRes.(sides{i}).(turns{j}).ImageSeriesID=histImg.SeriesID;
                            HistoRes.(sides{i}).(turns{j}).densityNintendoStyle=histImg.densityNintendoStyle;
                            HistoRes.(sides{i}).(turns{j}).densityTransducedNintendoStyle=histImg.densityTransducedNintendoStyle;
                            HistoRes.(sides{i}).(turns{j}).densityNintendoStyle2D=histImg.densityNintendoStyle2D;
                            HistoRes.(sides{i}).(turns{j}).density2D =histImg.density2D;
                            HistoRes.(sides{i}).(turns{j}).density2Dslice =histImg.density2Dslice;
                            HistoRes.(sides{i}).(turns{j}).densityNintendoStyle2Dslice =histImg.densityNintendoStyle2Dslice;
                            HistoRes.(sides{i}).(turns{j}).numPlanesVolume= histImg.numPlanesVolume;
                            
                        else %make mean value if mutliple versions for one turn and side exist
                            all_density=[];
                            all_densityTransduced=[];
                            all_transductionRate=[];
                            all_nCells=[];
                            all_areaSlice=[];
                            all_areaSliceNintendoStyle=[];
                            all_ImageSeriesID={};
                            all_densityNintendoStyle=[];
                            all_densityTransducedNintendoStyle=[];
                            all_densityNintendoStyle2D=[];
                            all_density2D=[];
                            all_density2Dslice=[];
                            all_densityNintendoStyle2Dslice=[];
                            all_numPlanesVolume=[];
                            for kk=1:length(ix)
                                histImg=loadHistImg(histimg(ee,HistoTable.data(ix(kk),1)));
                                all_density(kk)=histImg.density;
                                all_densityTransduced(kk)=histImg.densityTransduced;
                                all_transductionRate(kk)=histImg.transductionRate;
                                all_nCells(kk)=histImg.nCells;
                                
                                all_ImageSeriesID{kk}=histImg.SeriesID;
                                all_densityNintendoStyle(kk)=histImg.densityNintendoStyle;
                                all_densityTransducedNintendoStyle(kk)=histImg.densityTransducedNintendoStyle;
                                 % 2D based on extracting cell count and
                                % area from a single slice
                                if ~isnan(histImg.density2Dslice)
                                    all_density2Dslice(kk)=histImg.density2Dslice;
                                    all_areaSlice(kk)=histImg.areaSlice;
                                else
                                    all_density2Dslice(kk)=NaN;
                                    all_areaSlice(kk)=NaN;
                                end
                                if ~isnan(histImg.densityNintendoStyle2Dslice)
                                    all_densityNintendoStyle2Dslice(kk)=histImg.densityNintendoStyle2Dslice;
                                    all_areaSliceNintendoStyle(kk)=histImg.areaSliceNintendoStyle;
                                else
                                    all_densityNintendoStyle2Dslice(kk)=NaN;
                                    all_areaSliceNintendoStyle(kk)=NaN;
                                end

                                % 2D based on division by numebr of planes
                                if ~isempty(histImg.densityNintendoStyle2D)
                                    all_densityNintendoStyle2D(kk)=histImg.densityNintendoStyle2D;
                                else
                                    all_densityNintendoStyle2D(kk)=NaN;
                                end
                                if ~isempty(histImg.numPlanesVolume) 
                                    all_density2D(kk)=histImg.density2D;
                                    all_numPlanesVolume(kk)=histImg.numPlanesVolume;
                                else
                                    all_density2D(kk)=NaN;
                                    all_numPlanesVolume(kk)=NaN;
                                end

                              
                            end
                            HistoRes.(sides{i}).(turns{j}).density=mean(all_density);
                            HistoRes.(sides{i}).(turns{j}).densityTransduced=mean(all_densityTransduced);
                            HistoRes.(sides{i}).(turns{j}).transductionRate=mean(all_transductionRate);
                            HistoRes.(sides{i}).(turns{j}).nCells=mean(all_nCells);
                            HistoRes.(sides{i}).(turns{j}).areaSlice=mean(all_areaSlice,'omitnan');
                            HistoRes.(sides{i}).(turns{j}).areaSliceNintendoStyle=mean(all_areaSliceNintendoStyle,'omitnan');
                            HistoRes.(sides{i}).(turns{j}).ImageSeriesID=all_ImageSeriesID;
                            HistoRes.(sides{i}).(turns{j}).densityNintendoStyle=mean(all_densityNintendoStyle);
                            HistoRes.(sides{i}).(turns{j}).densityTransducedNintendoStyle=mean(all_densityTransducedNintendoStyle);
                            HistoRes.(sides{i}).(turns{j}).densityNintendoStyle2D=mean(all_densityNintendoStyle2D,'omitnan');
                            HistoRes.(sides{i}).(turns{j}).density2D =mean(all_density2D,'omitnan');
                            HistoRes.(sides{i}).(turns{j}).density2Dslice =mean(all_density2Dslice,'omitnan');
                            HistoRes.(sides{i}).(turns{j}).densityNintendoStyle2Dslice =mean(all_densityNintendoStyle2Dslice,'omitnan');
                            HistoRes.(sides{i}).(turns{j}).numPlanesVolume=mean(all_numPlanesVolume,'omitnan'); 
                        end
                    end
                end
            end
        end
        save_name = 'HistoRes.mat';
        save(fullfile(getProcessedDataDir(ee),'HISTO',save_name),'HistoRes')
        disp('HistoRes saved')
    end
end