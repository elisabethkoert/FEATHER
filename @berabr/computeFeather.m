function B = computeFeather(B,CutOff,RVRS,NC)

%understand and improve RR. It is very slow for no reason.
% this function isolates a single ABR
%note that the filter increases the baseline. I  should check
%that these values are ok
%
%
if exist('CutOff') == 0
    CutOff=[300 3000];
end
if exist('RVRS') == 0
    RVRS=1;
end
if exist('NC') == 0
    NC=0;
end

%
%
SamplingRate=B.ExpInfo.FreqAcq;
SamplingPeriod=1/SamplingRate;

ABR=[];
ABReven=[];
ABRodd=[];

wc=(2*CutOff)/SamplingRate;
[filt_B, filt_A]=butter(2, wc);

for ii = 1 : size(B.R,2)
    protocol = B.Stim(ii).protocol;
    un_bera = B.R(ii);
    ExpInfo = B.ExpInfo;
    F(ii) = unitABR (un_bera,ExpInfo, protocol, CutOff,RVRS,NC);


end
%   F(ii).abrFilters = [CutOff,RVRS,NC]

B.F = F;
end

%% local
function out = unitABR (un_bera,ExpInfo, protocol, CutOff,RVRS,NC)
%why does it work with Anu and not with Anna? I was importing something
%wrong.
% this function isolates a single ABR
%note that the filter increases the baseline. I  should check that these
%values are ok
if exist('CutOff') == 0
    CutOff=[300 3000];
end
if exist('RVRS') == 0
    RVRS=1;
end
if exist('NC') == 0
    NC=0;
end


%

SamplingRate=ExpInfo.FreqAcq;
SamplingPeriod=1/SamplingRate;

ABR=[];
ABReven=[];
ABRodd=[];

wc=(2*CutOff)/SamplingRate;
[filt_B, filt_A]=butter(2, wc);

if exist('protocol')==1
    if protocol=='R'
        if un_bera.BERAdatTraceStim~=0
            CutOff2=[1000 4000];
            wc2=(2*CutOff2)/SamplingRate;
            [filt_B2, filt_A2]=butter(2, wc2);

            SignalTrace=un_bera.BERAdatTraceStim(51:end);
            t=0:length(SignalTrace)-1; t=t*SamplingPeriod;
            SignalTrace=filtfilt(filt_B2, filt_A2, double(SignalTrace));

            Deriv=gradient(SignalTrace, mean(diff(t)));
            Deriv=Deriv./max(Deriv);
            [pks,locs] = findpeaks(Deriv, 'MinPeakHeight', max(Deriv(1:100))*0.9, 'MinPeakDistance', (un_bera.isIntensTimeValue1/1000)*SamplingRate);
            locs=locs+1;
            RepetitionPeriod_sample=median(diff(locs));

            % number of iterations
            TimeWindow_sample=ExpInfo.timeView*SamplingRate;
            temp=locs+TimeWindow_sample;
            nbIt=find(temp<=length(SignalTrace));
            nbIt=nbIt(end)-1;

            % ABR analyse trace
            Signal=un_bera.BERAdatTrace(51:end)*RVRS;
            Signal=filtfilt(filt_B, filt_A, double(Signal));

            WindAvg=[];
            WindAvg_control=[];
            SignalTrace=un_bera.BERAdatTraceStim(51:end);

            for a=1:nbIt
                %     for a=ceil((0.1*SamplingRate)/RepetitionPeriod_sample):nbIt
                WindAvg(a,:)=[Signal(locs(a)-(0.001*SamplingRate)+1:locs(a)+TimeWindow_sample-1-(0.001*SamplingRate))];
                WindAvg_control(a,:)=[SignalTrace(locs(a)-(0.001*SamplingRate)+1:locs(a)+TimeWindow_sample-1-(0.001*SamplingRate))];
                if max(abs(WindAvg(a,:)))>=1.7000e-05
                    WindAvg(a,:)=NaN(1, length(WindAvg(a,:)));
                end
            end

            ABR=nanmean(WindAvg(:,:));
            if length(WindAvg)~=0
                ABRodd=nanmean(WindAvg(1:2:end,:));
                ABReven=nanmean(WindAvg(2:2:end,:));
            else
                ABRodd=NaN(1, length(length(ABR)));
                ABReven=NaN(1, length(length(ABR)));
            end
            ABR2=nanmean(WindAvg_control(:,:));
            t=0:length(ABR)-1; t=t*SamplingPeriod;
            ABR=nanmean(WindAvg(:,:));
            if length(WindAvg)~=0
                ABRodd=nanmean(WindAvg(1:2:end,:));
                ABReven=nanmean(WindAvg(2:2:end,:));
            else
                ABRodd=NaN(1, length(length(ABR)));
                ABReven=NaN(1, length(length(ABR)));
            end
            ABR2=nanmean(WindAvg_control(:,:));
        end
        t=0:length(ABR)-1; t=t*SamplingPeriod;

        out.ABR=ABR;
        out.ABReven=ABReven;
        out.ABRodd=ABRodd;
        out.t = t-0.001;
        if exist('CutOff2')
            out.filter = [CutOff;CutOff2];
        else
            out.filter = [CutOff];
        end
    elseif protocol== 'I' |  protocol=='D'  |  protocol==' '
        if length(un_bera.BERA1SingleTrace)~=0

            Signal=un_bera.BERA1SingleTrace(:, 1:end)*RVRS;
            % t=0:SamplingPeriod:(length(Signal(1,:))-1)*SamplingPeriod-0.001;
            for i=1:length(Signal(:,1))
                Signal(i,:)=filtfilt(filt_B, filt_A, double(Signal(i,:)));
            end
            Signal=Signal(:, 51:end); %why? because
            t=0:SamplingPeriod:(length(Signal(1,:))-1)*SamplingPeriod;
            t=t-0.001;

            out.ABR=mean(Signal);
            out.ABReven=mean(Signal(2:2:end,:));
            out.ABRodd=mean(Signal(1:2:end,:),1);
            out.t = t;
            out.filter = [CutOff];

        end
    end
end
if exist('out')==0
    out.ABR=nan;
    out.ABReven=nan;
    out.ABRodd=nan;
    out.t = nan;
    out.filter = nan;
end

end
