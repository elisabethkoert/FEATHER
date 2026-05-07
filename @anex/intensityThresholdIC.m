function [ExpIntThr] = intensityThresholdIC(ee,  dPrimeMode, ExpType, stim_criteria_array,t_start,t_stop,cochleaTurn)
% anex\intensity_thresholdIC finds the lowest intensity  with d'=1 (analysed with dPrimeMode) for a given ExpType
% by loopoing through all ICMEs of said type, for fiber sitmulation it
% focuses on RW stimulation
% input: 
%    ee (anex): animal experiment for which to get the threshold
%    dPrimeMode: (string) 'baseline' or 'increasingLvl'  mode to caclulate the d' values on
%        default: 'baseline'
%    ExpType: (string) describing the 1 ms pusle intensity protocols in the UT table
%        default: 'PulseTrain_Attenuation' (works for OBIS lasers)
%   stim_criteria_array (nx3 array floats) helper to identify wanted
%   stimuli [collum in stimlist, min value, max value], default for 0-60 mW
%   for lasers
%   t_start (float): stanrt time analysis window [ms]
%   t_stop (float): stop time analysis window [ms]
%   cochleaTurn (string): ap/mid/bas if only one turn should be taken
%       into account for optical stimulation. If empty (default) all turns are taken.
% output: (in struct ExpIntThr)
%   ExpType (string) : same as input
%   fixed _stim(double): value descibed in second array of stim_criteria
%       array (eg. frequency for MX_tones)
%   fixed_var_value_descriptor('string') descrpitor of fixed stimulus
%   thresholdIC (double) smalles intensity value for which any
%       recording had a d' value of 1 in the respective d' mode without
%       interpolation
%   thresholdIC_contour (double) smalles intensity value for which any 
%       recording had a d' value of 1 in the respective d' mode determined
%       via contourlines (omitting circles, and interpolating values)
%   IC_SeriesID (string): Name of the icme where the lowest threshold was
%       detected

if ~exist('dPrimeMode','var') 
    dPrimeMode='baseline';
end
if ~exist('ExpType','var')
   ExpType={'PulseTrain_Attenuation'};
end
% get stim_criteria_array
if ~exist('stim_criteria_array','var')
    stim_criteria_array=[1,0,60;3,1,1]; 
end
if ~exist('t_start','var')
    t_start=2; 
end
if ~exist('t_stop','var')
    t_stop=25; 
end
if ~exist('cochleaTurn','var')
    cochleaTurn=[]; 
end

ExpIntThr=[]; %return empty if no data exists yet

% try loading existing results
if status_cache==1
    try
        load_name = strcat(dPrimeMode,'ICthreshhold.mat');
        if contains(ExpType,'tone')
            load_name=strcat('acoustic_',load_name);
        else
            load_name=strcat('optic_',load_name);
        end
        load(fullfile(getProcessedDataDir(ee),load_name)),
%         disp('IC threshold results loaded.')
        return
    catch 
        disp('IC threshhold results need to be compiled');
    end
end

%load IC user input
try
    in_dir_name = fullfile( expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME',strcat("ICUserInput_", ee.ExpID, ".mat"));
    load(in_dir_name);%loads UT
catch
    % save empty if no IC recordings performed
        ExpIntThr.thresholdIC=NaN;
        ExpIntThr.IC_SeriesID=NaN;
        ExpIntThr.ExpType=ExpType;
       save_name = strcat(dPrimeMode,'ICthreshhold.mat');
    if contains(ExpType,'tone')
        save_name=strcat('acoustic_',save_name);
        ExpIntThr.unit='dB';
    else
        save_name=strcat('optic_',save_name);
        ExpIntThr.unit='mW';
    end
    save(fullfile(getProcessedDataDir(ee),save_name),'ExpIntThr'),
    return
end
L =listIcme(ee);
all_thresholds={};
for ii = 1: numel(L.IC_SeriesID)
    ix_in_UT= cellfun(@(x) strcmp( x ,string(L.IC_SeriesID(ii))),UT.data(:,find(contains(UT.fieldNames,'SeriesID'))));
    % skip if marked as bad, not correct Epxeriiment Type or marked as deaf
    if UT.data{ix_in_UT,find(contains(UT.fieldNames,'Use'))}== -1 ||...
            ~contains(UT.data{ix_in_UT,find(strcmp(UT.fieldNames,'ExpType'))},ExpType)||...
            contains(UT.data{ix_in_UT,find(strcmp(UT.fieldNames,'ExpType'))},'deaf')
            continue
    end
    % skip if not correct cochlea turn or fiber diameter
    if ~isempty(cochleaTurn)
        if ~contains(UT.data{ix_in_UT,find(strcmp(UT.fieldNames,'pos cochlea'))},cochleaTurn) ||...
                ~strcmp(num2str(UT.data{ix_in_UT,find(strcmp(UT.fieldNames,'d fiber [µm]'))}),'200')
            continue
        end
    end
    % skip if it is bipolar for eCI data
    if any(contains(UT.fieldNames,'eCIstimulationMode'))
        if contains(UT.data{ix_in_UT,find(strcmp(UT.fieldNames,'eCIstimulationMode'))},'bipolar')
            continue
        end
    end    
    IC = loadIcme(icme(ee,L.IC_SeriesID(ii))); % loads the ICME object
    fprintf('getting threshold for %s \n',IC.SeriesID)
    d_prime_results_all= calculateDprimeMultipleStimVars(IC,dPrimeMode,stim_criteria_array,t_start,t_stop); %ToDo check for baseline
    for fixed_var_ix=1:length(d_prime_results_all)
        d_prime_results=d_prime_results_all{fixed_var_ix};
        fixed_var_value=d_prime_results.fixed_var_value;

        d_prime_1_ix=find(d_prime_results.analyzed_d_prime_array==1);
        if strcmp(dPrimeMode,'increasingLvl')
            thresholds_by_channel=d_prime_results.thresholds_by_channel_Cum;
             cur_data =d_prime_results.all_Dprime_cumsum;
            used_stimuli=d_prime_results.changing_var_values(2:end);
        elseif strcmp(dPrimeMode,'baseline')
            thresholds_by_channel=d_prime_results.thresholds_by_channel_base;
             cur_data =d_prime_results.all_Dprime_array;
            used_stimuli=d_prime_results.changing_var_values;
        end
        if isempty(cur_data)
            continue
        end

        % check if the stimuli are ordered with increasing intensity, if
        % not resort everything
        if ~all(diff(used_stimuli) >= 0)
            [used_stimuli, resort_idx] = sort(used_stimuli);
            cur_data=cur_data(:,resort_idx);
        end

         % get contourlines and threhsolds
        [all_contourlines,all_thresholds_icme] =getContourLinesForXYdata(cur_data,...
            d_prime_results.analyzed_d_prime_array,used_stimuli,IC.SL.all_electrodes+1);
        

        thr_value=min(thresholds_by_channel(:,d_prime_1_ix));
        thr_value_contour=all_thresholds_icme(d_prime_1_ix,2);
        if ~isempty(all_thresholds)
            ix_fixed_var_valueulus=find([cellfun(@(x) x.fixed_var_value, all_thresholds)]==fixed_var_value);
            if ~isempty(ix_fixed_var_valueulus) % add value to already exsting stimulus type
                all_thresholds{ix_fixed_var_valueulus}.fixed_var_value=fixed_var_value;
                all_thresholds{ix_fixed_var_valueulus}.thr_value=[all_thresholds{ix_fixed_var_valueulus}.thr_value;thr_value];
                all_thresholds{ix_fixed_var_valueulus}.thr_value_contour=[all_thresholds{ix_fixed_var_valueulus}.thr_value_contour;thr_value_contour];
                all_thresholds{ix_fixed_var_valueulus}.IC_SeriesIDs={all_thresholds{ix_fixed_var_valueulus}.IC_SeriesIDs{:},IC.SeriesID};

            else % save new frequency/ pulse duration
                all_thresholds{end+1}.fixed_var_value=fixed_var_value;
                all_thresholds{end}.thr_value=thr_value;
                all_thresholds{end}.thr_value_contour=thr_value_contour;
                all_thresholds{end}.IC_SeriesIDs={IC.SeriesID};

            end
        else
            all_thresholds{1}.fixed_var_value=fixed_var_value;
            all_thresholds{1}.thr_value=thr_value;
            all_thresholds{1}.thr_value_contour=thr_value_contour;
            all_thresholds{1}.IC_SeriesIDs={IC.SeriesID};
        end

    end


end
    
    %% go through all fixed stimuli (eg. frequencies) and get the lowest threshold and corresponding icme
    for jj=1:length(all_thresholds)
           [value,ix]=min(all_thresholds{jj}.thr_value);
           
           [value_contour,ix_contour]=min(all_thresholds{jj}.thr_value_contour);
           if ix~=ix_contour %sanity check
               disp('not same ICME for thresholds wiht and without contour???')
           end

         ExpIntThr(jj).ExpType=ExpType;
         ExpIntThr(jj).fixed_var_value=all_thresholds{jj}.fixed_var_value;
         ExpIntThr(jj).fixed_var_value_descriptor=IC.Stim.stimheader{stim_criteria_array(2,1)};
         if ~isempty(value)
             ExpIntThr(jj).thresholdIC=value;
            ExpIntThr(jj).thresholdIC_contour=value_contour;
            ExpIntThr(jj).IC_SeriesID=all_thresholds{jj}.IC_SeriesIDs{ix};
            
        else
            ExpIntThr(jj).thresholdIC=NaN;
            ExpIntThr(jj).IC_SeriesID=NaN;
            ExpIntThr(jj).thresholdIC_contour=NaN;
        end
        if contains(ExpType,'tone')
            ExpIntThr(jj).unit='dB';
        else
            ExpIntThr(jj).unit='mW';
        end

    end
    
    
   
    save_name = strcat(dPrimeMode,'ICthreshhold.mat');
    if contains(ExpType,'tone')
        save_name=strcat('acoustic_',save_name);
    else
        save_name=strcat('optic_',save_name);
    end
    save(fullfile(getProcessedDataDir(ee),save_name),'ExpIntThr'),
%     disp('IC threshold results saved')
end
