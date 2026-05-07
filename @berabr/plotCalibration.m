function plotCalibration (B)
% berabr/plot calibration : plots the calibration for the bera. In the
% first plot, the calibraiton for each beratrace intensity is plotted. IN
% the 2nd plot, we see the calibration and how it compares with
% interpolating or filtting a polynomial

f1 = figure()
subplot(2,1,1)
TL = ttlString(B);
plot([B.Stim.intensity],[B.C.Ical], 'or')
title(strcat(TL.ExpSeriesModStim,' OD:',num2str(B.C.calib.calibTag)))
legend('bera traces')
xlabel('Software out, mW')
ylabel('Corrected Intensity, mW')

subplot(2,1,2)
hold on
plot([B.C.calib.interp.xx],[B.C.calib.interp.yy], '-k')
plot([B.C.calib.PF.xx],[B.C.calib.PF.yy], 'b')
plot([B.C.calib.softwareOut],[B.C.calib.intensityOutMeasured], 'ok')
plot([B.Stim.intensity],[B.C.Ical], 'or')
xlabel('Software out, mW')
ylabel('Corrected Intensity, mW')
legend({'interpolation','polyfit','in-out','bera intensities corrected'})


hold off
end