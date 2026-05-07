function [] = functionWhiskerPlotMEANSTD(Abisce,Ordinate,  Width, color, edgecolor)
%FUNCTIONWHISKERPLOT Summary of this function goes here
%   Detailed explanation goes here
if exist('edgecolor', 'var')==0
    edgecolor='none';
end
if color==[1 1 1]*0.99
    plotcolor='k'; 
else
    plotcolor=color; 
end

PCT=    [mean(Ordinate)-std(Ordinate), mean(Ordinate), mean(Ordinate)+std(Ordinate)]
MIN=min(Ordinate);
MAX=max(Ordinate);

plot([Abisce Abisce Abisce-(Width/4) Abisce+(Width/4)], [PCT(1) MIN MIN MIN], '-', 'color', plotcolor, 'linewidth', 1); hold on;
plot([Abisce Abisce Abisce-(Width/4) Abisce+(Width/4)], [PCT(3) MAX MAX MAX], '-', 'color', plotcolor, 'linewidth', 1)

h=fill([-Width/2 -Width/2 Width/2 Width/2]+Abisce, [PCT(1) PCT(3) PCT(3) PCT(1)], color, 'edgecolor', edgecolor); hold on;
h.LineWidth=1; 
alpha(h, 0.2);
plot([-Width/2 Width/2]+Abisce, [1 1]*PCT(2), '-', 'color', plotcolor, 'linewidth', 1)


end

