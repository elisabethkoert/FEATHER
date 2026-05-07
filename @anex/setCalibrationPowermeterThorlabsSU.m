function setCalibrationPowermeterThorlabsSU(ee, Ithreshold)
% this function corrects the values from the gentech powermeter to the
% equivalent readouts form the thorlabs powermeter. It will go through all
% the sutr data and correct the .C field. Two subfields will emerge for
% the two powermeeters and the Ical values will be updated to the TL
% powermeter readout.

% W:\home\vhunniford\Sub-projects\ChRmine_ChREEF\Calibration_conversion
% the value 50GT - 90TL is artificial, as we have a problem of
% overshooting. That is only fot he 522 nm.

x_GT_OX = [43.5000   42.0000   40.7000   39.3000   37.3000   34.4000 ...
    29.1000   22.6000   15.0000   11.4000    7.6400    6.8100 ...
    5.9800    5.3600    4.6600    3.9000    3.1600    2.3900 ...
    1.6800    1.0300    1.0000    0.8550    0.7770    0.6600 ...
    0.5600    0.4540    0.3480    0.2370    0.1430   42.3000 ...
    41.0000   39.7000   38.3000   36.3000   33.5000   28.5000 ...
    22.2000   14.9000   11.3000    7.5000    5.9400    4.5700 ...
    3.9000    3.1600    2.3500    1.6400    1.0200    0.8690 ...
    0.6510    0.5500    0.4490    0.3410    0.2360    0.1420 ...
    0   47.0000   44.5000   33.1000   16.9000    0.8770 50]; %gentech

y_TL_OX = [79.4700   68.7700   60.1400   52.1800   44.0500   36.3300 ...
    28.6000   21.2800   14.0300   10.5500    7.1050    6.3590 ...
    5.5920    5.0600    4.2680    3.6570    2.8800    2.2270 ...
    1.5600    0.9400    0.9176    0.8120    0.7200    0.6220 ...
    0.5260    0.4220    0.3247    0.2237    0.1351   81.9800 ...
    70.8400   61.9500   53.8100   45.4800   37.4500   29.5400 ...
    21.9700   14.4700   10.8500    7.3290    5.7570    4.4030 ...
    3.7240    3.0090    2.3150    1.6030    0.9706    0.8385 ...
    0.6342    0.5414    0.4319    0.3335    0.2280    0.1368 ...
    0   80.5600   77.6800   35.4700   17.3500    0.9000 90]; %thorlabs

% Evaluate the fitted polynomial p and plot:
[xx_GT_OX,xInd_GT_OX] = sort(x_GT_OX); %sort the data for the fitting.
[yy_TL_OX] =y_TL_OX(xInd_GT_OX);
% Evaluate the fitted polynomial p and plot:
pOrder_OX = 6;
[p_TL_OX,S] = polyfit(xx_GT_OX,yy_TL_OX,pOrder_OX);
[f_TL_OX,delta] = polyval(p_TL_OX,xx_GT_OX,S);

x_GT_OB = [39.7000   38.5000   37.5000   36.3000   34.7000   32.6000   28.7000 ...
    23.3000   22.0000   20.5000   19.1000   17.7000   16.1000   14.7000 ...
    13.2000   11.7000   10.2000    8.5200    7.0400    5.5400    4.8000 ...
    4.0500    3.3300    2.6100    1.9600         0   42.0000   40.8000 ...
    39.8000   38.6000   37.0000   34.8000   31.2000   24.5000   21.4000 ...
    16.7000   13.6000    8.8000    7.2500    5.7100    4.9300    4.1600 ...
    3.4200    2.6800    2.0200   42.6000]; %gentech

y_TL_OB = [82.6000   74.6000   66.5000   58.3000   50.1000   42.0000   33.7700 ...
    25.1600   23.9300   22.3200   20.6900   19.0100   17.3600   15.7700 ...
    14.1200   12.4500   10.8400    9.2000    7.5900    5.9300    5.1300 ...
    4.3200    3.5300    2.8100    2.1000         0   84.7000   76.3500...
    67.8500   59.3500   51.0000   42.6600   34.3300   26.0100   22.6200...
    17.6500   14.3300    9.3200    7.6800    6.0000    5.1900    4.3800 ...
    3.5800    2.8400    2.1300   85.5000]; %thorlabs

% Evaluate the fitted polynomial p and plot:
[xx_GT_OB,xInd_GT_OB] = sort(x_GT_OB); %sort the data for the fitting.
[yy_TL_OB] =y_TL_OB(xInd_GT_OB);
% Evaluate the fitted polynomial p and plot:
pOrder_OB = 7;
[p_TL_OB,S] = polyfit(xx_GT_OB,yy_TL_OB,pOrder_OB);
[f_TL_OB,delta] = polyval(p_TL_OB,xx_GT_OB,S);

C.TL.p_TL_OB = p_TL_OB;
L = listSutr(ee);
for ii = 1 : numel(L.SU_SeriesID)
    clear C
    T = loadSutr(sutr(ee,L.SU_SeriesID(ii)));
    if strcmp( T.Stim(1).modality,'Optical')==1 %we only proceed to calibration for optical measurements
        %case statements for different stimulus hardwares
        if ~isfield(T.C, 'GT') % that is to check that I have not already converted the calibration
            switch     erase(T.Stim(1).stimulusHardware," ") % I erase the whitespaces to facilitate matlab understanding.
                case   'LaserOxxiusMPA' % I have erased the whitespaces.
                    C.GT = T.C;
                    C.TL.p_TL_OX = p_TL_OX;
                    C.TL.pOrder_OX = pOrder_OX;
                    C.TL.xx_GT_OX = xx_GT_OX;
                    C.TL.yy_TL_OX = yy_TL_OX;
                    [indexIcal]=T.C.Ical>=Ithreshold;% to only change the values that are higher than the ithreshold
                    C.Ical = T.C.Ical;
                    polyOuttmp =  polyval(p_TL_OX,T.C.Ical);
                    C.Ical(indexIcal) = polyOuttmp(indexIcal);
                    T = setC(T,C);
                    enablecache off
                    saveSutr(T);
                    enablecache on

                case   'LaserObisTTL' % I have erased the whitespaces.
                    C.GT = T.C;
                    C.TL.p_TL_OB = p_TL_OB;
                    C.TL.pOrder_OB = pOrder_OB;
                    C.TL.xx_GT_OB = xx_GT_OB;
                    C.TL.yy_TL_OB = yy_TL_OB;
                    [indexIcal]=T.C.Ical>=Ithreshold;% to only change the values that are higher than the ithreshold
                    C.Ical = T.C.Ical;
                    polyOuttmp =  polyval(p_TL_OB,T.C.Ical);
                    C.Ical(indexIcal) = polyOuttmp(indexIcal);
                    T = setC(T,C);
                    enablecache off
                    saveSutr(T);
                    enablecache on
            end
        end
    end
end


