function []  = convertNLXDataForKilosort(IC,savepath)
% econvertNLXDataForKilosort - Reads Neuralynx Data ans saves in .dat file
% This script reads in the Raw data for an IC recording, joins the traces
% for all 32 electrodes and saves it in a .dat file format that can be read
% by kilosrt
    
    if nargin==1
        savepath = fullfile(expProcDataDir,'ICME','RESORT')
    end
    
    
    electrodes = [1:32];
    
%     % find the raw data files
    p_dat =   IC.ExpInfo.RawDataFolder{1}(strfind( IC.ExpInfo.RawDataFolder{1}, IC.ExpInfo.animal_ID)+length(IC.ExpInfo.animal_ID)+1:end);
    rawFiles = dir(fullfile(gen_dir_name(IC.D.dir), p_dat, '*.ncs'));

    %% load the raw data into the channel structure
    
    for idx_channel = electrodes%1:size(rawFiles, 1)
        cur_channel = rawFiles(idx_channel).name;
        cur_channelname = char(fullfile(gen_dir_name(IC.D.dir), p_dat, cur_channel));
        [channel(idx_channel).data.Timestamps, channel(idx_channel).data.ChannelNumbers, channel(idx_channel).data.SampleFrequencies, channel(idx_channel).data.NumberOfValidSamples, channel(idx_channel).data.Samples, channel(idx_channel).data.Header] = ...
            Nlx2MatCSC(cur_channelname,[1 1 1 1 1], 1, 1, []);
        fprintf('channel data loaded for %i \n',idx_channel)
    end
    
    % save data in a joined different format
    data_points=size(channel(1).data.Samples,1)*size(channel(1).data.Samples,2);
    joined_raw_data=zeros(length(electrodes),data_points);
    for idx_channel = electrodes%1:size(rawFiles, 1)
        joined_raw_data(idx_channel,:)=(channel(idx_channel).data.Samples(:));
    end
    
    
    save_name=fullfile(savepath,strcat(IC.SeriesID,"_RawData.dat"));
    fid = fopen(save_name,'w');
    % fwrite(fid,joined_raw_data,'int16');
    fwrite(fid,joined_raw_data,'float32');
    fclose(fid);

end

