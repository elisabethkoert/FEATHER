function setCalibrationBeraFromLaserControl(ee,calibDir)
%readCalibrationBeraFromLaserControl Read the calibration files created in
%the AutomatedCalibration GUI LaserControl and assigns calibrated intesnity
%values to all Berabr objects
% the User input Gui needs to have been filled beforehand
%
% input:
%   ee (anex) animal experiment to assign claibration values to
%   calibrDir (str) if the calibration files are not stored with the ABR
%   raw data (where they should be stored)

if ~exist('calibDir')
    calibDir = ee.RawDataDir(find([ee.RawDataDir.type]=='ABR')).dir;
end

% import the user information about the applied filters
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),strcat("ODui_", ee.ExpID, ".mat"));
load(in_dir_name);%loads UT

% find all names of .txt calib files
files=dir(fullfile(gen_dir_name(calibDir), '*Power_Calibration*.txt'));
TableVarName={'date','laserType','ComPort', 'calibArray', 'filter'};
T_cal=table('size', [1,5], 'VariableTypes', { 'string','string','string', 'cell', 'double'});
T_cal.Properties.VariableNames=TableVarName;
for i = 1:length(files)
    filename = files(i).name; % convert to lower case for comparison
    if contains(filename,'Mixed')
        continue
    end
    % extract file info from header
    file_desc=split(filename,'_');
    T_cal.date(i)=file_desc{1};
    T_cal.filter(i)=str2double(erase(file_desc{end},'.txt'));
    T_cal.laserType(i)=file_desc{3};
    T_cal.ComPort(i)=file_desc{cellfun(@(x) contains(x,'COM') , file_desc)};

    % prep to read  the calibration file
    full_filename=fullfile(files(i).folder,filename);
    fileText = fileread(full_filename);
    % Look for the header line
    headerLineLocation = strfind(fileText, 'Power (mW)');
    % Count the number of newline characters before that point
    headerLineCount = count(fileText(1:headerLineLocation), newline);
    % Now read in the table
    myTable = readtable(full_filename, 'HeaderLines', headerLineCount);
    % Rename the column variables to more MATLAB-friendly names
%     myTable.Properties.VariableNames = {'Power_Percent', 'Current_mA', 'Power_mW'};
    
    % save in calib array
    T_cal.calibArray{i}= table2array(myTable);
    
    % BS green laser: read out attenuator mode (MPA/Current)
    if contains( T_cal.laserType(i),'Oxxius+MPA')
         attenuatorValue = erase(file_desc{end},'.txt');   % get attenuation type
         T_cal.laserType(i)=strcat(T_cal.laserType(i),' Type_',attenuatorValue);
    end

   
end

% assign correct callibration per berabr, using the user OD input and the
% calibration excel file.
L = listBerabr(ee);
for ii = 1 : numel(L.ABR_SeriesID)
    clear Ical
    B = loadBerabr(berabr(ee,L.ABR_SeriesID(ii)));

    

    if strcmp( B.Stim(1).modality,'Optical')==1 % we only proceed to calibration for optical measurements    
        
        if contains(UT.data{ii,3},'Obis')
            B_OD = UT.data{ii,2};
            B_hardware=UT.data{ii,3};
            B_hardware_desc=split(B_hardware,' ');
            B_hardware_desc(cellfun(@(x) isempty(x),B_hardware_desc))=[];
            laserType=B_hardware_desc{2};
            if length(B_hardware_desc)>2
                SerNr=B_hardware_desc{3};
            else 
                SerNr='151367';
            end

            
            if SerNr=='151367'
                ComPort='COM10';
            elseif SerNr=='191143'
                ComPort='COM3';
            end
    
    
            ii_inC = find(T_cal.ComPort==ComPort & T_cal.filter==B_OD);
            C.calib = T_cal.calibArray(ii_inC);

        elseif contains(UT.data{ii,3},'L660')
           ii_inC = find(contains(T_cal.laserType,'L660') );
           C.calib = T_cal.calibArray(ii_inC);
            % BERA only saves the % values for the DRL, therefore we need
            % to change the output values to percent
            C.calib{1}(:,1)=(C.calib{1}(:,1)-3400)/(3900-3400)*100;
            
        elseif contains(UT.data{ii,3},'LaserOxxiusMPA542')
            B_OD = UT.data{ii,2};% current setting (user input)
            ii_inC = find(contains(T_cal.laserType,'Type_MPA') );% in Bera output is always set via MPA with fixed current
            temp_calib=T_cal.calibArray{ii_inC};
            idx_val_range=temp_calib(:,1)==B_OD;
            temp_calib=temp_calib(idx_val_range,2:end); 
            % find 0 value and discard to improve fit
            is_zero=find(temp_calib(1,:)==0);
            temp_calib(is_zero,:)=[];
            %save or later reference
            C.calib = {temp_calib};
        end

        coeffs = polyfit(C.calib{1}(:,1),C.calib{1}(:,end), 5);
        %------------- OPTIONAL plot fit for visualization -----------------
        % figure()
        % hold on
        % x_vals=[0:1:100];
        % plot(x_vals,polyval(coeffs,x_vals))
        % plot(C.calib{1}(:,1),C.calib{1}(:,end))

        %create reference values for each individual trace within a berabr
        for jj = 1 : B.nTraces
            Ical(jj)= polyval(coeffs, B.Stim(jj).intensity);
        end
        C.Ical = Ical;
        B = setC(B,C);
        enablecache off
        saveBerabr(B);
        enablecache on

    elseif strcmp( B.Stim(1).modality,'Acoustic')
        C.calib=[];
        C.Ical=B.Stim.intensity;
        B = setC(B,C);
        enablecache off
        saveBerabr(B);
        enablecache on
    end
end

end