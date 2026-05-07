function [meanSpikeRates, spikeRateAllReps] = calculateSpikeRate(obj, t_start,t_stop )
% icme\calculateSpikeRate calculates the spikeRate [Hz] in the given time window for all stimuli
% input:
%   obj (icme)
%   t_start double analysis time window start
%   t_stop double analysis time window stop
% output
%   meanSpikeRates 32xn_stimuli array with mean spike rates caclulated in the
%       time window for each presented stimulus
%   SpikeRateAllReps 32xn_stimulix30 all spike rates calculated in the
%       time window for each presented stimulus for each repetition



    if nargin == 1 & ~exist('t_start') & ~exist('t_stop')
        t_start = 0;% time before and after a trigger that is supposed to be investigated
        t_stop = 50; % default 50 ms after trigger
    end
    
    %  if enable cache is on try to load any existing data' and if successfull
    %  leave the function
    if strcmpi(enablecache,'on')
            save_name = strcat("SR_",obj.ExpID,"_",obj.SeriesID,"_",num2str(t_start),"_",num2str(t_stop),".mat");
            if isfile(fullfile(expProcDataDir,'ICME','SR',save_name))
                load(fullfile(expProcDataDir,'ICME','SR',save_name));
                return
            end
    end
     
    % if loading did not work or enablecache is off calculate  new spikerates
    % from spikelist 

    % check if the spik_lists_all structure exists that separates
    % everything by electrode
    if isfield(obj.SL,'spik_list_all')
        all_electrode_names=obj.SL.all_electrode_names;
        stimIDs=1:1:length(obj.Stim.stimlist);
        meanSpikeRates = zeros(length(all_electrode_names), length(stimIDs)); %array that saves mean spike rate
        spikeRateAllReps = zeros(length(all_electrode_names), length(stimIDs),min(obj.Stim.n_rep));
        for elec_ix = 1:length(all_electrode_names)
            elec_name=strcat('elec',num2str(elec_ix-1));
            Spik_list=obj.SL.spik_list_all.(elec_name);
           % loop through sitmuli
                for stim_ix = 1:length(stimIDs)
                        curStim = stimIDs(stim_ix);
                    for curRep=1:obj.Stim.n_rep
                        spikes2curStim = Spik_list((Spik_list(:, 1) == curStim & Spik_list(:,2) == curRep), 6);
                        spikes_within_responsewindow = sum(spikes2curStim > t_start/1000 & spikes2curStim < t_stop/1000);
                        spikerate2curStim = (spikes_within_responsewindow./(abs(t_stop-t_start)/1000)); % to get spike/sec -> Hz
                        spikeRateAllReps(elec_ix, stim_ix,curRep) = spikerate2curStim;
                    end
                    meanSpikeRates(elec_ix, stim_ix) =mean(spikeRateAllReps(elec_ix,stim_ix,:));
                end
        end
    else
            disp('no type of Spik_list_all found to calculate spike rate')
            return
    end

    %save the output
    save_name = strcat("SR_",obj.ExpID,"_",obj.SeriesID,"_",num2str(t_start),"_",num2str(t_stop),".mat");
    %test if there is alreadz a directory for SR, otherwise make it
    if  ~isfolder(fullfile(expProcDataDir,'ICME','SR'))
        mkdir(fullfile(expProcDataDir,'ICME','SR'));
        save(fullfile(expProcDataDir,'ICME','SR',save_name),'meanSpikeRates','spikeRateAllReps');
    elseif  isfolder(fullfile(expProcDataDir,'ICME','SR')) == 1
        save(fullfile(expProcDataDir,'ICME','SR',save_name),'meanSpikeRates','spikeRateAllReps');
    end

    
end

