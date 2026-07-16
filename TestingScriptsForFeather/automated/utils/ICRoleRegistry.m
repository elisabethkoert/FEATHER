function registry = ICRoleRegistry()
% ICRoleRegistry - MANUALLY CURATED mapping of which icme SeriesID plays
% which experimental "role" for each animal, plus the stim_criteria_array
% / time window each role-specific analysis function needs. Edit by hand;
% do NOT auto-generate - correct intensity/duration ranges depend on each
% animal's actual calibrated laser output, which cannot be inferred
% automatically.
%
% Roles wired up in runICPipeline.m:
%   tonotopy       -> calculateTonotopicSlope   (no stim_criteria_array needed -
%                                                 hardcoded internally; only
%                                                 requires ExpType=='MX_tones')
%   repRate        -> calculateVS               (vector strength)
%   pulseIntensity -> calculateSOE              (spread of excitation)
%
% Leave a role out entirely for an animal if not yet confirmed -
% runICPipeline will simply skip it.

registry = struct();

% ----- GEK030 
% tonotopy
registry.GEK030.tonotopy.SeriesID = "GEK030_0001";

% rep Rate protocol OBIS laser
registry.GEK030.repRate.SeriesID = "GEK030_0007";
registry.GEK030.repRate.stim_criteria_array = [4,10,500;1,30,34];
registry.GEK030.repRate.t_start = 0;
registry.GEK030.repRate.t_stop  = 115;

% pulse intensity OBIS laser no filter
registry.GEK030.pulseIntensity.SeriesID = "GEK030_0004";
registry.GEK030.pulseIntensity.stim_criteria_array = [1,0,60;3,1,1];
registry.GEK030.pulseIntensity.t_start = 3;
registry.GEK030.pulseIntensity.t_stop  = 25;
registry.GEK030.pulseIntensity.psth.t_start        = -10;
registry.GEK030.pulseIntensity.psth.t_stop         = 60;
registry.GEK030.pulseIntensity.psth.PSTH_binsize   = 0.25;
registry.GEK030.pulseIntensity.psth.artefact_removal = 1;
registry.GEK030.pulseIntensity.psth.stimdur_ix     = 10;

% pulse duration OBIS laser no filter
registry.GEK030.pulseDuration.SeriesID = "GEK030_0006";
registry.GEK030.pulseDuration.stim_criteria_array = [3,0,5;1,0,60];
registry.GEK030.pulseDuration.t_start = 3;
registry.GEK030.pulseDuration.t_stop  = 30;
registry.GEK030.pulseDuration.mode  = 'baseline';


% ----- gjg131644 -
registry.gjg131644.tonotopy.SeriesID = "gjg131644_0001";

% rep Rate protocol OBIS laser
registry.gjg131644.repRate.SeriesID = "gjg131644_0004";
registry.gjg131644.repRate.stim_criteria_array = [4,10,500;1,25,35]; 
registry.gjg131644.repRate.t_start = 0;
registry.gjg131644.repRate.t_stop  = 115;

% pulse duration OBIS laser no filter
registry.gjg131644.pulseDuration.SeriesID = "gjg131644_0002";
registry.gjg131644.pulseDuration.stim_criteria_array = [3,0,5;1,0,60];
registry.gjg131644.pulseDuration.t_start = 3;
registry.gjg131644.pulseDuration.t_stop  = 30;
registry.gjg131644.pulseDuration.mode  = 'baseline';


% ----- gna192119 - acoustic single-tone/noiseband protocol; does not use
% MX_tones/OBIS-pulse/f_train ExpTypes at all, so none of these three
% roles apply. Intentionally left unset. -----

% ----- gth212308 
registry.gth212308.tonotopy.SeriesID = "gth212308_0001";

% pulse intensity protocol dark red laser
registry.gth212308.pulseIntensity.SeriesID = "gth212308_0004";
registry.gth212308.pulseIntensity.stim_criteria_array = [1,0,60;3,1,1];
registry.gth212308.pulseIntensity.t_start = 3;
registry.gth212308.pulseIntensity.t_stop  = 25;




end