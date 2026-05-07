function setCalibrationSU(ee, calibExcelDir)
% set the calibration for the SU green laser
% harvest the names of the excel calibraiton files
if ~exist(calibExcelDir)
    calibExcelDir = fullfile(expProcDataDir(ee.ExperimenterID, ee.ExpID), strcat("Calibration_", ee.ExpID, ".xlsx"));
    [~,xl_hardware_sheet]=xlsfinfo(calibExcelDir)
    for k=1:numel(xl_hardware_sheet)
        k
        [~,~,calibEXC{k}]=xlsread(calibExcelDir,xl_hardware_sheet{k});
        try         allXlsSheet.(erase(xl_hardware_sheet{k}," ")) = calibEXCparser (calibEXC{k},ee);
        catch
            "invalid field name or the parser does not work "
        end
    end
else
    [~,xl_hardware_sheet]=xlsfinfo(calibExcelDir)
    for k=1:numel(xl_hardware_sheet)
        [~,~,calibEXC{k}]=xlsread(calibExcelDir,xl_hardware_sheet{k});
        try         allXlsSheet.(erase(xl_hardware_sheet{k}," ")) = calibEXCparser (calibEXC{k},ee);
        catch
            "invalid field name or the parser does not work "
        end
    end
end

% assign correct callibration per berabr, using the user OD input and the
% calibration excel file.
L = listSutr(ee);
for ii = 1 : numel(L.SU_SeriesID)
    clear Ical
    T = loadSutr(sutr(ee,L.SU_SeriesID(ii)));

    if strcmp( T.Stim(1).modality,'Optical')==1 %we only proceed to calibration for optical measurements
        %case statements for different stimulus hardwares

        switch     erase(T.Stim(1).stimulusHardware," ") % I erase the whitespaces to facilitate matlab understanding.
            case   'LaserOxxiusMPA' % I have erased the whitespaces.

                [~,ii_inC] = find(T.ExpInfo.Stimulus(5).DiodeCurrentMPA == [allXlsSheet.LaserOxxiusMPA.calibTag]);
                C.calib = allXlsSheet.LaserOxxiusMPA(ii_inC);
                %create reference values for each individual trace wwithin a berabr
                for jj = 1 : T.nConditions
                    if isfield(C.calib, 'interp')
                        [iInt] = find(C.calib.interp.xx==T.Stim(jj).intensity);
                        if ~isempty(iInt)
                            Ical(jj) = C.calib.interp.yy(iInt);
                        end
                    elseif isempty(Ical(jj))
                        Ical(jj) = polyval(C.calib.PF.P, T.Stim(jj).intensity);
                    end
                end
                C.Ical = Ical;
                T = setC(T,C);
                enablecache off
                saveSutr(T);
                enablecache on
        end 
    end
L.SU_SeriesID(ii)
end
% for jj = 1 : B.nTraces
%
%     if isfield(C.calib, 'interp')
%         [iInt] = find(C.calib.interp.xx==B.Stim(s).intensity);
%         if ~isempty(iInt)
%             Ical = C.calib.interp.yy(iInt);
%         end
%     else
%         Ical = polyval(C.interp.PF.P, B.Stim(ii).intensity);
%     end
% end
end


%%
function str_out = calibEXCparser (calibEXC,ee)
%test that the experiment name matxhes. Otherwise, ABORT!
if calibEXC{1,2}~=ee.ExpID
    error("the Experiment ID in the excel file does not match the experiment name. Check your files, and look for typos.")
end

%actual parser part
nCTs =  size(calibEXC,2)-1 ;%number of different Calibration Tags
for ii = 1 : nCTs
    jj=ii+1;
    if ~isnan(calibEXC{2,jj})
        str_out(ii).calibTag = calibEXC{2,jj}; % this will be values 0-100 for current (oxiusMPA laser) or optical density 0-1(ObisTTL etc)
        str_out(ii).softwareOut = vertcat(calibEXC{3:end,1});
        str_out(ii).intensityOutMeasured = vertcat(calibEXC{3:end,jj});
        str_out(ii).PF = local_pf(str_out(ii).softwareOut, str_out(ii).intensityOutMeasured);
        str_out(ii).interp = local_interp(str_out(ii).softwareOut, str_out(ii).intensityOutMeasured);
    end
end

'allalal'

'la'
end

%local funcitons called within the parser. interpollation and polyfit
%approaches for calibration
function out_pf = local_pf (x,y)
[yy,x_indexx] = denan(y);
xx = x(x_indexx);
[P,S] = polyfit(xx,yy,3);
yy = polyval(P,xx);
out_pf = CollectInStruct(x,y,xx,yy,P,S);
end

function out_interp = local_interp (x,y)
% [y_val,x_index] = denan(y);
% xx_t = x(x_index);
% xq = 100:-0.01:0;%it wass -1
% vq1 = interp1(xx_t,y_val,xq);
% yy = vq1;
% xx = xq;

[y_val,x_index] = denan(y);
xx_t = x(x_index);
xq = 100:-0.01:0;%it wass -1
vq1 = interp1(xx_t,y_val,xq);
yy = vq1;
xx = xq;
%vq1(end) = 0%this is hardcoded 0 calibration when the laser is
out_interp = CollectInStruct(x,y,xx,yy);
end

