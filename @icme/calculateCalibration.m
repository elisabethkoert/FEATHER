function [IC] = calculateCalibration(IC,OD,ComPort, calibDir, calibCollumnNames) 
% icme/calculateCalibration reads calibration table and adapts the stimlist
% This funciton assumes that the LaserOutput of ExpControl was not
% calibrated so it looks for a calibration .txt file in the format as
% generated with LaserControl 
% https://gitlab.gwdg.de/optogroup/opticsmodules/lasercontrol reads int he
% calibration array and uses it to interpolate the calibrated stimlist
% input: 
%   IC (icme): IC recording object
%   OD (string): optical density filter value ('0','1') or external current ('5','10') that is
%       manually set during calibration of the Laser
%   ComPort (String): Serial Port of the Laser
%   calibDir(String): Location of the claibration files, defualt with IC
%       raw data
%   calibCollumnNames (cell of strings): names of the collumns of values in
%       the calibration file, default( {'Power_Percent', 'Current_mA', 'Power_mW'};)
% Output:
%   IC (icme): updated IC recording object containing a claibrated stimlist
%   and 

if ~exist('calibDir')
    calibDir = IC.D.dir;
end
if ~exist('calibCollumnNames')
    calibCollumnNames = {'Power_Percent', 'Current_mA', 'Power_mW'};
end

% initilaize the stimlist, the claibratied values will overwrite the
% ones saved by ExpControl
stimlistCal=IC.Stim.stimlist;


if contains(IC.Stim.exp_type,'OBIS') ||contains(IC.Stim.exp_type,'OXXIUS') ||...
        contains(IC.Stim.exp_type,'DarkRedLaser')
    file=dir(fullfile(gen_dir_name(calibDir), sprintf('*%s_Power_Calibration_%s.txt',ComPort,OD)));
    if isempty(file)
        IC.C(1).CalibArray=[];
        IC.C(1).minIntensity=NaN;
        IC.C(1).maxIntensity=NaN;
        IC.C(1).CalibFileName=NaN;
    else % read in calibration if file was found
        if length(file)>1
            file=file(1);
        end
        full_filename=fullfile(file.folder,file.name);
        fileText = fileread(full_filename);
        % Look for the header line
        headerLineLocation = strfind(fileText, 'Power (mW)');
        % Count the number of newline characters before that point
        headerLineCount = count(fileText(1:headerLineLocation), newline);
        % Now read in the table
        array = readtable(full_filename, 'HeaderLines', headerLineCount);
         % Rename the column variables to more MATLAB-friendly names
        array.Properties.VariableNames = calibCollumnNames;
    
        Power_percent=array{:,contains(array.Properties.VariableNames,'Power_Percent')};
        Power_mW=array{:,contains(array.Properties.VariableNames,'Power_mW')};

        %find polynomial fit and store the coefficients
        degree=5;
        coeffs= polyfit( Power_percent,Power_mW, degree);
        used_intensities_percent=IC.Stim.stimlist(:,1);
        used_intensities_mW=polyval(coeffs,used_intensities_percent);
        stimlistCal(:,1)=used_intensities_mW;

    
        % fill in the calibration info in the icme object
        IC.C(1).CalibArray=[Power_percent/1000,Power_mW];
        IC.C(1).minIntensity=min(Power_mW);
        IC.C(1).maxIntensity=max(Power_mW);
        IC.C(1).CalibFileName=file.name;
    end

elseif contains(IC.Stim.exp_type,'SBcreeLED10x1')            
            %harvest implant and resistor information from the data
            try
                resistorLevel = str2num((IC.ExpInfo.Res_lvl{:}));
            catch
            resistorLevel = 0;
                'resistor level not given'
            end
            try
                implantID = IC.ExpInfo.implant_ID{:};
            catch
                implant_ID = 'notgiven';
                'implant ID not given'
            end
            file=dir(fullfile(gen_dir_name(calibDir), sprintf('*_SB_%s_Power_Calibration_ID_%s_ResistorNo_%i.txt',ComPort,implant_ID,resistorLevel)));
%             if isempty(file)
%                 IC.C(1).CalibArray=[];
%                 IC.C(1).minIntensity=NaN;
%                 IC.C(1).maxIntensity=NaN;
%             else % read in calibration if file was found
%                 if length(file)>1
%                     file=file(1);
%                 end
% 
%             %load the correct calibration
%             tmpCal=[];
%             for kk = 1 : height(T_cal)
%                 if strcmp(T_cal.laserType(kk),"SB") & (T_cal.filter(kk)==resistorLevel) & strcmp(T_cal.implantID(kk),implantID)
%                     tmpCal = T_cal(kk,:);
%                 end
%             end
%            if isempty(tmpCal)
%                disp("not calibration found")
%                continue
%            end
%             % save the calibration array with the ICME object
%             IC.C(1).CalibArray =  tmpCal;
%             % make the fits for all the channels and storethem in
%             calibArray = tmpCal.calibArray{1};
%             allChannels = unique(calibArray(:,1));
%             for   ll = 1: numel(allChannels)
%                 emitterCal(ll).emitterID =allChannels(ll);
%                 emitterCal(ll).calibArray = calibArray(calibArray(:,1)==allChannels(ll),:);
%                 emitterCal(ll).calibArray(emitterCal(ll).calibArray(:,3)<0.001,3) = 0;%ommit the negative values, 0.001
%                 [itarget,~]=find([emitterCal(ll).calibArray(:,3)]==0);
%                 if numel(itarget)>1
%                     emitterCal(ll).calibArray(itarget,:)=[];
%                     emitterCal(ll).calibArray=[emitterCal(ll).emitterID,0,0;emitterCal(ll).calibArray];%
%                 end
%                 emitterCal(ll).degree=2;
%                 emitterCal(ll).coeffs= polyfit(emitterCal(ll).calibArray(:,2),emitterCal(ll).calibArray(:,3),    emitterCal(ll).degree);
%             end
%             IC.C(1).emitterCal = emitterCal;
%             %stimlist
%             stimlistCal = IC.Stim.stimlist;
%            if size(stimlistCal,2) <= 8 %bad bad practice, as it hndles the probles fro the different channels
%             %look into the header
%             [indexIntensity] = strcmp(IC.Stim.stimheader,'Intensity%');
%             [indexChannel] = strcmp(IC.Stim.stimheader,'channel');
%             % create the stimlistCal
%             if size(IC.Stim.stimheader,2)==size(IC.Stim.stimlist,2)
%                 for iCal = 1 : size(stimlistCal,1)
% 
%                     if stimlistCal(iCal,indexIntensity) == 0
%                         stimlistCal(iCal,indexIntensity) = 0;
%                     else
%                         stimlistCal(iCal,indexIntensity) =polyval(IC.C.emitterCal(stimlistCal(iCal,indexChannel)).coeffs,  stimlistCal(iCal,indexIntensity));
%                     end
%                 end
%                 IC.C(1).stimlistCal=stimlistCal;
%                % IC.C(1).stimlistCal=stimlistCal;
%                 IC.C(1).impossibleStimuli=[];
%             end
end



% the calibrated stimlist is sure to have real intenstiy values    
IC.C(1).stimlistCal=stimlistCal;
end