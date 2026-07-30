# Architecture Overview

This page describes the class hierarchy, data flow, and file/folder conventions underlying FEATHER, for developers who need to extend or maintain the toolbox. It assumes you're comfortable reading MATLAB `classdef` files.

If you're looking for a plain-language, non-technical introduction instead, see the User Guide's [How FEATHER Works (Big Picture)](../User-Guide/How-FEATHER-Works.md) page — it covers the same concepts with no code.

Much of this page is adapted from the toolbox's main `README.md`; refer back to that file in the repository root for the canonical version.

---

## Core objects

FEATHER organizes all data belonging to one animal experiment under a single `anex` (animal-experiment) object, with sub-objects for each recording or image set. Multiple sub-objects of each type can be associated with one `anex`.

### `anex` — animal-experiment object

`anex` is the central container for one animal experiment. It links metadata (`ExpID`, `Species`, `ExperimenterID`, `UserID`) with raw and processed data directories (`RawDataDir`, and the persistent `expProcDataDir`), and provides methods to list and initialize the sub-objects described below.

Key properties (all `SetAccess=private`, changed only via setter methods):

| Property | Type | Description |
|---|---|---|
| `ExpID` | string | Experiment/animal ID, e.g. `GEK111` |
| `Species` | string | Animal species |
| `ExperimenterID` | string | Initials of whoever ran the animal experiment |
| `UserID` | string | Initials of whoever is running the analysis |
| `RawDataDir` | struct array | One entry per raw-data type (`ABR`, `IC`, `SU`, `NintendoRes`, `LSFM`, ...), each with `.dir` (path segments) and `.type` |
| `ExpMetaData` | struct | Free-form experiment metadata (DOB, injection details, virus batch, etc.) |

The constructor behaves differently depending on `status_cache`:
- If caching is **on**, it attempts to `loadAnex` an existing saved object.
- If caching is **off**, it initializes a new object from the given `RawDataDir` and registers the processed-data directory via the persistent `expProcDataDir` function.

At this level, FEATHER enables: listing available ABR/IC/histology datasets, launching experiment-wide analyses (e.g. thresholds across *all* IC or ABR recordings for one animal), and initializing the processed-data folder structure.

### `berabr` — Auditory Brainstem Response object

Represents one ABR measurement recorded with the BERA custom MATLAB software. See [How to Add Support for New Laser/Stimulus Hardware](../Developer-Guide/Adding-New-Hardware.md) for how `berabr.Stim` gets populated per-hardware-type.

| Property | Description |
|---|---|
| `ExpID`, `SeriesID` | Identifiers |
| `ExpInfo` | Struct copied from raw BERA `.mat` file (minus heavy/raw fields) |
| `nTraces` | Number of stimulus conditions/traces |
| `Stim` | Per-trace stimulus struct (modality, intensity, hardware, protocol, etc.) — populated by `stim.m` |
| `R` | Raw data (emptied before saving to disk) |
| `F` | "Feather" — processed/filtered ABR traces, populated by `processBerabr` |
| `C` | Calibration struct — populated by `setCalibrationBeraFromLaserControl` or similar |
| `D` | Raw data directory struct |

Processing pipeline: `initBerabr` → `loadRaw` → `stim` → `processBerabr` → `saveBerabr`.

### `icme` — inferior colliculus multielectrode recording object

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

Processing pipeline: `initIcme` (loads log file) → `ICuserInput` GUI (hardware/filter/quality metadata) → `getCalibration`/`calculateCalibration` → `ExtractMUAfromRawDataIntoSL` → `saveIcme`.

The `Stim.stimlist` is the single most important structure to understand when extending analysis code: it's a matrix where each **row** is one presented stimulus condition (its row index is the `stim_ID` referenced everywhere in spike lists and `stim_criteria_array` inputs), and each **column** is a stimulus parameter (intensity, duration, frequency, etc.), named in the parallel `stimheader` cell array. Almost every IC analysis function filters this matrix using a `stim_criteria_array` of the form `[column, min, max; column, min, max; ...]`.

### `histimg` — histology image object (confocal pipeline)

Represents quantification results from one confocal histology image set (typically one cochlear turn from one side), produced by the Arivis-based "Nintendo" pipeline (Thirumalai *et al.* 2025, doi:10.7150/thno.104474).

Key properties: `side`, `turn`, `version` (parsed automatically from `SeriesID`), plus quantification outputs (`nCells`, `nPosCells`, `density`, `densityTransduced`, `transductionRate`, `density2Dslice`, etc.), populated by `readNintendoResults` from a `.csv` export.

---

## Data flow

A typical processing pipeline (regardless of data type) follows this pattern:

1. **Construct or load the parent `anex`.** If `status_cache`/`enablecache` is on, the constructor attempts to load a previously saved object from the processed-data directory; if off, it initializes fresh from `RawDataDir`.
2. **Register/point at raw data** for the modality being processed (`ABR`, `IC`, `NintendoRes`, etc.) via `setRawDataDir`.
3. **Bulk-initialize sub-objects** from raw data (`allBerabr`, `allIcme`, `listHistImgsRaw` + per-image `histimg` construction). This step reads raw files and creates one sub-object per recording/image.
4. **Manual user input via GUI** — several pieces of metadata cannot be inferred from raw data alone (which hardware/filter was used, which recordings are unusable, which images to keep) and must be entered via the relevant `.mlapp` GUI. This is saved as a separate user-input table (e.g. `ICUserInput_<ExpID>.mat`), not directly onto the sub-objects.
5. **Calibration** — resolves raw hardware output settings (e.g. laser drive %) into physical units (mW), using calibration files matched via the metadata from step 4.
6. **Type-specific processing** — spike extraction (IC), wave filtering (ABR), or straightforward CSV import (histology).
7. **Analysis functions** — operate on individual sub-objects (or lists of them, for cross-animal comparisons via the `multipleAnexFunctions` module) and are the majority of the codebase.
8. **Save.** Every save function empties heavy raw-data fields (`R`) before writing to disk, so that saved objects stay small; raw data is always re-read from the original raw files if needed again.

---

## Caching pattern (`enablecache` / `status_cache`)

See [Coding Conventions](../Developer-Guide/Coding-Conventions.md) for the developer-facing rules for using this pattern correctly in new code. In short: `enablecache`/`status_cache` is a persistent, session-wide switch (not tied to any one object) that governs whether constructors and loader functions attempt to load previously saved results from disk, or force recomputation from raw data.

---

## Processed data folder layout

FEATHER resolves the processed-data folder for one experiment as:

```
<processedDataMap>/<processedDataDirPath>/<userID>data/<ExperimenterID>/f_<ExpID>
```

and raw-data lookups are resolved from:

```
<ukonmap>/<rawDataDir segments...>
```

Within one experiment's processed folder, the file layout is:

```text
f_<ExpID>/
  E_<ExpID>.mat                     # anex object (experiment-level container)
  <ExpID>_kiwi.m                    # notepad file

  B_<ExpID>_<SeriesID>.mat          # berabr objects (ABR)
  W_<ExpID>_<SeriesID>.mat          # detected waves/peaks for the berabr object
  List_ABR_raw.mat                  # cached ABR raw list
  List_ABR.mat                      # cached ABR processed list
  ODui_<ExpID>.mat                  # user input table with all berabr associated info
  *.mat                             # additional anex-wide ABR analysis results (e.g. thresholds)

  List_IC_raw.mat                   # cached IC raw list
  List_IC.mat                       # cached IC processed list
  *.mat                             # additional anex-wide IC analysis results (e.g. thresholds)

  HISTO/
    H_<ExpID>_<SeriesID>.mat        # histimg objects
    List_Hist_raw.mat               # cached histology raw list
    List_Hist.mat                   # cached histology processed list
    HistoRes.mat                    # anex-wide summary of histology results across all cochlea turns
    HistoUserInput_<ExpID>.mat      # user input table with all histimg associated info

  ICME/
    IC/
      IC_<ExpID>_<SeriesID>.mat     # icme objects
    RESORT/
      <ExpID>_<SeriesID>_Resort.txt # extracted multiunit spike-list + metadata, human-readable export
    SR/
      SR_<ExpID>_<SeriesID>_<t_start>_<t_stop>.mat   # cached spike rates for a given time window
    ICUserInput_<ExpID>.mat         # user input table with all icme associated info
    <SeriesID>_tonotopy_res_*.mat   # cached tonotopy analysis results
```

`testSafeDir` is invoked before most save operations to guarantee that none of the above ever gets written into a path containing `archiv` (the raw-data domain).

---
