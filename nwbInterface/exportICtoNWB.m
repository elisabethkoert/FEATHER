function nwb = exportICtoNWB(nwb, ee, sessionStart, icElecTableOffset, targetSeriesIDs)
% exportICtoNWB  Exports IC data to the NWB processing module and Units table.

    % Get list of available ICs
    LIC = listIcme(ee);
    allSeriesIDs = string(LIC.IC_SeriesID);
    allSeriesIDs = allSeriesIDs(~ismissing(allSeriesIDs));
    
    % Filter based on user input
    if ~isempty(targetSeriesIDs)
        mask = ismember(allSeriesIDs, targetSeriesIDs);
        allSeriesIDs = allSeriesIDs(mask);
    end
    
    nIC = numel(allSeriesIDs);
    if nIC == 0
        fprintf('  No IC recordings selected for export.\n');
        return;
    end
    
    %% PROCESSING MODULE FOR IC METADATA
    %  Holds one stimlist DynamicTable per recording (describing each
    %  stimulus condition, from IC.Stim.stimlist/stimheader) and one
    %  shared analysis-parameters DynamicTable (one row per recording, for
    %  provenance: threshold/filter settings, MUEdate, GitHash...).

    icModule = types.core.ProcessingModule(...
        'description', ['Processed IC data: per-recording stimulus condition tables ' ...
        'and MUA-extraction analysis parameters.']);

    % Accumulators for Analysis Parameters Table
    ap_recordingID   = {};
    ap_expType       = {};
    ap_threshold      = [];
    ap_preTime        = [];
    ap_postTime       = [];
    ap_refTime        = [];
    ap_lowFilt        = [];
    ap_highFilt       = [];
    ap_filtOrd        = [];
    ap_preStimRecTime = [];
    ap_postStimRecTime= [];
    ap_artefactRemoval= [];
    ap_MUEdate        = {};
    ap_GitHash        = {};
    ap_GitBranch      = {};
    ap_waveThreshLow  = []; 

    % Accumulators for Units Table
    % UNITS TABLE - one shared table for the whole session
    %  one row per (recording x electrode x stimulus condition). Each row's
    %  spike_times is ragged across repetitions and expressed in seconds
    %  relative to session_start_time (standard NWB semantics). Per-spike
    %  repetition number and time-relative-to-trigger are preserved as
    %  additional ragged columns aligned to spike_times, so the original
    %  per-trial structure survives without needing FEATHER-specific
    %  tooling to reconstruct it.
    % --- row-level accumulators ---
    u_electrodeRow  = [];   % 0-based row index into combinedElecTable
    u_recordingID   = {};   % cellstr, one per row
    u_stimID        = [];   % 1-based row into that recording's stimlist table

    % --- ragged-column accumulators (cell per row; flattened at the end) ---
    u_spikeTimes_ss   = {}; % session-relative seconds
    u_spikeRelTrigger = {}; % seconds after trigger (copied straight from spikelist col 6)
    u_spikeRep        = {}; % repetition number (spikelist col 2)


    for iIC = 1:nIC
        SeriesID = allSeriesIDs(iIC);
        IC = loadIcme(icme(ee, SeriesID));
        safeName = matlab.lang.makeValidName(SeriesID);

        if ~isfield(IC.SL,'spik_list_all') || ~isfield(IC.SL,'all_electrode_names')
            warning('%s: no spikelist found, skipping.', SeriesID);
            continue
        end

        % Trigger timing
        if ~isfield(IC.SL,'Trigger')
            warning('%s: SL.Trigger missing - re-parsing from raw .nev.', SeriesID);
            IC = addTriggerTimeInfo(IC);
            enablecache off % make sure it is actually saved
            saveIcme(IC); 
            enablecache on
        end
        Trigger = IC.SL.Trigger;

        %% --- build the per-recording trigger-time lookup table ---
        % trigTimeLUT(stim_id, rep) = absolute NLX time [us] of that trial's trigger
        nStim = size(IC.Stim.stimlist,1);
        maxRep = max(Trigger.stim_list(:,2));
        trigTimeLUT = nan(nStim, maxRep);
        lutIdx = sub2ind([nStim, maxRep], Trigger.stim_list(:,1), Trigger.stim_list(:,2));
        trigTimeLUT(lutIdx) = Trigger.TrigBeginTime;
        % naive (unzoned) datetime - see timezone caveat in comments above
        % sessionStart's definition; both must stay unzoned to subtract directly
        trigDatetimeLUT = datetime(trigTimeLUT/1e6, 'ConvertFrom', 'posixtime');

        % --- sanity check: this recording should start AFTER session_start_time ---
        firstTrigOffset_s = seconds(min(trigDatetimeLUT(:), [], 'omitnan') - sessionStart);
        if firstTrigOffset_s < 0 || firstTrigOffset_s > 14*3600
            warning(['%s: computed offset from session_start_time (%.1f min) looks implausible - ' ...
                'check that ABR and IC recordings used a consistent PC clock/timezone.'], SeriesID, firstTrigOffset_s/60);
        end

        % Per-recording stimlist DynamicTable (from IC.Stim.stimlist/stimheader)
        stimHeaderNames = matlab.lang.makeValidName(strrep(IC.Stim.stimheader, ' ', '_'));

        %  Fix attenuation naming if necessary
        % some ExpControl laser stimheaders list 
        % 'Attenuation' twice - once for the calibrated intensity in mW, once for
        % the raw % attenuation value sent to the laser. so we
        % rename them explicitly here for clarity in the exported NWB table.
        attenuationIdx = find(strcmp(stimHeaderNames, 'Attenuation'));
        if numel(attenuationIdx) == 2
            stimHeaderNames{attenuationIdx(1)} = 'intensity_mW';
            stimHeaderNames{attenuationIdx(2)} = 'intensity_percent';
        end
        nCond = size(IC.Stim.stimlist,1);

        icStimTable = types.hdmf_common.DynamicTable(...
            'description', sprintf('Stimulus conditions for IC recording %s (exp_type: %s)', SeriesID, IC.Stim.exp_type), ...
            'colnames', [stimHeaderNames, {'stim_duration_s'}]);
        
        % if we have a calibrated stimlist we always want to only save that
        % one, otherwise we go for the uncalibrated one
        if isfield(IC.C,'stimlistCal')
           for iCol = 1:numel(stimHeaderNames)
                icStimTable.vectordata.set(stimHeaderNames{iCol}, types.hdmf_common.VectorData(...
                    'data', IC.C.stimlistCal(:,iCol), ...
                    'description', sprintf('Stimulus parameter "%s"', IC.Stim.stimheader{iCol})));
           end
        else
            for iCol = 1:numel(stimHeaderNames)
                icStimTable.vectordata.set(stimHeaderNames{iCol}, types.hdmf_common.VectorData(...
                    'data', IC.Stim.stimlist(:,iCol), ...
                    'description', sprintf('Stimulus parameter "%s"', IC.Stim.stimheader{iCol})));
            end
        end
        
        if isfield(IC.Stim,'dura') && numel(IC.Stim.dura) == nCond
            duraCol = double(IC.Stim.dura(:));
        else
            duraCol = nan(nCond,1);
        end
        icStimTable.vectordata.set('stim_duration_s', types.hdmf_common.VectorData(...
            'data', duraCol, 'description', 'Full stimulus duration [s]'));
        icStimTable.id = types.hdmf_common.ElementIdentifiers('data', int64(0:nCond-1)');
        
        icModule.dynamictable.set(sprintf('%s_stimlist', safeName), icStimTable);

        % --- Analysis Parameters Row ---
        ap = IC.SL.analysis_parameters;
        ap_recordingID{end+1,1}    = char(SeriesID);%#ok<AGROW>
        ap_expType{end+1,1}        = char(IC.Stim.exp_type);%#ok<AGROW>
        ap_threshold(end+1,1)      = ap.threshold;%#ok<AGROW>
        ap_preTime(end+1,1)        = ap.pre_time;%#ok<AGROW>
        ap_postTime(end+1,1)       = ap.post_time;%#ok<AGROW>
        ap_refTime(end+1,1)        = ap.ref_time;%#ok<AGROW>
        ap_lowFilt(end+1,1)        = ap.low_filt;%#ok<AGROW>
        ap_highFilt(end+1,1)       = ap.high_filt;%#ok<AGROW>
        ap_filtOrd(end+1,1)        = ap.filt_ord;%#ok<AGROW>
        ap_preStimRecTime(end+1,1) = ap.prestimrectime;%#ok<AGROW>
        ap_postStimRecTime(end+1,1)= ap.poststimrectime;%#ok<AGROW>
        ap_artefactRemoval(end+1,1)= double(ap.use_artefact_removal);%#ok<AGROW>
        ap_MUEdate{end+1,1}        = char(string(ap.MUEdate));%#ok<AGROW>
        ap_GitHash{end+1,1}        = char(ap.GitHash);%#ok<AGROW>
        ap_GitBranch{end+1,1}      = char(ap.GitBranch);%#ok<AGROW>
        ap_waveThreshLow(end+1,:)  = ap.waveform_threshold_low(:)';%#ok<AGROW>

        % --- Units Table Accumulation ---
        elecNames = IC.SL.all_electrode_names;
        for iE = 1:numel(elecNames)
            elecNum = str2double(regexp(elecNames{iE}, '\d+', 'match', 'once')); 
            spk = IC.SL.spik_list_all.(elecNames{iE});

            for stimID = 1:nCond
                if isempty(spk)
                    rowSpk = zeros(0,6);
                else
                    rowSpk = spk(spk(:,1) == stimID, :);
                end

                relTime_s = rowSpk(:,6);      
                repNum    = rowSpk(:,2);      

                if isempty(rowSpk)
                    sessionRelTime_s = zeros(0,1);
                else
                    trigDT = trigDatetimeLUT(sub2ind(size(trigTimeLUT), rowSpk(:,1), rowSpk(:,2)));
                    trigDT = trigDT(:);   
                    spikeAbsDT = trigDT + seconds(relTime_s);
                    sessionRelTime_s = seconds(spikeAbsDT - sessionStart);
                end

                u_electrodeRow(end+1,1) = icElecTableOffset + elecNum; %#ok<AGROW>
                u_recordingID{end+1,1}  = char(SeriesID); %#ok<AGROW>
                u_stimID(end+1,1)       = stimID; %#ok<AGROW>
                u_spikeTimes_ss{end+1,1}   = sessionRelTime_s(:); %#ok<AGROW>
                u_spikeRelTrigger{end+1,1} = relTime_s(:); %#ok<AGROW>
                u_spikeRep{end+1,1}        = repNum(:); %#ok<AGROW>
            end
        end
    end % end loop over IC recordings

    % --- Attach Analysis Parameters Table ---
    nRec = numel(ap_recordingID);
    icAnalysisParamsTable = types.hdmf_common.DynamicTable(...
        'description', 'Per-recording MUA spike-extraction analysis parameters.', ...
        'colnames', {'recording_id','exp_type','threshold','pre_time','post_time','ref_time', ...
                     'low_filt','high_filt','filt_ord','prestimrectime','poststimrectime', ...
                     'use_artefact_removal','waveform_threshold_low','MUEdate','GitHash','GitBranch'});
    
    % (Helper function to add columns would be nice, but doing inline for brevity)
    icAnalysisParamsTable.vectordata.set('recording_id', types.hdmf_common.VectorData('data', ap_recordingID, 'description','IC recording SeriesID'));
    icAnalysisParamsTable.vectordata.set('exp_type', types.hdmf_common.VectorData('data', ap_expType, 'description', 'ExpControl experiment-type'));
    icAnalysisParamsTable.vectordata.set('threshold', types.hdmf_common.VectorData('data', ap_threshold, 'description','Spike detection threshold [MAD units]'));
    icAnalysisParamsTable.vectordata.set('pre_time', types.hdmf_common.VectorData('data', ap_preTime, 'description','Waveform window before spike peak [ms]'));
    icAnalysisParamsTable.vectordata.set('post_time', types.hdmf_common.VectorData('data', ap_postTime, 'description','Waveform window after spike peak [ms]'));
    icAnalysisParamsTable.vectordata.set('ref_time', types.hdmf_common.VectorData('data', ap_refTime, 'description','Refractory period [ms]'));
    icAnalysisParamsTable.vectordata.set('low_filt', types.hdmf_common.VectorData('data', ap_lowFilt, 'description','Bandpass filter low cutoff [Hz]'));
    icAnalysisParamsTable.vectordata.set('high_filt', types.hdmf_common.VectorData('data', ap_highFilt, 'description','Bandpass filter high cutoff [Hz]'));
    icAnalysisParamsTable.vectordata.set('filt_ord', types.hdmf_common.VectorData('data', ap_filtOrd, 'description','Bandpass filter order'));
    icAnalysisParamsTable.vectordata.set('prestimrectime', types.hdmf_common.VectorData('data', ap_preStimRecTime, 'description','Time before trigger included in spike extraction window [ms]'));
    icAnalysisParamsTable.vectordata.set('poststimrectime', types.hdmf_common.VectorData('data', ap_postStimRecTime, 'description','Time after trigger included in spike extraction window [ms]'));
    icAnalysisParamsTable.vectordata.set('use_artefact_removal', types.hdmf_common.VectorData('data', ap_artefactRemoval, 'description','1 if global-mean artefact removal was applied'));
    icAnalysisParamsTable.vectordata.set('waveform_threshold_low', types.hdmf_common.VectorData('data', ap_waveThreshLow, 'description','Per-electrode absolute voltage threshold [V]'));
    icAnalysisParamsTable.vectordata.set('MUEdate', types.hdmf_common.VectorData('data', ap_MUEdate, 'description','Date/time MUA extraction was run'));
    icAnalysisParamsTable.vectordata.set('GitHash', types.hdmf_common.VectorData('data', ap_GitHash, 'description','FEATHER git commit hash'));
    icAnalysisParamsTable.vectordata.set('GitBranch', types.hdmf_common.VectorData('data', ap_GitBranch, 'description','FEATHER git branch'));
    icAnalysisParamsTable.id = types.hdmf_common.ElementIdentifiers('data', int64(0:nRec-1)');
    
    icModule.dynamictable.set('analysis_parameters', icAnalysisParamsTable);
    nwb.processing.set('ic_metadata', icModule);

    % --- Build and Attach Units Table ---
    nRows = numel(u_recordingID);
    countPerRow = cellfun(@numel, u_spikeTimes_ss);
    cumIdx = int64(cumsum(countPerRow));

    flatSpikeTimes   = cell2mat(u_spikeTimes_ss);
    flatRelTrigger   = cell2mat(u_spikeRelTrigger);
    flatRep          = cell2mat(u_spikeRep);

    nwb.units = types.core.Units(...
    'description', sprintf(['IC multi-unit activity (MUA), one row per (recording x electrode x ' ...
    'stimulus condition). spike_times are in seconds relative to session_start_time (standard NWB ' ...
    'convention). spike_time_rel_trigger [s] and spike_rep give the original per-trial time-after-' ...
    'trigger and repetition number for each spike. stim_id (1-based) indexes into the matching ' ...
    '<recording>_stimlist table in processing/ic_metadata describing that stimulus condition.']), ...
    'colnames', {'spike_times','electrodes','recording_id','stim_id','spike_time_rel_trigger','spike_rep'});

    % --- required typed column: spike_times (ragged) ---
    nwb.units.spike_times = types.hdmf_common.VectorData(...
        'data', flatSpikeTimes, ...
        'description', 'Spike times in seconds, relative to session_start_time');
    nwb.units.spike_times_index = types.hdmf_common.VectorIndex(...
        'data', cumIdx, ...
        'target', types.untyped.ObjectView(nwb.units.spike_times), ...
        'description', 'Index into spike_times for each row');

    % --- electrodes: one (non-ragged) electrode row-reference per unit row ---
    nwb.units.electrodes = types.hdmf_common.DynamicTableRegion(...
        'table', types.untyped.ObjectView(nwb.general_extracellular_ephys_electrodes), ...
        'description', 'Electrode (channel) this MUA row was recorded from', ...
        'data', int64(u_electrodeRow));


    % --- custom ragged columns: spike_time_rel_trigger, spike_rep ---
    vd_rel = types.hdmf_common.VectorData('data', flatRelTrigger, ...
        'description', 'Spike time in seconds relative to the stimulus trigger of that spike''s trial');
    vi_rel = types.hdmf_common.VectorIndex('data', cumIdx, ...
        'target', types.untyped.ObjectView(vd_rel), ...
        'description', 'Index into spike_time_rel_trigger for each row');
    nwb.units.vectordata.set('spike_time_rel_trigger', vd_rel);
    nwb.units.vectordata.set('spike_time_rel_trigger_index', vi_rel);   
    
    vd_rep = types.hdmf_common.VectorData('data', flatRep, ...
        'description', 'Repetition number of the stimulus condition for each spike');
    vi_rep = types.hdmf_common.VectorIndex('data', cumIdx, ...
        'target', types.untyped.ObjectView(vd_rep), ...
        'description', 'Index into spike_rep for each row');
    nwb.units.vectordata.set('spike_rep', vd_rep);
    nwb.units.vectordata.set('spike_rep_index', vi_rep);  

    % --- custom scalar (non-ragged) columns: recording_id, stim_id ---
    nwb.units.vectordata.set('recording_id', types.hdmf_common.VectorData(...
        'data', u_recordingID, ...
        'description', 'IC recording SeriesID (icme.SeriesID) this row belongs to'));
    nwb.units.vectordata.set('stim_id', types.hdmf_common.VectorData(...
        'data', int64(u_stimID), ...
        'description', ['1-based row index into that recording''s stimlist table ' ...
        '(processing/ic_metadata/<recording>_stimlist) describing the stimulus condition for this row']));
    % --- id set LAST, now that every column is populated and heights agree ---
    nwb.units.id = types.hdmf_common.ElementIdentifiers('data', int64(0:nRows-1)');

end