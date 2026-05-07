function setCalibrationICfromLaserControl(ee, calibDir,skip_IDs)
%% creates the ICME.C calibrated Stimulus Info based on the ICuserInput
% input:
% ee (anex),
% calibDir (str) path to Dir that contains the calibration files from the powermeter
% skip_IDs (list of str with zeros and ID eg ['0001','0010']) optional input to save time
%    if the function has previously been called for this ee

if ~exist('calibDir')
    calibDir = ee.RawDataDir(find([ee.RawDataDir.type]=='IC')).dir;
end


if exist('calibDir') & isempty(calibDir)
    calibDir = ee.RawDataDir(find([ee.RawDataDir.type]=='IC')).dir;
end


% check if skip_IDs have been specified
if ~exist('skip_IDs')
    skip_IDs=[];
end

% import the user information about the applied filters
in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
load(in_dir_name);%loads UT

% find all names of calib files and save info in a table
files=dir(fullfile(gen_dir_name(calibDir), '*Power_Calibration*.txt'));
TableVarName={'date','laserType','ComPort', 'calibArray', 'filter', 'implantID'};
T_cal=table('size', [1,6], 'VariableTypes', { 'string','string','string', 'cell', 'double','string'});
T_cal.Properties.VariableNames=TableVarName;
for i = 1:length(files)
    filename = files(i).name; % convert to lower case for comparison
    % extract file info from header
    file_desc=split(filename,'_');
    T_cal.date(i)=file_desc{1};
    T_cal.filter(i)=str2double(erase(file_desc{end},'.txt'));
    T_cal.laserType(i)=file_desc{3};
    T_cal.ComPort(i)=file_desc{cellfun(@(x) contains(x,'COM') , file_desc)};
    try
        if strcmp(file_desc{7},'ID')
            T_cal.implantID(i) = strcat(file_desc{8},'_',file_desc{9});
        end
    end

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
    %         myTable.Properties.VariableNames = {'Power_Percent', 'Current_mA', 'Power_mW'};

    % save in calib array
    T_cal.calibArray{i}= table2array(myTable);

end

%% check if 2 fiber calibration files exist and load in second table if that is the case
files=dir(fullfile(gen_dir_name(calibDir),'2FCalibs', '*Power_Calibration*.txt'));
TableVarName={'date','laserType','ComPort', 'calibArray', 'filter'};
T_cal_2F=table('size', [1,5], 'VariableTypes', { 'string','string','string', 'cell', 'double'});
T_cal_2F.Properties.VariableNames=TableVarName;
for i = 1:length(files)
    filename = files(i).name; % convert to lower case for comparison
    % extract file info from header
    file_desc=split(filename,'_');
    T_cal_2F.date(i)=file_desc{1};
    T_cal_2F.filter(i)=str2double(erase(file_desc{end},'.txt'));
    T_cal_2F.laserType(i)=file_desc{3};
    T_cal_2F.ComPort(i)=file_desc{cellfun(@(x) contains(x,'COM') , file_desc)};

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
    %         myTable.Properties.VariableNames = {'Power_Percent', 'Current_mA', 'Power_mW'};

    % save in calib array
    T_cal_2F.calibArray{i}= table2array(myTable);

end


% % check if EXPCONTROL aleady read in calibration files (should usually be the case)
% if CalibrationDone==1
%     % we still need to open the calibration files to check if we presented
%     % impossible stimuli (tend to go to high with Laser2 and then it wants
%     % to give 60 mW but actually gives 0, because 100% output is 55 mW
% 
% 
% 
%     % assign correct callibration per ICME, using the user OD input
%     for ii = 1 : numel(UT.data(:,1))
%         % check if experiment has been marked -1 by UserInput
%         if UT.data{ii,find(contains(UT.fieldNames,'Use'))}==-1
%             continue
%         end
%         fprintf('filling calibrated values for % s \n',UT.data{ii,find(contains(UT.fieldNames,'SeriesID'))})
%         %check if this ICME has already been processed
%         ICME_desc=split(UT.data{ii,find(contains(UT.fieldNames,'SeriesID'))},'_');
%         if ~isempty(skip_IDs)
%             if any(all(skip_IDs==ICME_desc{2},2))
%                 continue
%             end
%         end
%         IC = loadIcme(icme(ee,UT.data{ii,find(contains(UT.fieldNames,'SeriesID'))}));
%         % since the calibration was already considered during the
%         % Experiment, the Stimulus Intensities are the same as the
%         % calibration intensities
%         IC.C(1).stimlistCal=IC.Stim.stimlist;
%         bad_ix=[];
% 
%         % for Laser stimulations
%         if contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'OBIS_LS594_PulseTrain')
%             if any(contains(UT.fieldNames,'LaserCOMPort'))
%                 ComPort=UT.data{ii,find(contains(UT.fieldNames,'LaserCOMPort'))};
%             else
%                 % duck tape fix for old data where there is no COmport
%                 % only Serial number
%                 % in the UT table
%                 SerNr=UT.data{ii,find(contains(UT.fieldNames,'Laser') &contains(UT.fieldNames,'ID'))};
%                 if SerNr=='151367'
%                     ComPort='COM10';
%                 elseif SerNr=='191143'
%                     ComPort='COM3';
%                 end
%             end
% 
%             % save the calibration array with the ICME object
%             ix=find(T_cal.ComPort==ComPort & T_cal.filter==str2num(UT.data{ii,find(contains(UT.fieldNames,'Filter'))})& T_cal.laserType=='Obis');
%             if length(ix)>1 % if multiple calib file sexist in folder take first one
%                 ix=ix(1);
%                 disp('multiple calibration files found for this recording')
%             end
%             IC.C.CalibArray=T_cal.calibArray{ix};
%             IC.C.minIntensity=min(T_cal.calibArray{ix}(:,end));
%             IC.C.maxIntensity=max(T_cal.calibArray{ix}(:,end));
%             % check if any impossible stimuli have been attempted (more
%             % than 100 or less then 0 % laser output
%             bad_ix=find(IC.C.stimlistCal(:,1)>IC.C.maxIntensity | (IC.C.stimlistCal(:,1)<IC.C.minIntensity & IC.C.stimlistCal(:,1)~=0));
%         elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'OBIS_1Fiber_Masking')
%             ix=find(T_cal.ComPort==ComPort & T_cal.filter==str2num(UT.data{ii,find(contains(UT.fieldNames,'Filter'))})&T_cal.laserType=='Obis-NI-Mixed');
%             if length(ix)>1
%                 ix=ix(1);
%                 disp('multiple calibration files found for this recording')
%             end
%             IC.C.CalibArray=T_cal.calibArray{ix};
%             IC.C.minIntensity=min(T_cal.calibArray{ix}(:,end));
%             IC.C.maxIntensity=max(T_cal.calibArray{ix}(:,end));
%             % check if any impossible stimuli have been attempted (more
%             % than 10 V or less then 0 V NI output
%             bad_ix=find(IC.C.stimlistCal(:,2)>IC.C.maxIntensity | ... % pusle1 amp > max
%                 (IC.C.stimlistCal(:,2)<IC.C.minIntensity & IC.C.stimlistCal(:,2)~=0) |... % pusle1 amp <min
%                 IC.C.stimlistCal(:,4)>IC.C.maxIntensity | ...% pusle2 amp > max
%                 (IC.C.stimlistCal(:,4)<IC.C.minIntensity & IC.C.stimlistCal(:,4)~=0)); %pusle2 amp < min
%         elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'DarkRedLaser')
% 
%             ix=find( contains(T_cal.laserType,'L660'));
%             if length(ix)>1 % if multiple calib file sexist in folder take first one
%                 ix=ix(1);
%                 disp('multiple calibration files found for this recording')
%             end
%             IC.C.CalibArray=T_cal.calibArray{ix};
%             IC.C.minIntensity=min(T_cal.calibArray{ix}(:,end));
%             IC.C.maxIntensity=max(T_cal.calibArray{ix}(:,end));
%             % check if any impossible stimuli have been attempted (more
%             % than 100 or less then 0 % laser output
%             bad_ix=find(IC.C.stimlistCal(:,1)>IC.C.maxIntensity | (IC.C.stimlistCal(:,1)<IC.C.minIntensity & IC.C.stimlistCal(:,1)~=0));
% 
%         elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'MX') % nothing read in
% 
%         elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'TwoLaser_OBIS')
%             %Laser1
%             ComPort=UT.data{ii,find(contains(UT.fieldNames,'LaserCOMPort'))};
%             ix=find(T_cal_2F.ComPort==ComPort & T_cal_2F.filter==str2num(UT.data{ii,find(contains(UT.fieldNames,'Filter'))})& T_cal_2F.laserType=='Obis');
%             if length(ix)>1 % if multiple calib file sexist in folder take first one
%                 ix=ix(1);
%                 disp('multiple calibration files found for this recording')
%             end
%             IC.C.CalibArray=T_cal_2F.calibArray{ix};
%             IC.C.minIntensity=min(T_cal_2F.calibArray{ix}(:,end));
%             IC.C.maxIntensity=max(T_cal_2F.calibArray{ix}(:,end));
%             %Laser2
%             ComPort2=UT.data{ii,find(contains(UT.fieldNames,'Laser2 ComPort'))};
%             ix=find(T_cal_2F.ComPort==ComPort2 & T_cal_2F.filter==str2num(UT.data{ii,find(contains(UT.fieldNames,'Laser2 filter'))})& T_cal_2F.laserType=='Obis');
%             if length(ix)>1 % if multiple calib file sexist in folder take first one
%                 ix=ix(1);
%                 disp('multiple calibration files found for this recording')
%             end
%             IC.C.CalibArray_L2=T_cal_2F.calibArray{ix};
%             IC.C.minIntensity_L2=min(T_cal_2F.calibArray{ix}(:,end));
%             IC.C.maxIntensity_L2=max(T_cal_2F.calibArray{ix}(:,end));
%         else
%             disp('no calibration file found')
%         end
% 
%         IC.C.impossibleStimuli=bad_ix;
%         saveIcme(IC);
% 
%     end



% else % for  older IC recordings the calibration was not considered in ExpControl (Eg. all JG data)

    % go through all ICME objects and fill IC.C
    for ii = 1 : numel(UT.data(:,1))
        % check if experiment has been marked -1 by UserInput
        if UT.data{ii,find(contains(UT.fieldNames,'Use'))}==-1
            continue
        end
        fprintf('filling calibrated values for % s \n',UT.data{ii,find(contains(UT.fieldNames,'SeriesID'))})
        %check if this ICME has already been processed
        ICME_desc=split(UT.data{ii,find(contains(UT.fieldNames,'SeriesID'))},'_');
        if ~isempty(skip_IDs)
            if any(all(skip_IDs==ICME_desc{2},2))
                continue
            end
        end
        IC = loadIcme(icme(ee,UT.data{ii,find(contains(UT.fieldNames,'SeriesID'))}));

        % check which kind of ICME we have and correspondingly fill the
        % calibration Stimlist in IC.C.stimlistCal
        if contains(UT.data{ii,find(strcmp(UT.fieldNames,'ExpType'))},'OBIS')
            OD = str2num(UT.data{ii,find(strcmp(UT.fieldNames,'Filter'))});
            % find the right calibration file

            SerNr=UT.data{ii,find(contains(UT.fieldNames,'Laser'))};
            laser_type='Obis';
            if strcmp(SerNr,'151367')
                ComPort='COM10';
            elseif strcmp(SerNr,'191143')
                ComPort='COM3';
            end

            % save the calibration array with the ICME object
            ix=find(T_cal.ComPort==ComPort & T_cal.laserType==laser_type);
            if length(ix)>1 % if multiple calib files exist in folder newest
                ix=ix(1);
                disp('multiple calibration files found for this recording')
            
            elseif length(ix)==0
                error('no calibration file found for this recording')
            end

            Power_percent=T_cal.calibArray{ix}(:,1);
            Power_mW_adapted= T_cal.calibArray{ix}(:,end);


            %% make a fit to the data
            %find polynomial fit and store the coefficients
            degree=5;
            coeffs= polyfit( Power_percent,Power_mW_adapted, degree);
            used_intensities_percent=IC.Stim.stimlist(:,1);
            used_intensities_mW=polyval(coeffs,used_intensities_percent);
            stimlistCal=IC.Stim.stimlist;
            stimlistCal(:,1)=used_intensities_mW;


            %                 % plot fit
            %                 x_fit = linspace(0, 100, 100);
            %                 y_fit = polyval(coeffs, x_fit);
            %                 figure;  % open new figure window for each sheet
            %                 hold on; % keep the same axis for all plots
            %                 scatter( Power_percent,Power_mW_adapted);
            %                 plot(x_fit, y_fit, 'LineWidth', 2);
            %                 legend('Data', 'Fit');
            %                 ylabel('Power (mW) OD0');
            %                 xlabel('Percent Power (%)');
            %                 hold off;


            IC.C(1).stimlistCal=stimlistCal;
            IC.C(1).CalibArray=[Power_percent/1000,Power_mW_adapted];
            IC.C(1).minIntensity=min(Power_mW_adapted);
            IC.C(1).maxIntensity=max(Power_mW_adapted);

        elseif contains(UT.data{ii,find(strcmp(UT.fieldNames,'ExpType'))},'OXXIUS') & ~(contains(UT.data{ii,find(strcmp(UT.fieldNames,'ExpType'))},'OXXIUS_LAS488_PulseTrain'))
            OD = str2num(UT.data{ii,find(strcmp(UT.fieldNames,'Filter'))});
            % find the right calibration file

            ComPort=UT.data{ii,find(contains(UT.fieldNames,'Laser'))};
            laser_type='Oxxius';

            % save the calibration array with the ICME object
            ix=find(T_cal.ComPort==ComPort & T_cal.laserType==laser_type & T_cal.filter==OD);
            if length(ix)>1 % if multiple calib files exist in folder newest
                ix=ix(1);
                disp('multiple calibration files found for this recording')
            end

            Power_percent=T_cal.calibArray{ix}(:,1);
            Power_mW_adapted= T_cal.calibArray{ix}(:,end); %filter is already in filename


            %% make a fit to the data
            %find polynomial fit and store the coefficients
            degree=5;
            coeffs= polyfit( Power_percent,Power_mW_adapted, degree);
            used_intensities_percent=IC.Stim.stimlist(:,1);
            used_intensities_mW=polyval(coeffs,used_intensities_percent);
            stimlistCal=IC.Stim.stimlist;
            stimlistCal(:,1)=used_intensities_mW;

            IC.C(1).stimlistCal=stimlistCal;
            IC.C(1).CalibArray=[Power_percent/1000,Power_mW_adapted];
            IC.C(1).minIntensity=min(Power_mW_adapted);
            IC.C(1).maxIntensity=max(Power_mW_adapted);
            IC.C(1).impossibleStimuli=[];
            % check if any impossible stimuli have been attempted (more
            % than 100 or less then 0 % laser output
        elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'MX')
            % for acoustic stimuli no calibration necessary
            IC.C(1).stimlistCal=IC.Stim.stimlist;
            IC.C(1).impossibleStimuli=[];
        elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'SBcreeLED10x1')
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


            %load the correct calibration
            tmpCal=[];
            for kk = 1 : height(T_cal)
                if strcmp(T_cal.laserType(kk),"SB") & (T_cal.filter(kk)==resistorLevel) & strcmp(T_cal.implantID(kk),implantID)
                    tmpCal = T_cal(kk,:);
                end
            end
           if isempty(tmpCal)
               disp("not calibration found")
               continue
           end
            % save the calibration array with the ICME object
            IC.C(1).CalibArray =  tmpCal;
            % make the fits for all the channels and storethem in
            calibArray = tmpCal.calibArray{1};
            allChannels = unique(calibArray(:,1));
            for   ll = 1: numel(allChannels)
                emitterCal(ll).emitterID =allChannels(ll);
                emitterCal(ll).calibArray = calibArray(calibArray(:,1)==allChannels(ll),:);
                emitterCal(ll).calibArray(emitterCal(ll).calibArray(:,3)<0.001,3) = 0;%ommit the negative values, 0.001
                [itarget,~]=find([emitterCal(ll).calibArray(:,3)]==0);
                if numel(itarget)>1
                    emitterCal(ll).calibArray(itarget,:)=[];
                    emitterCal(ll).calibArray=[emitterCal(ll).emitterID,0,0;emitterCal(ll).calibArray];%
                end
                emitterCal(ll).degree=2;
                emitterCal(ll).coeffs= polyfit(emitterCal(ll).calibArray(:,2),emitterCal(ll).calibArray(:,3),    emitterCal(ll).degree);
            end
            IC.C(1).emitterCal = emitterCal;
            %stimlist
            stimlistCal = IC.Stim.stimlist;
           if size(stimlistCal,2) <= 8 %bad bad practice, as it hndles the probles fro the different channels
            %look into the header
            [indexIntensity] = strcmp(IC.Stim.stimheader,'Intensity%');
            [indexChannel] = strcmp(IC.Stim.stimheader,'channel');
            % create the stimlistCal
            if size(IC.Stim.stimheader,2)==size(IC.Stim.stimlist,2)
                for iCal = 1 : size(stimlistCal,1)

                    if stimlistCal(iCal,indexIntensity) == 0
                        stimlistCal(iCal,indexIntensity) = 0;
                    else
                        stimlistCal(iCal,indexIntensity) =polyval(IC.C.emitterCal(stimlistCal(iCal,indexChannel)).coeffs,  stimlistCal(iCal,indexIntensity));
                    end
                end
                IC.C(1).stimlistCal=stimlistCal;
               % IC.C(1).stimlistCal=stimlistCal;
                IC.C(1).impossibleStimuli=[];
            end
            enablecache off
            saveIcme(IC);
            enablecache on
           end
        end
%     end

end




