function FSL(ee,Itar,Dtar,Rtar)
if nargin==1
    Itar = 60%10; %intnsity target
    Dtar=1; %duraiton target
    Rtar=20; %repetition rate target
end

allUnits = ee.ExpMetaData.Units;

allInt=[];% unit, trace, condition
for iUnit = allUnits
    SU = sunit(ee,iUnit);
    for iT = 1 : numel(SU.Traces.SeriesID)
        T = loadSutr(sutr(ee,SU.Traces.SeriesID(iT)));
        for iCond = 1: numel(T.Stim)
            if T.Stim(iCond).duration==Dtar && isfield(T.Stim(iCond),"BurstFreq2") && T.Stim(iCond).intensity==Itar
                if T.Stim(iCond).BurstFreq2==Rtar
                    allInt=[allInt;iUnit,iT,iCond];
                end
            end
        end
    end
end

firstSpikeLatencyAll=cell(0);
allunit=unique(allInt(:,1));
for iUnit =allunit'
    SU = sunit(ee,iUnit);
    [targetIndex] = find(allInt(:,1)==iUnit);
    tmpLatencies = [];

    for iTr = targetIndex'
        T = sutr(ee,SU.Traces.SeriesID(allInt(iTr,2)));
        T = loadSutr(T);
        % go to specific condition
        iCond = allInt(iTr,3);
        for iGreen = T.greenIt(iCond).allIt
            if ~isempty(T.ST(iCond).SpikeTimes{iGreen})
                tmpLatencies = [tmpLatencies, T.ST(iCond).SpikeTimes{iGreen}(1,2) ];
            end

        end
    end
    firstSpikeLatencyAll{iUnit}=tmpLatencies; % I believe it is 2ms until the pulse begins

end
% plot
tmpCl = jet(length(firstSpikeLatencyAll));

figure()
for ii = 1 : length(firstSpikeLatencyAll)
    hold on
    % Create jittered y-axis values
    jitter = (rand(numel(firstSpikeLatencyAll{ii}),1,1)-0.5) * 0.1;
    plot([0 0.8],[ii ii],'color',tmpCl(ii,:) )
    plot([3e-3 3e-3 ],[ 0 30] ,'k-')

    plot(firstSpikeLatencyAll{ii}-0.002,ii*ones(numel(firstSpikeLatencyAll{ii}),1,1)+jitter,'.','color',tmpCl(ii,:),'markersize',12)
end
xlabel('latency, s')
ylabel('#unit')
xlim([-2e-3 80e-3])
title('1st spike latency')

figure()
for ii = 1 : length(firstSpikeLatencyAll)
    hold on

    plot([0 5],[ii ii],'color',tmpCl(ii,:) )
    plot(std([firstSpikeLatencyAll{ii}])/mean([firstSpikeLatencyAll{ii}]),ii,'.','color',tmpCl(ii,:),'markersize',12)
end
xlabel('jitter')
ylabel('#unit')
title('1st spike jitter')


figure()
jitter = (rand(numel(allUnits),1,1)-0.5) * 0.1;

for ii = 1 : length(firstSpikeLatencyAll)
    hold on
    % Create jittered y-axis values
    % Create jittered x-axis values

    plot(1+jitter(ii),std([firstSpikeLatencyAll{ii}])/mean([firstSpikeLatencyAll{ii}]),'.','color',tmpCl(ii,:),'markersize',15)
end
xlabel('jitter')
ylabel('#unit')
xlim([-1 3])
ylim([-1 5])
title('1st spike jitter')



figure()
% plot
tmpCl = jet(length(firstSpikeLatencyAll));
figure(2)
for ii = 1 : length(firstSpikeLatencyAll)
    hold on
    % Create jittered y-axis values
    plot(median(firstSpikeLatencyAll{ii})-0.002,ii,'o','color',tmpCl(ii,:))
end
plot([3e-3 3e-3 ],[ 0 30] ,'k-')

xlabel('latency, s')
ylabel('#unit')
xlim([-2e-3 10e-3])
title('1st spike latency median')
% plot
tmpCl = jet(length(firstSpikeLatencyAll));
figure(3)
for ii = 1 : length(firstSpikeLatencyAll)

    hold on
    plot(mean(firstSpikeLatencyAll{ii})-0.002,ii,'o','color',tmpCl(ii,:))
end
plot([3e-3 3e-3 ],[ 0 30] ,'k-')
xlabel('ms latency')
ylabel('#unit')
xlim([-2e-3 10e-3])
title('1st spike latency mean')
%% waveforms
firstSpikeWV = [];
allunit=unique(allInt(:,1));
firstSpikeWVAll = cell(0);
for iUnit =allunit'
    firstSpikeWV = [];

    SU = sunit(ee,iUnit);
    [targetIndex] = find(allInt(:,1)==iUnit);
    for iTr = targetIndex'
        T = sutr(ee,SU.Traces.SeriesID(allInt(iTr,2)));
        T = loadSutr(T);
        % go to specific condition
        iCond = allInt(iTr,3);
        for iGreen = T.greenIt(iCond).allIt
            if ~isempty(T.WF(iCond).waveform{iGreen})
                firstSpikeWV= [firstSpikeWV; T.WF(iCond).waveform{iGreen}(1,:) ];
            end
            firstSpikeWVAll{iUnit}=firstSpikeWV; % I believe it is 2ms until the pulse begins

        end
    end
end

%plot
wv_timeVector = (1/T.ST(1).SamplingRate:1/T.ST(1).SamplingRate:176*1/T.ST(1).SamplingRate )  -176/2*1/T.ST(1).SamplingRate;
for kk = 1 :numel(firstSpikeWVAll)
    figure()
    for ii = 1 :size(firstSpikeWVAll{kk},1)
        hold all
        plot( wv_timeVector,firstSpikeWVAll{kk}(ii,:))
        xlabel('Time (s)')
        ylabel('Amplitude (V)')
        ttlStr = strcat("spike waveform ",", StCondition: ",num2str(kk))  ;
        title(ttlStr)
    end
end









end