function B = plotBerabr(B)
% simple plot with the stimulus. I should fi the legends and labels etc.


color_temp = jet(B.nTraces);

figure()
subplot(2,1,1)
hold on
for ii = 1:B.nTraces
    plot(B.F(ii).t*1e3, B.F(ii).ABR*1e6,'color', color_temp(ii,:),'linewidth',1.5);
end


subplot(2,1,2)
hold on
for ii = 1:B.nTraces
    plot(B.F(ii).t_stim*1e3, B.F(ii).stim,'color', color_temp(ii,:),'linewidth',1.5);
end
end