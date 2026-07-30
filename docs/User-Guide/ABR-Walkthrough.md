---
title: ABR Walkthrough
---
# ABR Analysis Walkthrough

This page walks you through analysing Auditory Brainstem Response (ABR) recordings for one animal experiment, from raw data to thresholds and peak amplitudes. It assumes you have already completed [[Getting Started – Installation & Toolbox Setup|User-Guide-Getting-Started]] and read [[How FEATHER Works (Big Picture)|User-Guide-How-FEATHER-Works]].

A full working example of everything on this page is available in the toolbox at:

```
exampleScripts/processing_new_ABR_data.m
```

It's worth keeping that script open alongside this page — it's a runnable version of the steps below.

In FEATHER, each individual ABR recording is represented by a `berabr` object. All `berabr` objects for one animal live inside that animal's `anex`.

---

## Before you start

You will need:

- The **Experiment ID** of your animal (e.g. `GEK030`).
- The **raw data folder path** for the ABR recordings, relative to your raw-data drive.
- The **Experimenter ID** (initials of whoever ran the animal experiment).

---

## Step 1: Create (or load) the `anex` for your animal

If this is the **first time** anyone has analysed this animal in FEATHER, create a new `anex` and point it at the raw ABR data:

```matlab
ExpID = 'GEK030';
rawDatadir = ["archiv","systems","AllDataTypesForAnalysisTests","GEK030"];
experimenterID = 'test';

enablecache off   % make sure you load fresh raw data, not old cached results
D(1).dir = rawDatadir;
D(1).type = "ABR";
ee = anex(ExpID, experimenterID, D);
ee = setAnimalSpecies(ee,'mouse');   % or your species
initProcessedExp(ee)                 % creates the results folder for this animal
initKiwi(ee)                         % opens a notes file you can use for this animal
saveAnex(ee);
```

If the `anex` **already exists** (e.g. a labmate already set it up, or you're returning to this animal on a different day), just load it instead:

```matlab
enablecache on
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);
```

This is also where you should fill in `ExpMetaData` (date of birth, injection details, virus batch, etc.) as indicated in th example script. The more MetaData you add, the easier it will be later to work with the data, but it is not a requirement for running FEATHER analysis.

---

## Step 2: Process all ABR recordings

This step reads in every ABR raw-data file found for this animal and prepares it for analysis (filtering, etc.):

```matlab
enablecache off
allBerabr(ee)
```

After this runs, every ABR recording is available as a `berabr` object that you can browse and annotate.

---

## Step 3: Mark ABR wave peaks (manual step, via GUI)

FEATHER cannot automatically identify ABR wave peaks — this requires manual annotation. Open the exploration GUI:

```matlab
exploreBerabr(ee)
```

This opens **`exploreBerabr`**, which lists all ABR recordings for this animal. Selecting a recording and clicking **clickWaves** opens **`berabrWaveGUI2`**, where you click on the peaks of each wave for each stimulus intensity.

⚠️ You must press the green **Accept** button after annotating each trace, and the **EXPORT** button when you are done, or your annotations will not be saved.

Full button-by-button instructions for both GUIs are in the [[GUI Reference|User-Guide-GUI-Reference]] page — read that page in full before doing this step for the first time.

---

## Step 4: Record which hardware/filter was used for each recording

Calibration later on depends on knowing which optical density filter and which specific piece of laser hardware was used for each optical ABR recording. Enter this information via:

```matlab
userberabrOD(ee)
```

This opens the **`userberabrOD`** GUI (see [[GUI Reference|User-Guide-GUI-Reference]]). For each `berabr`, fill in the applied optical density filter (or current setting, depending on hardware) and, if there are multiple lasers of the same type in use, enough additional detail (e.g. serial number or COM port) to tell them apart. Press **EXPORT** when done.

For **acoustic-only** recordings, this step is not required — no calibration file is needed since the stimulation software already outputs calibrated dB SPL values.

---

## Step 5: Calibrate optical intensities

For optical ABR recordings, laser output settings (e.g. "60%") need to be converted into actual light intensity (mW), using calibration files recorded separately with the LaserControl software:

```matlab
setCalibrationBeraFromLaserControl(ee)
```

This function looks for calibration `.txt` files in the ABR raw-data folder, matches them to each recording based on what you entered in Step 4, and stores the calibrated intensity values with each `berabr`.

---

## Step 6: Get thresholds and peak amplitudes

Once calibration is done, you can compute standard summary values across all recordings for this animal.

**Lowest intensity with a detectable wave (threshold):**

```matlab
enablecache off
[ExpIntThrAcoustic] = intensityThreshold(ee, 'Acoustic');
[ExpIntThrOptical]  = intensityThreshold(ee, 'Optical');
```

**Largest P1-N1 amplitude and its latency, across all recordings of a given modality:**

```matlab
[MaxABRValues] = ABRMaxWaveValues(ee, 'Optical');
```

---

## Step 7: Working with your results afterwards

Once everything above has been run once, you can revisit results quickly with caching turned on, without reprocessing raw data. See `exampleScripts/processing_new_ABR_data.m` for ready-to-use snippets covering:

- listing and loading individual `berabr` recordings,
- quick-plotting traces (`B.plotBerabr`),
- inspecting stimulus intensities, calibration values, and protocol settings on a loaded recording.

---

## Supported stimulus hardware

The following hardware types are automatically recognised by FEATHER for ABR recordings. If your recording used something not on this list, see the Developer Guide's [[How to Add Support for New Laser/Stimulus Hardware|Developer-Guide-Adding-New-Hardware]] page (or ask a developer to add it).

| Hardware (`Speaker` field) | Modality |
|---|---|
| `avisoft` | Acoustic |
| `Laser ObisTTL` | Optical |
| `uLED Array` | Optical |
| `Laser TTL AOTF 473` | Optical |
| `Laser Oxxius` | Optical |
| `Laser RedL660P` | Optical |
| `LaserOxxiusMPA542` | Optical |
| `Laser OxxiusAnalog` | Optical |
| `Laser A   AOTF 473` | Optical |
| `electric_placeholder` | Electric |

---

## What's next

- [[IC Analysis Walkthrough|User-Guide-IC-Walkthrough]]
- [[Histology Analysis Walkthrough|User-Guide-Histology-Walkthrough]]
- [[GUI Reference|User-Guide-GUI-Reference]] for detailed button-by-button GUI instructions
- [[FAQ / Troubleshooting|User-Guide-FAQ]] if something goes wrong