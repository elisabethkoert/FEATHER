# IC Analysis Walkthrough

This page walks you through analysing inferior colliculus (IC) multielectrode recordings for one animal experiment, from raw data to spike rates, response thresholds, and standard analysis plots. It assumes you have already completed [Getting Started – Installation & Toolbox Setup](./Getting-Started.md) and read [How FEATHER Works (Big Picture)](./How-FEATHER-Works.md).

A full working example of everything on this page is available in the toolbox at:

```
exampleScripts/processing_new_IC_data.m
```

It's worth keeping that script open alongside this page — it's a runnable version of the steps below, including several worked examples for different experiment types (pulse intensity, tonotopy, repetition-rate, pulse-duration protocols).

In FEATHER, each individual IC recording is represented by an `icme` object ("inferior-colliculus-multielectrode-recording"). All `icme` objects for one animal live inside that animal's `anex`.

---

## Before you start

You will need:

- An existing `anex` for your animal (usually already created during ABR analysis — see [ABR Analysis Walkthrough](./ABR-Walkthrough.md)).
- The **raw data folder path** for the IC recordings. This is often the same raw-data folder used for ABR.

---

## `icme` — inferior colliculus multielectrode recording object - an overview

Represents one IC multielectrode recording made with a 32-channel NeuroNexus probe, Cheetah/Neuralynx acquisition, and the custom ExpControl stimulation software.

| Property | Description |
|---|---|
| `ExpID`, `SeriesID` | Identifiers |
| `ExpInfo` | Struct copied from the ExpControl `.m` log file |
| `Stim` | Stimulus definitions (`exp_type`, `stimlist`, `stimheader`, `dura`, `n_rep`) |
| `R` | Raw data pointers (event/file info, not full raw traces) |
| `EP` | Electrode probe info (currently mostly unused; probe info lives in the IC user-input table) |
| `SL` | Spike-list struct — multi-unit spikes extracted from raw `.ncs`/`.nev` files, keyed by electrode |
| `C` | Calibrated stimulus list and calibration array |
| `D` | Raw data directory struct |

The `Stim.stimlist` is the single most important structure to understand when extending analysis code: it's a matrix where each **row** is one presented stimulus condition (its row index is the `stim_ID` referenced everywhere in spike lists and `stim_criteria_array` inputs), and each **column** is a stimulus parameter (intensity, duration, frequency, etc.), named in the parallel `stimheader` cell array. Almost every IC analysis function filters this matrix using a `stim_criteria_array` of the form `[column, min, max; column, min, max; ...]`.

## Step 1: Load your `anex` and register the IC raw data folder

```matlab
ExpID = 'GEK030';
experimenterID = 'test';
enablecache on
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);

% register the IC raw data directory (often the same folder as ABR)
D_cur = ee.RawDataDir;
D_cur(end+1).dir = ee.RawDataDir(find([ee.RawDataDir.type]=='ABR')).dir;
D_cur(end).type = "IC";
ee = setRawDataDir(ee, D_cur);
saveAnex(ee);
```

---

## Step 2: Read in all IC recordings

This reads the ExpControl log file (`.m`) for every IC recording found in the raw data folder and creates the corresponding `icme` objects:

```matlab
enablecache off
allIcme(ee)
```

---

## Step 3: Enter recording metadata (manual step, via GUI)

Open the IC user input GUI:

```matlab
ICuserInput(ee)
```

For each `icme`, this table lets you record information that FEATHER cannot read automatically from the raw data, but which is required for later analysis steps — most importantly:

- which **optical density filter / current setting** was used (needed to find the matching calibration file),
- the **laser or implant serial number / COM port**,
- the **fiber diameter** and **cochlear position** (e.g. round window/base, mid, apex),
- whether the recording should be **excluded** from further analysis (set `Use` to `-1`, e.g. for interrupted or noisy recordings).

Press **Done & EXPORT** when finished. Full details of every column are in the [GUI Reference](./GUI-Reference.md) page.

---

## Step 4: Calibration and spike extraction

For each usable `icme`, you need to (a) attach the correct calibration information and (b) extract multi-unit spikes from the raw Neuralynx/Cheetah data. This is normally done in a loop over all recordings, using the information you entered in Step 3:

```matlab
enablecache on
in_dir_name = fullfile(expProcDataDir(ee.ExperimenterID, ee.ExpID),'ICME', ...
    strcat("ICUserInput_", ee.ExpID, ".mat"));
load(in_dir_name);   % loads UT, the user input table from Step 3

L = listIcme(ee);
for ii = 1:numel(L.IC_SeriesID)
    ix_in_UT = cellfun(@(x) strcmp(x, string(L.IC_SeriesID(ii))), ...
        UT.data(:, find(contains(UT.fieldNames,'SeriesID'))));
    if UT.data{ix_in_UT, find(contains(UT.fieldNames,'Use'))} == -1
        continue   % skip recordings marked as unusable
    end

    IC = loadIcme(icme(ee, string(L.IC_SeriesID(ii))));

    % attach calibration
    OD = UT.data{ix_in_UT, find(contains(UT.fieldNames,'Filter'))};
    ComPort = UT.data{ix_in_UT, find(contains(UT.fieldNames,'Port'))};
    IC = getCalibration(IC, OD, ComPort);
    saveIcme(IC);

    % extract multi-unit spikes from raw data (this step is slow — see note below)
    enablecache off
    IC = ExtractMUAfromRawDataIntoSL(IC);
    saveIcme(IC);
end
```

⚠️ Spike extraction (`ExtractMUAfromRawDataIntoSL`) reads through the raw Neuralynx files and can be slow — running it on a lab workstation rather than a laptop is recommended for larger datasets.

---

## Step 5: Get response thresholds

Once spikes have been extracted, you can compute standard threshold summaries across all IC recordings for this animal, separately for optical pulse stimuli and for acoustic (tonotopy) stimuli:

```matlab
enablecache off
optThr = intensityThresholdIC(ee, 'baseline');
optThr = intensityThresholdIC(ee, 'increasingLvl');

acoustThr = intensityThresholdIC(ee, 'baseline', 'MX_tones', [4,0,90;1,500,32000]);
```

---

## Step 6: Analyse a single recording

Most of the day-to-day analysis work happens on individual `icme` objects rather than the whole animal at once. The example script covers this in detail for four common experiment types:

- **Pulse intensity protocols** — spike rate, d′ analysis, spread of excitation, PSTH
- **Tonotopy (`MX_tones`) protocols** — spike rate maps, d′ heatmaps, tonotopic slope
- **Repetition-rate protocols** — raster plots, vector strength, cut-off frequency
- **Pulse-duration protocols** — d′ analysis and PSTHs restricted to specific durations/intensities

Rather than duplicate all of this here, load a recording and follow along in `exampleScripts/processing_new_IC_data.m`:

```matlab
enablecache on
IC = loadIcme(icme(ee, 'GEK030_0004'));   % use your own SeriesID here
```

A few of the most commonly used analysis functions, to get you oriented:

| What you want | Function |
|---|---|
| Spike rate per stimulus/electrode | `calculateSpikeRate` |
| d′ analysis (increasing level or vs. baseline) | `calculateDprimeMultipleStimVars` |
| Which electrodes responded at all | `getResponsiveUnits` |
| Standard heatmaps (spike rate, d′) | `plotHeatmapsIC` |
| Spread of excitation | `calculateSOEContourlinesMultipleStimVars` (and related `calculateSOE*` functions) |
| PSTH and response timing (onset/offset) | `calculatePSTH` |
| Raster plot | `makeRasterPlot` |
| Tonotopic slope (tonotopy experiments) | `calculateTonotopicSlope`, `calculateTonotopicSlopeSortedbyElectrode` |
| Vector strength / cut-off frequency (rep-rate experiments) | `runRepRateAnalysis` |

Most of these functions take a **`stim_criteria_array`** as input, which tells FEATHER which subset of presented stimuli to analyse (e.g. "only 16 kHz tones between 50 and 90 dB", or "only 1 ms pulses between 5 and 60 mW"). This is explained with examples in each function's help text and in the worked examples in the script — look there for the exact syntax for your experiment type.

---

## What's next

- [Histology Analysis Walkthrough](./Histology-Walkthrough.md)
- [GUI Reference](./GUI-Reference.md) for detailed button-by-button GUI instructions
- [FAQ / Troubleshooting](./FAQ.md) if something goes wrong
- Developer Guide: [How to Add a New Experiment/Protocol Type](../Developer-Guide/Adding-New-Experiment-Type.md), if your `stim_criteria_array`/experiment type isn't covered by existing functions
