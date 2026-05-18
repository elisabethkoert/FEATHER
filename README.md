# FEATHER
FEATHER: a Framework for Experimental Analysis of Tissue and Electrophysiology for Heterogeneous Experiments and Researchers

This project is a toolbox developed for the institute for auditory neuroscience to process the various types of data generated in connection to an animal experiment in the institute from *in-vivo* electrophysiology recordings to results from immunohistochemical analysis of tissue.

## Authors
Tht toolbox framework was set up by Anna Vavakou. Elisabeth Koert and Niels Albrecht joined as developers. Elisabeth Koert created this public version from the institues private code in connection to the publication XXX.

# Affiliation
Institute for Auditory Neuroscience  
University Medical Center Goettingen <br>
Robert-Koch_Str. 40<br>
37075 Goettingen<br>
Germany

---

# Toolbox Overview

## Classes

### `anex` — Animal Experiment
An `anex` object holds all information associated with a single animal experiment. It acts as the central entry point that links raw data directories, metadata, and the various data objects collected across experimental sessions (ABR, IC recordings, histology, etc.).

**Properties**
| Property | Type | Description |
|---|---|---|
| `ExpID` | string | Experiment/animal identifier (e.g. `GEK111`) |
| `Species` | string | Animal species (e.g. mouse, gerbil) |
| `ExperimenterID` | string | ID of the person who ran the experiment (e.g. `EK`) |
| `UserID` | string | ID of the analyst currently working on the data |
| `RawDataDir` | struct | Struct array pointing to raw data directories, each with a `.dir` path and a `.type` label (e.g. `"ABR"`, `"SU"`, `"IC"`, `"NintendoRes"`) |
| `ExpMetaData` | struct | Arbitrary experimental metadata |

**Functions**
- `anex(ExpID, ExperimenterID, RawDataDir)` — Constructor; sets up directory paths and loads cached data if caching is enabled.
- `getSUrawDir` / `getABRrawDir` / `getICrawDir` — Retrieve the raw data directory for a specific data type.
- `getProcessedDataDir` / `setProcessedDataDir` — Get or update the processed-data directory for this experiment.
- `setRawDataDir` / `setAnimalSpecies` / `setExperimenterID` / `setUserID` / `setExpMetaData` — Setters for individual properties.
- `listBerabrRaw` / `listBerabr` — List ABR series in the raw data folder or the processed data folder.
- `listIcRaw` / `listIcme` — List IC raw log files or processed ICME objects.
- `listSuRaw` / `listSutr` — List single-unit raw files or processed single-unit objects.
- `listHistImgsRaw` / `listHistimg` — List histology image sets in the raw or processed data folder.
- `allBerabr` — Initialize `berabr` objects for all ABR series found in the raw data.
- `allIcme` — Initialize `icme` objects for all IC recording series found in the raw data.
- `initProcessedExp` — Create the processed-data folder hierarchy for a new experiment.
- `saveAnex` / `loadAnex` — Persist or reload the `anex` object in the processed data directory.
- `intensityThreshold` — Determine the ABR intensity threshold for a given stimulus modality.
- `intensityThresholdIC` — Determine the IC d-prime-based intensity threshold across the recording array.
- `getAcousticThresh` — Retrieve acoustic threshold for a given frequency and bandwidth.
- `ABRMaxWaveValues` — Extract the maximum ABR wave amplitudes and latencies.
- `findModProt` — Find a `berabr` measurement matching a specific modality and protocol.
- `loadStimOverview` / `loadSROverview` — Load stimulus or spike-rate overview tables across all IC recordings.
- `calculateDynamicRangeAnex` — Compute the dynamic range of IC responses for a given stimulus type.
- `getHistoResults` — Retrieve combined histology results from all `histimg` objects linked to this experiment.
- `setCalibrationBeraFromLaserControl` — Import and attach a calibration file from the laser-control software.
- `initKiwi` / `kiwiFile` — Initialise or retrieve the Kiwi user-annotation file for IC recording data.
- `winopenR` / `winopenP` — Open the raw or processed data directory in the system file explorer.
- `FSL` — First-spike-latency analysis for a specified set of stimulus conditions.

---

### `berabr` — Brainstem Auditory Evoked Response (BERA software)
A `berabr` object contains all data for a single ABR measurement series acquired with the BERA software. It stores the raw traces, processed waveforms, stimulus parameters, and calibration information for acoustic, optical, or electric stimulation.

**Properties**
| Property | Type | Description |
|---|---|---|
| `ExpID` | string | Experiment identifier |
| `SeriesID` | string | Series identifier (e.g. `0001BERA`) |
| `ExpInfo` | struct | Header metadata from the BERA recording file |
| `nTraces` | double | Number of ABR traces in the series |
| `Stim` | struct | Stimulus parameters (modality, protocol, intensities, hardware) |
| `R` | struct | Raw data (averaged traces per intensity level, before FEATHER processing) |
| `F` | struct | FEATHER-processed data (filtered ABR waveforms and split even/odd traces) |
| `C` | struct | Calibration file |
| `D` | struct | Directory information for the raw data |

**Functions**
- `berabr(ee, SeriesID, D)` — Constructor; links the object to an `anex` and optionally a raw data directory.
- `initBerabr` — Full preprocessing pipeline: load raw data → extract stimulus info → process waveforms → save.
- `loadRaw` — Load raw BERA data from the directory stored in `D`.
- `stim` — Extract stimulus parameters (modality, protocol, intensity levels, hardware) from the raw data and populate `Stim`.
- `processBerabr(FcL, FcH)` — Filter and average the raw traces into FEATHER-processed waveforms (stored in `F`).
- `computeFeather` — Alternative waveform computation pipeline (e.g. for legacy datasets).
- `intensityThreshold` — Find the lowest intensity level that exceeds a detection criterion.
- `crossCorThreshold` — Determine threshold using cross-correlation of even and odd sub-average traces.
- `findMaxWave` — Extract P1/N1 amplitude and latency at the highest annotated intensity.
- `importWaves` — Import user wave-peak annotations from an associated annotation file.
- `saveBerabr` / `loadBerabr` — Save or load the processed `berabr` object to/from the processed data directory.
- `setRawDataDir` — Update the raw data directory pointer.
- `setC` — Attach a calibration struct.
- `ttlString` — Generate descriptive title and legend strings for plots.
- `inverseBerabr` — Invert the ABR polarity (to correct for arbitrary electrode placement).
- `nanBerabr(ii)` — Replace trace `ii` with NaN values (to exclude a single artefact-contaminated trace).
- `plotBerabr` — Plot the full ABR series (waveforms stacked by intensity).
- `plotCalibration` — Plot the attached calibration data.

---

### `icme` — Inferior Colliculus Multielectrode Recording
An `icme` object characterises a single IC recording session acquired with a multielectrode probe via the Cheetah/Neuralynx system. It stores the recording metadata, stimulus information, the spike list (MUA), and analysis results.

**Properties**
| Property | Type | Description |
|---|---|---|
| `ExpID` | string | Experiment identifier |
| `SeriesID` | string | Recording series identifier (e.g. `GEK111_0001`) |
| `ExpInfo` | struct | Metadata from the ExpControl log file |
| `Stim` | struct | Stimulus info including stimulus list, headers, and presentation parameters |
| `R` | struct | Raw data references (event timestamps, raw file pointers) |
| `EP` | struct | Electrode probe information |
| `SL` | struct | Spike list: detected MUA spikes per electrode, analysis parameters |
| `C` | struct | Calibrated stimulus list and calibration array |
| `D` | struct | Directory where raw data is stored |

**Functions**
- `icme(ee, SeriesID, D)` — Constructor; links the object to an `anex` and automatically finds the IC raw data directory.
- `initIcme` — Preprocessing entry point: load log file and save the initialised object.
- `loadLogFileInfo` — Load the ExpControl log file and populate `ExpInfo` and `Stim`.
- `ExtractMUAfromRawDataIntoSL` — Detect MUA spikes from raw Neuralynx data and populate `SL` (with configurable threshold, filter, and time-window parameters).
- `loadMUAfromRESORTFile` / `loadSLfeather_fromRESORT` — Load a spike list from an existing RESORT export file.
- `loadSLfeather` — Legacy function to load a spike list.
- `stim` — Populate the calibrated stimulus list in `C`.
- `getCalibration` / `calculateCalibration` — Retrieve or compute the stimulus calibration from an optical power meter measurement.
- `loadArtWave` / `waveformArtifact` — Load or evaluate stimulation artefact waveforms for artefact removal.
- `evaluateDataAndSpikes_EK` — Quality-control visualisation of raw data acquisition and detected spikes.
- `convertNLXDataForKilosort` — Export raw Neuralynx data in a format compatible with Kilosort spike sorting.
- `generateSLfromRawNlxData_baseline_global` — Low-level spike extraction using a global baseline noise estimate.
- `calculateSpikeRate` — Calculate mean spike rates and per-repetition spike rates across stimulus conditions.
- `calculateEvokedSpikeRate` — Calculate evoked (stimulus-driven) spike rates for a defined time window and stimulus set.
- `calculateSpikeBins` / `getPSTHarrayAllMU` — Bin spikes into peri-stimulus time histograms per electrode or across all MU channels.
- `calculatePSTH` — Compute the normalised PSTH and extract onset/offset response latencies.
- `plotPSTHHeatmap` — Plot a heatmap of PSTH responses across electrodes and stimulus conditions.
- `makeRasterPlot` — Generate a raster plot of spike times across stimulus repetitions.
- `calculateDprime` / `calculateDprimeMultipleStimVars` — Compute d-prime sensitivity indices (cumulative or baseline) for one or multiple stimulus variables.
- `calculateSOEMultipleStimVars` / `calculateSOEContourlinesMultipleStimVars` / `calculateSOEContourlinesMultipleStimVarsAtBE` — Calculate spread-of-excitation across the electrode array for multiple stimulus conditions.
- `calculateDynamicRangeICME` — Compute the dynamic range of IC responses from spike rate or d-prime.
- `calculateVS` — Calculate the vector strength (phase-locking) of responses.
- `runRepRateAnalysis` — Run a repetition-rate / temporal-following analysis.
- `calculateTonotopicSlope` / `calculateTonotopicSlopeSortedbyElectrode` — Determine the tonotopic gradient along the electrode array from best-frequency estimates.
- `getInterpolatedBestFrequenciesForElectrodes` — Interpolate best frequencies for a specified set of electrodes.
- `getSTCSpread` — Calculate the bandwidth of spread-of-excitation contour lines.
- `getStimuliFromStimCriteriaArray` — Filter the stimulus list using a criteria array (column index, min, max).
- `getResponsiveUnits` — Identify responsive electrodes for a given stimulus condition.
- `findBadElectrodes` — Flag outlier electrodes based on spike rate statistics.
- `ROCAna_03` — Receiver-operating-characteristic analysis for d-prime calculation.
- `saveIcme` / `loadIcme` — Save or load the `icme` object to/from the processed data directory.
- `setRawDataDir` — Update the raw data directory pointer.
- `plotHeatmapsIC` — Plot standard spike-rate and d-prime heatmaps for the recording.
- `plotHeatmap_evokedSR_dPbase1_contour` — Plot evoked spike-rate heatmap overlaid with d-prime contour lines.

---

### `histimg` — Histology Image Set
A `histimg` object holds the results of the Nintendo-based SGN (spiral ganglion neuron) counting analysis for a single confocal image stack, typically a 40× field from one cochlear turn.

**Properties**
| Property | Type | Description |
|---|---|---|
| `ExpID` | string | Experiment identifier |
| `SeriesID` | string | Image set identifier encoding side and turn (e.g. `L_mid`, `R_apex_v2`) |
| `D` | struct | Directory pointers for raw images and Nintendo analysis results |
| `filename` | string | Name of the Nintendo results CSV file |
| `side` | string | Cochlear side (`L` or `R`) |
| `turn` | string | Cochlear turn (`apex`, `mid`, or `base`) |
| `version` | double | Version index when multiple image sets exist for the same region |
| `nCells` | double | Total number of detected SGNs |
| `nPosCells` | double | Number of GFP-positive (transduced) SGNs |
| `volume` | double | 3D ROI volume around all detected cells (µm³) |
| `areaSlice` | double | Cross-sectional area at the centre slice (µm²) |
| `volumeNintendoStyle` | double | Manually drawn Rosenthal's canal volume (µm³) |
| `areaSliceNintendoStyle` | double | Cross-sectional area of the manually drawn canal (µm²) |
| `density` / `densityNintendoStyle` | double | SGN density per 10⁵ µm³ (auto / manual ROI) |
| `densityTransduced` / `densityTransducedNintendoStyle` | double | Transduced SGN density per 10⁵ µm³ |
| `density2D` / `densityNintendoStyle2D` | double | 2D SGN density per 10⁴ µm² (derived from volume / number of planes) |
| `density2Dslice` / `densityNintendoStyle2Dslice` | double | 2D SGN density from a single centre slice |
| `transductionRate` | double | Fraction of GFP-positive cells |
| `gfpThreshhold` | double | GFP intensity threshold used in the Nintendo analysis |
| `numPlanesVolume` | double | Number of optical planes in the z-stack |

**Functions**
- `histimg(ee, SeriesID, D, filename)` — Constructor; parses side, turn, and version from the `SeriesID` string, or loads an existing cached object.
- `readNintendoResults` — Read SGN counts, volumes, and density values from the Nintendo CSV export file.
- `saveHistimg` / `loadHistImg` — Save or load the `histimg` object to/from the processed data directory.
- `setRawDataDir` — Update the raw data directory pointer.
- `readMicroscopeSettings` — (Planned) Read microscope acquisition settings from the raw data folder.

---

## Surrounding Utility Functions

### `dirManagement` — Directory and Caching Utilities
A set of standalone functions for managing data paths and session caching. These are used internally by all class methods but can also be called directly.

- `expProcDataDir(ExperimenterID, ExpID)` — Persistent function that generates and stores the path to the processed-data directory for a given experimenter and experiment.
- `gen_dir_name(Din)` — Concatenates the mapped network drive letter (from `ukonmap`) with an array of path components to form a complete directory string.
- `testSafeDir(dir)` — Safety check that raises an error if the supplied path points into the raw-data archive, preventing accidental overwriting of raw data.
- `enablecache(flag)` — Enable (`'on'`) or disable (`'off'`) caching for the current MATLAB session; returns the current state when called without arguments.
- `status_cache` — Returns `1` if caching is enabled and `0` if not; acts as a safety abort when called without an output argument and cache is off.
- `getExperimenterFromExpID(ExpID)` — Helper that extracts the experimenter ID string from a standard experiment ID string.

### `plotFunctions` — Visualisation Utilities
A collection of plotting functions for standard figures used across multiple analyses.

- `plotHeatmapContour(IC, ...)` — Plot a frequency-vs-intensity (or duration/rate) heatmap with d-prime contour lines overlaid, as used in publications.
- `plotHeatmapsIC(IC, mode, ...)` — Plot standard spike-rate and d-prime heatmaps for a single ICME recording.
- `plotHeatmap_evokedSR_dPbase1_contour(IC, ...)` — Plot evoked spike-rate heatmap with contour lines derived from d-prime.
- `plot_tonotopic_slope(anex_names_list, ...)` — Plot electrode depth versus characteristic frequency for one or more experiments.
- `plotSpread(data, ...)` — Plot data distributions by spreading individual points around the x-axis (jitter plot).
- `distributionPlot(data, ...)` — Plot smoothed empirical distributions of data groups.
- `functionWhiskerPlotMEANSTD(data, ...)` — Whisker plot showing mean and standard deviation.
- `nonuniformHM(data, ...)` — Heatmap with non-uniform axis spacing.
- `changeFigureSize(fig, fraction, height_ratio)` — Resize a figure to a given fraction of A4 width with an optional height ratio.

### `multipleAnexFunctions` — Multi-Experiment Analysis
Functions that operate across a list of `anex` objects, enabling population-level analyses.

- `calculatePSTHanex(ee_list, ...)` — Calculate the normalised peri-stimulus time histogram (PSTH) and extract response onset/offset latencies for one or multiple experiments, pooling all IC recordings.
- `calculatePSTHanex_oneRecordingPerAnimal(ee_list, ...)` — Same as above, but restricted to one IC recording per animal to avoid pseudoreplication.