function [ExpIntThr] = intensityThreshold(ee, StimModality)
% anex\intensity_threshold finds the lowest intensity for which there is
% a user W1 annotation.
%  [IntMin,indexBeraTrace,B] = intensity_threshold(ee, StimModality)
% IntMin: the minimum intensity. In case it is optical, this will be the
% radiant flux taking into consideration the calibraiton
% indexBeraTrace: the bera trace that corresponds to minimum intensity
% B: the bera  that corresponds to minimum intensity
% the software will include the Intensity protocols and recordings without
% assigned protocol, meaning bera traces that only include a single data
% trace.
% ExpIntThr is a structure that contains the minValue, the berabrs that
% correspond to this minimum intensity and the individual traces within
% each of the beras that had the minimum intensity as stimulus intensity;

ExpIntThr=[]; %return empty if no image data exists yet
if status_cache==1
    try
        load_name = strcat(StimModality,'ABRthreshhold.mat');
        load(fullfile(getProcessedDataDir(ee),load_name)),
        disp('ABR threshold results loaded.')
    catch 
        disp('ABR threshhold results need to be compiled');
    end
elseif status_cache==0

    [BoutA,iiTraceOutA] = findModProt(ee, StimModality,'I');
    [BoutB,iiTraceOutB] = findModProt (ee, StimModality,' ');
    % BoutB = denan(BoutB);
    % iiTraceOutB = denan(iiTraceOutB);
    
    % here I should try to see if I can concatinate them
    if isempty(BoutB)
        B_all = BoutA;
        iiTraceOut = iiTraceOutA;
    elseif ~isempty(BoutB)
        B_all = [BoutA,BoutB];
        iiTraceOut = [iiTraceOutA,iiTraceOutB];
    end
    ExpIntThr=struct();

    % separate by different Lasers if existing
    stim_types={};
    for ii=1:length(B_all)
        stim_types{ii}=B_all(ii).Stim.stimulusHardware;
    end
    stim_types=unique(stim_types);
    minValues=[];
    minTraces=[];
    all_Bs=[];
    for jj=1:length(stim_types)
        % for all these bera indexes find the minimum intensity and pool them
        IntMin_temp = nan(numel(B_all),1,1);
        indexBeraTrace_temp = nan(numel(B_all),1,1);
    
    
        
        for ii = 1 : numel(B_all)
            if ~strcmp(B_all(ii).Stim(1).stimulusHardware,stim_types{jj})
                continue
            end
            [IntMin_temp(ii),indexBeraTrace_temp(ii)] = intensityThreshold(B_all(ii));
        end
        
        % find the lowest intensity
        minValue = min(IntMin_temp); %there might be more than one minimum values, if the same intensity has been used multiple times
        [iMin, ~] = find(IntMin_temp == minValue);
        minValues=[minValues,minValue];
        minTraces={minTraces,indexBeraTrace_temp(iMin)}
        all_Bs=[all_Bs,B_all(iMin)]
    end

    ExpIntThr.IntensityThreshold = minValues;
    ExpIntThr.Hardware=stim_types;
    ExpIntThr.B = all_Bs;
    ExpIntThr.minTrace = minTraces;
    save_name = strcat(StimModality,'ABRthreshhold.mat');
    save(fullfile(getProcessedDataDir(ee),save_name),'ExpIntThr'),
    disp('ABR threshold results saved')
end
    
end









