function result = runICPipeline(ExpID)
% runICPipeline - GUI-free IC pipeline for one experiment:
%   1) calibrates and extracts spikes for every usable icme recording
%   2) runs whichever protocol-specific analyses ICRoleRegistry.m defines
%      for this animal (tonotopy slope / rep-rate vector strength /
%      pulse-intensity spread of excitation + optional PSTH / pulse-
%      duration d-prime), reusing the already-extracted IC objects
%   3) computes anex-wide IC intensity thresholds unconditionally for
%      every animal (mirrors intensityThreshold(ee,'Optical'/'Acoustic')
%      being standard for every ABR animal - intensityThresholdIC itself
%      returns [] gracefully if no recording of the requested ExpType
%      exists, so no per-animal registry/opt-in is needed for this part)

ExperimenterID = getExperimenterFromExpID(ExpID);
rawDataDir = [testRawDataRoot, ExpID];

ee = getOrCreateTestAnex(ExpID, ExperimenterID, rawDataDir, "IC");

enablecache off
allIcme(ee);

copyUserInputFixtures(ExpID, ExperimenterID);

icUserInputFile = fullfile(expProcDataDir(ExperimenterID,ExpID),'ICME', ...
    sprintf('ICUserInput_%s.mat', ExpID));
hasICUserInput = isfile(icUserInputFile);

result = struct('ExpID', ExpID, 'hasICUserInput', hasICUserInput);

enablecache on
L = listIcme(ee);
result.SeriesIDs = cellstr(L.IC_SeriesID);
result.meanSpikeRatesFirst = [];
result.meanSpikeRatesFirstSeriesID = '';

if ~hasICUserInput
    return
end

S = load(icUserInputFile);   % expects UT, and ideally CalibrationDone
UT = S.UT;
if isfield(S,'CalibrationDone')
    calibrationDone = S.CalibrationDone;
else
    calibrationDone = false;  % fallback - confirm fixture always carries this
end

registry = ICRoleRegistry();
animalRoles = struct();
if isfield(registry, ExpID)
    animalRoles = registry.(ExpID);
end

processedIC = containers.Map();   % keeps extracted IC objects around for role dispatch below, avoids re-extracting

for ii = 1:numel(L.IC_SeriesID)
    SeriesID = string(L.IC_SeriesID(ii));

    ix_in_UT = cellfun(@(x) strcmp(x, SeriesID), ...
        UT.data(:, find(contains(UT.fieldNames,'SeriesID'))));
    if ~any(ix_in_UT)
        continue
    end
    if UT.data{ix_in_UT, find(contains(UT.fieldNames,'Use'))} == -1
        continue
    end

    enablecache on
    IC = loadIcme(icme(ee, SeriesID));

    OD = UT.data{ix_in_UT, find(contains(UT.fieldNames,'Filter'))};
    ComPort = UT.data{ix_in_UT, find(contains(UT.fieldNames,'Port'))};

    enablecache off
    if calibrationDone
        IC = getCalibration(IC, OD, ComPort);
    else
        IC = calculateCalibration(IC, OD, ComPort);
    end
    saveIcme(IC);

    IC = ExtractMUAfromRawDataIntoSL(IC);
    saveIcme(IC);

    processedIC(char(SeriesID)) = IC;

    if isempty(result.meanSpikeRatesFirst)
        [meanSpikeRates, ~] = calculateSpikeRate(IC, 0, 50);
        result.meanSpikeRatesFirst = meanSpikeRates;
        result.meanSpikeRatesFirstSeriesID = char(SeriesID);
    end
end

% ---- protocol-specific analyses, only for roles ICRoleRegistry.m
% defines for this animal ----

if isfield(animalRoles,'tonotopy') && processedIC.isKey(char(animalRoles.tonotopy.SeriesID))
    IC = processedIC(char(animalRoles.tonotopy.SeriesID));
    [tonotopy_array, tonotopy_slope] = calculateTonotopicSlope(IC, false, 'increasingLvl', 1);
    result.tonotopy.slope = tonotopy_slope;
    result.tonotopy.array = tonotopy_array;
    result.tonotopy.SeriesID = char(animalRoles.tonotopy.SeriesID);
end

if isfield(animalRoles,'repRate') && processedIC.isKey(char(animalRoles.repRate.SeriesID))
    IC = processedIC(char(animalRoles.repRate.SeriesID));
    r = animalRoles.repRate;
    [VS_array, ~, rates] = calculateVS(IC, r.stim_criteria_array, r.t_start, r.t_stop);
    result.repRate.VS_array = VS_array;
    result.repRate.rates = rates;
    result.repRate.SeriesID = char(r.SeriesID);
end

if isfield(animalRoles,'pulseIntensity') && processedIC.isKey(char(animalRoles.pulseIntensity.SeriesID))
    IC = processedIC(char(animalRoles.pulseIntensity.SeriesID));
    p = animalRoles.pulseIntensity;
    % NOTE: calculateSOE.m's own header says it is "getting retired" in
    % favor of calculateSOEMultipleStimVars/calculateSOEContourlines... -
    % using it here since it's what was explicitly requested; revisit if
    % you'd rather test one of the newer functions.
    SoE_results = calculateSOE(IC, 'increasingLvl', p.stim_criteria_array, p.t_start, p.t_stop);
    result.pulseIntensity.SoE_elecs = SoE_results.SoE_elecs;
    result.pulseIntensity.SoE_mm = SoE_results.SoE_mm;
    result.pulseIntensity.SeriesID = char(p.SeriesID);

    % optional: numeric-only PSTH check (no plotting), piggybacking on
    % this same recording/stim_criteria_array
    if isfield(p,'psth')
        ps = p.psth;
        elecs = getResponsiveUnits(IC, p.stim_criteria_array, p.t_start, p.t_stop);
        [PSTH_norm, PSTH, bin_centers, ~, t_onset, t_offset, peak_response_time] = ...
            calculatePSTH(IC, p.stim_criteria_array, elecs, 0, ps.artefact_removal, ...
                ps.stimdur_ix, ps.t_start, ps.t_stop, ps.PSTH_binsize);
        result.pulseIntensity.psth.PSTH_norm = PSTH_norm;
        result.pulseIntensity.psth.PSTH = PSTH;
        result.pulseIntensity.psth.bin_centers = bin_centers;
        result.pulseIntensity.psth.t_onset = t_onset;
        result.pulseIntensity.psth.t_offset = t_offset;
        result.pulseIntensity.psth.peak_response_time = peak_response_time;
    end
end

if isfield(animalRoles,'pulseDuration') && processedIC.isKey(char(animalRoles.pulseDuration.SeriesID))
    IC = processedIC(char(animalRoles.pulseDuration.SeriesID));
    pd = animalRoles.pulseDuration;
    elecs = getResponsiveUnits(IC, pd.stim_criteria_array, pd.t_start, pd.t_stop);
    d_prime_results = calculateDprime(IC, pd.mode, pd.stim_criteria_array, pd.t_start, pd.t_stop);
    result.pulseDuration.numResponsiveElecs = numel(elecs);
    result.pulseDuration.thresholds = d_prime_results.thresholds;
    result.pulseDuration.SeriesID = char(pd.SeriesID);
end

% ---- anex-wide IC thresholds - unconditional for every animal (see
% function header note) ----
enablecache off
result.icAnexWideThresholds = struct();
result.icAnexWideThresholds.baseline         = intensityThresholdIC(ee, 'baseline');
result.icAnexWideThresholds.increasingLvl    = intensityThresholdIC(ee, 'increasingLvl');
result.icAnexWideThresholds.acousticBaseline = intensityThresholdIC(ee, 'baseline', 'MX_tones', [4,0,90;1,500,32000]);

end