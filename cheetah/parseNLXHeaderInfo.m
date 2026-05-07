function headerInfo = parseNLXHeaderInfo(header)
    % Parse Neuralynx header information 
    
    % ADBitVolts
    strToFind = '-ADBitVolts';
    idx = find(cellfun(@(x) contains(x, strToFind), header, 'UniformOutput', true), 1);
    headerInfo.ADBitVolts = str2double(deblank(strrep(header{idx}, strToFind, '')));
    
    % Input Inversion
    strToFind = '-InputInverted ';
    idx = find(cellfun(@(x) contains(x, strToFind), header, 'UniformOutput', true), 1);
    if isequal(deblank(strrep(header{idx}, strToFind, '')), 'True')
        headerInfo.InputInversion = -1;
    else
        headerInfo.InputInversion = 1;
    end
    headerInfo.ADBitVolts = headerInfo.ADBitVolts * headerInfo.InputInversion;    headerInfo.ADBitVolts = headerInfo.ADBitVolts * headerInfo.InputInversion;
    
   
    
    strToFind = '-DspDelayCompensation Disabled';
    if ~isempty(find(cellfun(@(x) contains(x, strToFind), header, 'UniformOutput', true), 1))
         % DSP Delay
            strToFind = '-DspFilterDelay';
            idx = find(cellfun(@(x) contains(x, strToFind), header, 'UniformOutput', true), 1);
            tmp_string = strrep(header(idx), '�s', 'us');        
            split_info=split(tmp_string{1},' ');
            headerInfo.DspDelay = str2double(split_info{2}) / 1e6;
    else
        headerInfo.DspDelay = 0;
    end
end

