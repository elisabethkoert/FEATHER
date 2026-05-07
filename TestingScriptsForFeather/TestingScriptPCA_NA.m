% This scirpt can be run to test the analysis after git merges
clear all; close all; clear global;
% toolbox filepath
tb_path =  horzcat('C:\Users\Administrator\Desktop\GitFolders\FEATHER\invivoephysfeather'); % DS WS
addpath(genpath(tb_path));

% ukon drive mapping
tmp_ukonmap = 'Z:\UKON100';
ukonmap(tmp_ukonmap);

% set UserID for this analysis to determine where processed data gets
% stored
userID('EK'); 

%% Get info for the animal
ExpID='gna192119';
rawDatadir=  ["archiv","systems","AllDataTypesForAnalysisTests","gna192119"];
experimenterID('test');

%% create new Anex 
enablecache off % make sure you load raw data
D(1).dir =rawDatadir;
D(1).type ="ABR";
ee = anex(ExpID, experimenterID, D);
ee = setAnimalSpecies(ee,'gerbil');
initProcessedExp(ee) % creates save folder
initKiwi(ee)
saveAnex(ee);%updates the ee

%% load existing anex
enablecache on
ee = anex(ExpID, 'test'); 
ee=loadAnex(ee);
%% Intialize IC analysis 
% add raw data dir
D_cur=ee.RawDataDir;
D_cur(end+1).dir=ee.RawDataDir(find([ee.RawDataDir.type]=='ABR')).dir;
D_cur(end).type = "IC" ;
ee = setRawDataDir(ee,D_cur);
saveAnex(ee);

% initialise ICME objects from raw data .m log files (fillst the icme.stim with stim info)
enablecache off
allIcme(ee) %
%% Do Spike extraction
enablecache on
L =listIcme(ee);
for ii = 1: numel(L.IC_SeriesID)
    % load existing icme object
    enablecache on
    IC=loadIcme(icme(ee,string(L.IC_SeriesID(ii))));
    disp(L.IC_SeriesID(ii))
    %% initializing the SL from raw data (needs Workstation or veryyy slow)
    % skip this part if RESORT file already exists in the processed data
    % dir
    enablecache off
    IC = loadSLfeather(IC); % Fills ICME.SL from raw data, creating a new RESORT file
    [meanSpikeRates, spikeRateAllReps]  = calculateSpikeRate(IC,0,50);
    saveIcme(IC);
end
%% Do  a PCA for different tones presented in that animal 
PSTH_binsize=1; 
kernel_width=10; % used for smoothing 
L =listIcme(ee); 
% Get the information for the Single Channel Experiments
create_overview(ee,5,105,{'Single_NB'}); % creates an oveview of all aocuistcal single channel experiments, this list is late used for sorting 
stim_list_all=loadStimOverview(ee,'Single_NB'); % loads the created overview
is_freq=[2048, 4096, 5793,  6889, 7512, 7845, 8192]; % chooses frequencies to compare
dPrime_comparator=2;% they are compared at this activation level
BW=0; % nandwidth that is used 
t_start=5; % time window used 
t_stop=110;
array_all=[];
is_array_reps=[];
for hh=1:length(is_freq)
    is_ix=unique(stim_list_all(find(stim_list_all(:,2)==BW & stim_list_all(:,1)==is_freq(hh) & ismember(stim_list_all(:,6),10:10:90)),7));% Find the correct experiment, it doesnt use the 0 dB experiment as this would be just noise 
    if isempty(is_ix)
        is_freq(hh)=NaN;
        continue
    end
    is_ix=is_ix(end); % Loading the last experiment that was recorded (maybe change later)
    IC=loadIcme(icme(ee,string(L.IC_SeriesID(is_ix))));
    is_BW=BW;
    thresh_dP=getAcousticThresh(ee,is_freq(hh),is_BW,'increasingLvl',dPrime_comparator); % gets the dPrime Threshold to later load the right stimulus
    stim_criteria_array=[6, thresh_dP, thresh_dP;1,is_freq(hh),is_freq(hh);2,is_BW,is_BW];
    is_array_Tone{hh}=getPSTHarrayAllMU(IC,stim_criteria_array,t_start,t_stop,PSTH_binsize); % this creates the PSTH 
    is_array_Tone_smooth{hh}=get_smooth(is_array_Tone{hh},PSTH_binsize,kernel_width); % smoothes the PSTH, this array is later used for PCA
    is_array_Tone{hh}=is_array_Tone_smooth{hh};
    is_array_reps=cat(3,is_array_reps,is_array_Tone{hh}); % it concatenates all IC experiments but leavs the division by reps 
    array_all=cat(2,array_all,squeeze(mean(is_array_Tone{hh},2))); % concatenates the experiments after averaging over all reps 
    array_Tone{hh}=squeeze(mean(is_array_Tone{hh},2));% averaginges over the 30 reps for all tones  
end
is_freq=is_freq(~isnan(is_freq)); % frequencies that were not found are deleted out here 
% For defining manifold on whole dataset
% Defining manifold
[coeff, score, latent, signal_latent]=getManifold(array_all, is_array_reps,1);% applies PCA on the extracted stimuli and checks the signal variance that is explained by each PC 
clear('hh');
[~,no_PC]=max(signal_latent); % Finds the peak of the signal variance explained 

% Apply on PCs
array_PCA=applyonPC(array_Tone, no_PC,coeff,[1,2], is_freq);% Applies all tones individually on the prinncipal componetns explaining signal variance and plots them in the space defined by the first two PC
% calculate distance
is_dist=getDist(array_PCA, 1,'mahalanobis'); % calculates a distance as a metric of response dissimilarity 