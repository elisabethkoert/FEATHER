function [IC] = getCalibration(IC,OD,ComPort, calibDir, calibCollumnNames) 
% icme/getCalibration reads calibration table from CalibrationTableFile
% This funciton assumes that the LaserOutput of ExpControl already used the
% calibration table and the stimlist has the correct intensity values
% Reads the calibration table from a .txt file in the CalibrationFolder that 
% was generated with the LaserControl software 
% https://gitlab.gwdg.de/optogroup/opticsmodules/lasercontrol and uses it to
% fill the info in IC.C
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
    
        % fill in the calibration info in the icme object
        IC.C(1).CalibArray=[Power_percent/1000,Power_mW];
        IC.C(1).minIntensity=min(Power_mW);
        IC.C(1).maxIntensity=max(Power_mW);
        IC.C(1).CalibFileName=file.name;
    end

end

     % since the Stimualtion software used calibrated
     % values just copy the stimlist
    IC.C(1).stimlistCal=IC.Stim.stimlist;

end