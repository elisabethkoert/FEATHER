function [nwb, wave_annotations] = exportABRtoNWB(nwb, ee, sessionStart, abrElecRegion, targetSeriesIDs)
% exportABRtoNWB  Exports ABR data to the NWB processing module.
%   wave_annotations is a struct containing fields: recordingID, traceIndex, amplitude, latency, sampleIndex

    % Get list of available ABRs
    Bs = listBerabr(ee);
    allSeriesIDs = string(Bs.ABR_SeriesID);
    
    % Filter based on user input
    if ~isempty(targetSeriesIDs)
        mask = ismember(allSeriesIDs, targetSeriesIDs);
        allSeriesIDs = allSeriesIDs(mask);
        Bs.allDates_ABR = Bs.allDates_ABR(mask);
    end
    
    nABR = numel(allSeriesIDs);
    if nABR == 0
        fprintf('  No ABR recordings selected for export.\n');
        wave_annotations = struct();
        return;
    end

    %  A ProcessingModule is a container for derived/processed data (as opposed
    %  to raw acquisition data). Since we're only storing averaged, filtered
    %  waveforms (not raw sweeps), this belongs in /processing, not /acquisition.
    abrProcModule = types.core.ProcessingModule(...
        'description', 'Processed ABR data: averaged filtered waveforms and stimulus metadata');

    % Initialize accumulators for wave annotations
    wave_recordingID  = {};
    wave_traceIndex   = [];
    wave_amplitude    = zeros(0,2,5);
    wave_latency      = zeros(0,2,5);
    wave_sampleIndex  = zeros(0,2,5);

    for iABR = 1:nABR
        seriesID = allSeriesIDs(iABR);
        B = loadBerabr(berabr(ee, seriesID));
        %% Collect Metadata from BERABR object

        % --- Compute this recording's start time relative to session anchor ---
            % All ElectricalSeries in the file must share a consistent time axis,
        % so every recording's starting_time is expressed in seconds relative
        % to session_start_time         
        abrOffset_s = seconds(Bs.allDates_ABR(iABR) - sessionStart);

        % --- Extract common time vector and sampling rate ---
        % t is relative to stimulus onset (negative values = pre-stim baseline)
        t_common = B.F(1).t(:);
        fs = 1 / mean(diff(t_common));

        % --- Sanity check: confirm every trace shares the same time axis ---
        % If this fails, traces would need individual ElectricalSeries instead
        % of being combined into one matrix (see fallback discussed earlier).    
        for ii = 2:B.nTraces
            if numel(B.F(ii).t) ~= numel(t_common) || ~isequal(B.F(ii).t(:), t_common)
                warning('%s: time axis differs for trace %d - check manually!', seriesID, ii);
            end
        end

        % --- Assemble the data matrix: [nSamples x nTraces] ---
        % Each column = one averaged, filtered waveform for one stimulus condition.
        nSamples = numel(t_common);
        abrTraces = nan(nSamples, B.nTraces);
        for ii = 1:B.nTraces
            abrTraces(:, ii) = B.F(ii).ABR(:);
        end

        % Filter info
        filterInfo = B.F(1).filter; 

        % --- Extract per-trace stimulus parameters from B.Stim ---
        modality  = arrayfun(@(s) string(s.modality), B.Stim)';
        mode      = arrayfun(@(s) string(s.mode), B.Stim)';
        intensity = arrayfun(@(s) double(s.intensity), B.Stim)';
        unit      = arrayfun(@(s) string(s.unit), B.Stim)';
        duration  = arrayfun(@(s) double(s.duration)/1000, B.Stim)'; % seconds
        repRate   = arrayfun(@(s) double(s.repRate), B.Stim)';
        protocol  = arrayfun(@(s) string(s.protocol), B.Stim)';

        if isfield(B.Stim, 'stimulusHardware')
            stimulusHardware = arrayfun(@(s) string(s.stimulusHardware), B.Stim)';
        else
            stimulusHardware = repmat("unknown", B.nTraces, 1);
        end

        % --- Extract calibrated laser power if this is an optical ABR series ---
        % B.C.Ical holds calibrated mW values; empty/absent for acoustic-only recordings.    
        if ~isempty(B.C) && isfield(B.C, 'Ical') && ~isempty(B.C.Ical)
            laserPower_mW = double(B.C.Ical(:));
            if numel(laserPower_mW) ~= B.nTraces
                warning('%s: length of B.C.Ical does not match nTraces - check indexing!', seriesID);
                laserPower_mW = nan(B.nTraces, 1);
            end
        else
            laserPower_mW = nan(B.nTraces, 1);
        end

        % --- Build Stimulus Table ---
        % One row per trace/column in abrTraces above. Every VectorData column
        % requires both 'data' and 'description' or export will fail.   
        abrStimTable = types.hdmf_common.DynamicTable(...
            'description', sprintf('Stimulus conditions for ABR recording %s (bandpass %d-%d Hz)', ...
            seriesID, filterInfo(2), filterInfo(1)), ...
            'colnames', {'modality','stimulus_hardware','recording_id','mode','intensity','unit','duration_s','rep_rate_Hz','protocol','laser_power_mW'});
        
        abrStimTable.vectordata.set('modality', types.hdmf_common.VectorData('data', cellstr(modality), 'description', 'Stimulus modality'));
        abrStimTable.vectordata.set('stimulus_hardware', types.hdmf_common.VectorData('data', cellstr(stimulusHardware), 'description', 'Stimulus hardware'));
        abrStimTable.vectordata.set('recording_id', types.hdmf_common.VectorData('data', repmat(cellstr(seriesID), B.nTraces, 1), 'description', 'Original berabr SeriesID'));
        abrStimTable.vectordata.set('mode', types.hdmf_common.VectorData('data', cellstr(mode), 'description', 'Stimulus mode'));
        abrStimTable.vectordata.set('intensity', types.hdmf_common.VectorData('data', intensity, 'description', 'Stimulus intensity'));
        abrStimTable.vectordata.set('unit', types.hdmf_common.VectorData('data', cellstr(unit), 'description', 'Unit for intensity'));
        abrStimTable.vectordata.set('duration_s', types.hdmf_common.VectorData('data', duration, 'description', 'Duration in seconds'));
        abrStimTable.vectordata.set('rep_rate_Hz', types.hdmf_common.VectorData('data', repRate, 'description', 'Repetition rate'));
        abrStimTable.vectordata.set('protocol', types.hdmf_common.VectorData('data', cellstr(protocol), 'description', 'Protocol'));
        abrStimTable.vectordata.set('laser_power_mW', types.hdmf_common.VectorData('data', laserPower_mW, 'description', 'Calibrated laser power'));
        abrStimTable.id = types.hdmf_common.ElementIdentifiers('data', int64(0:B.nTraces-1)');

        % --- Build ElectricalSeries ---
        % holding the averaged waveforms and links it to the 
        % 'electrodes' in the shared electrode table/region and
        % 'starting_time' anchors this series on the shared
        % session clock; 'starting_time_rate' encodes the sampling rate.
        abrSeries = types.core.ElectricalSeries(...
        'data', abrTraces, ...
        'electrodes', abrElecRegion, ...
        'starting_time', abrOffset_s + t_common(1), ...
        'starting_time_rate', fs, ...
        'data_unit', 'volts', ...
        'description', sprintf(...
            ['Averaged, filtered ABR waveforms for recording %s. ' ...
             'Bandpass %d-%d Hz. RecordingModality: %s. ' ...
             'Columns correspond to rows in the associated stim table.'], ...
             seriesID, filterInfo(2), filterInfo(1), B.Stim(1).modality)...
             );

        % --- Sanitize the seriesID for use as a valid NWB object name ---
        % NWB object names can't contain hyphens etc.; makeValidName() converts
        % e.g. "10-33-51-BERA" -> "x10_33_51_BERA"   
        safeName = matlab.lang.makeValidName(seriesID);

        % --- Attach both the waveform series and its stimulus table to the module ---
        abrProcModule.nwbdatainterface.set(sprintf('%s_waveforms', safeName), abrSeries);
        abrProcModule.dynamictable.set(sprintf('%s_stim_table', safeName), abrStimTable);

        % --- Collect Manual Wave Annotations ---
        waveFile = fullfile(char(expProcDataDir(ee.ExperimenterID, ee.ExpID)), sprintf('W_%s_%s.mat', ee.ExpID, seriesID));
        if isfile(waveFile)
            Wload = load(waveFile);
            Wstruct = Wload.W;
            if numel(Wstruct) ~= B.nTraces
                warning('%s: W_ file has %d entries but berabr has %d traces - only the first %d will be exported.', ...
                    seriesID, numel(Wstruct), B.nTraces, min(numel(Wstruct),B.nTraces));
            end
            for jj = 1:min(numel(Wstruct), B.nTraces)
                wave_recordingID{end+1,1}   = char(seriesID); %#ok<AGROW>
                wave_traceIndex(end+1,1)    = jj; %#ok<AGROW>
                wave_amplitude(end+1,:,:)   = Wstruct(jj).A; %#ok<AGROW>
                wave_latency(end+1,:,:)     = Wstruct(jj).t; %#ok<AGROW>
                wave_sampleIndex(end+1,:,:) = Wstruct(jj).ii; %#ok<AGROW>
            end
        else
             fprintf('%s: no W_ annotation file found - wave annotations will be omitted for this recording.\n', seriesID);
        end   
    end

    nwb.processing.set('abr', abrProcModule);

    % Package annotations for return
    wave_annotations.recordingID  = wave_recordingID;
    wave_annotations.traceIndex   = wave_traceIndex;
    wave_annotations.amplitude    = wave_amplitude;
    wave_annotations.latency      = wave_latency;
    wave_annotations.sampleIndex  = wave_sampleIndex;
end