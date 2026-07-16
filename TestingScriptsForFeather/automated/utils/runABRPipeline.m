function result = runABRPipeline(ExpID)
% runABRPipeline - GUI-free ABR pipeline for one experiment, returns a
% struct of results suitable for golden-file comparison.

ExperimenterID = getExperimenterFromExpID(ExpID);
rawDataDir = [testRawDataRoot, ExpID];

ee = getOrCreateTestAnex(ExpID, ExperimenterID, rawDataDir, "ABR");

enablecache off
allBerabr(ee);

copyUserInputFixtures(ExpID, ExperimenterID);

hasODui = isfile(fullfile(expProcDataDir(ExperimenterID,ExpID), ...
    sprintf('ODui_%s.mat', ExpID)));

result = struct('ExpID', ExpID, 'hasODui', hasODui);

if hasODui
    setCalibrationBeraFromLaserControl(ee);
    enablecache off
    result.ThrOptical  = intensityThreshold(ee, 'Optical');
    result.ThrAcoustic = intensityThreshold(ee, 'Acoustic');
    % NOTE: ABRMaxWaveValues is documented as not yet working for 'Acoustic'
    result.MaxOptical  = ABRMaxWaveValues(ee, 'Optical');
end

end