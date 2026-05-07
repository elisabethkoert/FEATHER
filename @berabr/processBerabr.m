function B = processBerabr ( B, FcL, FcH )
% berabr\processBerabr - processes the berabr data.
% default is 300 to 3000 Hz band filter. This function adapts code from GH
% W:\home\ghoch\LabMember\tori\BERAResultNIGH_ToriShort
% The BERAdat field of IsData is filtered and stored. Additionally, the
% stimulus trace is stored.



% Default filter values if no input is assigned
if exist('FcL') == 0; FcL = 3000; end
if exist('FcH') == 0; FcH = 300; end

for ii = 1 : size (B.R,2)

    %each ABR trace will be processed individually - this is performed within the traceABR local function.

    % % %     % check if there is a BERAdat - otherwise harvest it from the
    % % %     % ExpInfo.NIdata - 'convert' part of GH code.
    % % %     % This conversion will NOT be stored with the raw data.
    % % %     noFieldBERAdat=0; if ~isfield(B.R(1,1),'BERAdat') disp('no field BERAdat'); noFieldBERAdat=1; end
    % % %     if noFieldBERAdat
    % % %         for iBERAdat= 1:size(B.R,2)
    % % %             try
    % % %                 B.R(iBERAdat).BERAdat(:) = B.ExpInfo.Dat.NIdata(iBERAdat).BERAdat(:);
    % % %             catch
    % % %                 'no BERAdat in the ExpInfo.Dat.NIdata'
    % % %             end
    % % %         end
    % % %     end
    if ~isempty(B.R(ii).BERAdat)
        F(ii) = local_traceABR (B.R(ii), B.ExpInfo, FcL, FcH); % processing of a single berabr trace
    elseif isempty(B.R(ii).BERAdat) & B.R(ii).AverageMode==2
        F(ii) = local_traceABR (B.R(ii), B.ExpInfo, FcL, FcH); % processing of a single berabr trace
    elseif isempty(B.R(ii).BERAdat) & B.R(ii).AverageMode~=2
        F(ii).ABR=nan;
        F(ii).t = nan;
        F(ii).filter = nan;
        F(ii).stim = nan;
        F(ii).t_stim = nan;
    end
end

B.F = F; % feather is assigned to the berabr

end

% ---------------------------------------------------------------------- %

function outABR = local_traceABR (R, ExpInfo, FcL, FcH)

% constants for data processing
IsData = R; % for compatibility with GH variabe names

acqFreq = ExpInfo.FreqAcqStim;
stimFreq = ExpInfo.FreqAcqStim;

AvInWin=1; % do we have the BERAdata averaged field?
AvContCut=2; % used for RR - no BERAdata - we need to do the averaging
acqDelay=0.001; % acquisition delay used for time allignment


% filters
N=2; [bl,al] = butter(N, FcL/(acqFreq/2), 'low');
N=2; [bh,ah] = butter(N, FcH/(acqFreq/2), 'high');

% output
outABR.ABR=nan;
outABR.t = nan;
outABR.filter = nan;

outABR.stim = nan;
outABR.t_stim = nan;



% % Averaging approach
display(['IsData.AvInWin:', num2str(IsData.AverageMode)])
if IsData.AverageMode == 1 %AvInWin > this is the most common condition
    disp('AvInWin')
    % berabr
    t = single(1:size(IsData.BERAdat,2));t=(t/acqFreq)-acqDelay;
    ABR = double(filtfilt(bl,al,double(filtfilt(bh,ah,double(IsData.BERAdat-IsData.BERAdat(1))))));

    % stimulus
    if ~isnan(IsData.StimDat)
        if isfield(IsData,'isIntensLaser')
            'isIntensLaser';
            TimeValueIsDate=IsData.isIntensTimeValue1;
            t_stim=single(1:size(IsData.StimDat,2)); t_stim=(t_stim/stimFreq)-acqDelay;
        else % GH?
            't_stim = t ???';
            t_stim = t; % GH?
        end
    end
    % assign outpus
    outABR.ABR=ABR;
    outABR.t = t;
    outABR.filter = [FcL FcH];

    outABR.stim = IsData.StimDat;
    outABR.t_stim = t_stim;

    % % AvContCut > this is often the case for repetition rates
elseif IsData.AverageMode == 2
    disp('AvContCut');
    CutArrayBERAdat=[];
    if ~isnan(IsData.BERAdatTraceStim)
        isTimeWin=uint32(acqFreq*0.01);
        isTimeBefore=uint32(acqFreq*0.001);
        BERAdatTraceStim=IsData.BERAdatTraceStim;
        isDataSize=size(BERAdatTraceStim,2);
        isDoAv=0;CutArrayBERAdat=[];AvBERAdatStim=[];
        % tTrace=single(1:size(IsData.BERAdatTraceStim,2)); tTrace=tTrace/stimFreq; %why does this exist?
        iAv=1;
        while iAv<isDataSize
            while iAv<isDataSize && (BERAdatTraceStim(iAv)<=1) iAv=iAv+1; end;
            if (iAv+isTimeWin<isDataSize) && (iAv-isTimeBefore>0)
                isDoAv=isDoAv+1;
                CutArrayBERAdat(isDoAv,:)=IsData.BERAdatTrace(iAv-isTimeBefore:iAv+isTimeWin);
                AvBERAdatStim(isDoAv,:)=BERAdatTraceStim(iAv-isTimeBefore:iAv+isTimeWin);
            end;
            while iAv<isDataSize && (BERAdatTraceStim(iAv)>1) iAv=iAv+1; end
        end
    end
    if ~isempty(CutArrayBERAdat)
        meanCutArrayBERAdat=mean(CutArrayBERAdat(:,:))';
        tCut=1:size(meanCutArrayBERAdat,1);tCut=tCut/stimFreq;tCut=tCut';
        FilterMeanCutArrayBERAdat=filtfilt(bl,al,filtfilt(bh,ah,(meanCutArrayBERAdat(:)-meanCutArrayBERAdat(1)) ));
        % meanAvBERAdatStim=mean(AvBERAdatStim(:,:)); GH again
        meanAvTdatStim=mean(AvBERAdatStim(:,:));

        outABR.ABR=FilterMeanCutArrayBERAdat;
        outABR.t = tCut - 0.001; % this subtraction is to correct for the 1 ms before stimulus presentation that GH includes in the data.
        outABR.filter = [FcL FcH];

        outABR.stim = meanAvTdatStim;
        outABR.t_stim = tCut - 0.001; % this subtraction is to correct for the 1 ms before stimulus presentation that GH includes in the data.

    end
end
end