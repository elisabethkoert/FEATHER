function [fig] = plot_tonotopic_slope(anex_names_list,ExperimenterID,mode)
%anex\plot_tonotopic_slope plots the electrode depth vs CF (Hz) for one ore more
%anex
% mode can be either depthArray, then we plot as y axis point the depths
% along the array or depthBrain, hen we actually caclualte the depth inthe
% brain with the saved electrode depth, anex needs to be analysed already
% including the user input
 if ~exist('mode') 
    mode='depthArray';
 end
  if ~exist('ExperimenterID') 
    ExperimenterID='EK';
end
        fig=figure;
        hold on
    for i=1:length(anex_names_list)
        ExpID=anex_names_list{i}
        enablecache on
        ee = anex(ExpID, ExperimenterID);

        enablecache on
        in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
        load(in_dir_name);%loads UT
        
        tonotopy_Series_ID=UT.data{find(cellfun(@(x) strcmp(x,'MX_tones'),UT.data(:,find(contains(UT.fieldNames,'ExpType'))))),1};
        IC = loadIcme(icme(ee,tonotopy_Series_ID));
        [tonotopy_array, tonotopy_slope] = calculateTonotopicSlope(IC);
    
        temp_tonotopy_array=tonotopy_array;
        nan_ixs=find(isnan(temp_tonotopy_array(:,2)));
        temp_tonotopy_array(nan_ixs,:)=[];
    
        CFs_kHz=temp_tonotopy_array(:,1)/1000;
        CFs_oct=log2(CFs_kHz/.500);
        dist_on_elec_mm=temp_tonotopy_array(:,2)*0.05;
        depth_in_brain_mm=abs(Electrode.depth/1000)-(32-temp_tonotopy_array(:,2))*0.05;
        
        if mode=='depthArray'
            depth=dist_on_elec_mm;
        elseif mode=='depthBrain'
            depth=depth_in_brain_mm;
        end
                
        p= polyfit(CFs_oct,depth,1);
        tonotopy_slope=1/p(1); % oct/mm
        % plot
        scatter(CFs_oct, depth,90, 'k.','HandleVisibility','off');
        plot(CFs_oct,polyval(p,CFs_oct),'LineWidth',2,'DisplayName',strcat(ee.ExpID,': ',num2str(tonotopy_slope,'%.1f'),' oct/mm'));
    end
    if mode=='depthArray'
        ylabel('depth on elec. array [mm]'); 
    elseif mode=='depthBrain'
       ylabel('depth in brain [mm]'); 
    end
    xlabel('CF [kHz]'); 
    set(gca, 'XTick', [CFs_oct(1:2:end)])
    xticklabels(num2str([CFs_kHz(1:2:end);CFs_kHz(end)],'%.1f'))
%     ylim([ 3.3]); 
    xlim([-0.5,6.5])
    set(gca,'Ydir','reverse');
    legend('Location','best')
%     title( strcat("tonotopy slope for ",IC.SeriesID,': ',num2str(tonotopy_slope,'%.2f'),' oct/mm'),'Interpreter','none')
    hold off

end