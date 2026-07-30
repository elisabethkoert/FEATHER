# FEATHER NWB Interface

This subfolder contains the scripts neccessary for exporting and loading FEATHER experiment data in the Neurodata Without Borders (NWB) format (in addition to the object specific functions to load from the NWB format in the icme, berabr and histimg subfolders)

## Overview

Neurodata without borders (https://nwb.org/) is a data standard and software ecosystem for sharing neurophysiology data.  To use it with Matlab it is necessary to pull the MATNWB toolbox as described here (https://nwb.org/matnwb/). For the development of these functions we used the version 2.9.0.

The NWB interface together with the functions in this folder allows users to convert `anex` (animal experiment) objects and their associated data (`berabr`, `icme`, `histimg`) into a standardized `.nwb` file. This facilitates data sharing, archiving, and analysis with external tools that support the NWB standard.

The export process is broken down into modular functions, allowing users to export only specific modalities (ABR, IC, Histology) or even only specific subsets of recordings (by SeriesID).

## File Structure

### Export Functions
*   **`exportFeatherToNWB.m`** (Main Entry Point)
    *   The primary function to call. It handles input parsing, initializes the NWB file, and orchestrates the sub-functions.
*   **`initNWBFile.m`**
    *   Creates the `NwbFile` object and populates session-level metadata (Subject, Lab, Session Start Time).
*   **`setupElectrodes.m`**
    *   Constructs the unified electrode table (combining ABR needle electrodes and IC MEA contacts) required by the NWB standard.
*   **`exportABRtoNWB.m`**
    *   Handles the export of Auditory Brainstem Response (ABR) data, including waveforms, stimulus parameters, and wave-peak annotations.
*   **`exportICtoNWB.m`**
    *   Handles the export of Inferior Colliculus (IC) data, including spike times (Units table), stimulus lists, and analysis parameters.
*   **`exportHistoToNWB.m`**
    *   Handles the export of Histology quantification results (cell counts, densities, etc.).
*   **`exportAnnotationsToNWB.m`**
    *   Bundles manual user inputs (ICUserInput, HistoUserInput, ODui) and ABR wave annotations into a dedicated processing module. Supports filtering to match exported subsets.

### Import Functions
*   **`createFeatherObjectsFromNWB.m`** (Main Entry Point)
    *   Reconstructs FEATHER objects (`anex`, `berabr`, `icme`, `histimg`) from an NWB file. It handles the reverse mapping of NWB tables back into FEATHER structs and saves them to the processed data directory.

### Utilities
*   **`printAllNWBTables.m`**
    *   A utility function to print all tables contained within an NWB object to the console for sanity checking.

## Dependencies

*   **MATLAB** (R2016b or later recommended)
*   **FEATHER Toolbox**: The core FEATHER objects (`anex`, `berabr`, `icme`, `histimg`) must be on the MATLAB path.
*   **MatNWB**: The official MATLAB interface for NWB. Ensure it is installed and added to the path.
    *   *Installation:* download from the [MatNWB GitHub](https://github.com/NeurodataWithoutBorders/matnwb) and add to the matlab path

## Usage

There is an example script *exportDataNWBformat.m* on how to export and load data in the exampleScripts folder.


## Part 1: Exporting FEATHER to NWB

### Basic Export (All Data)

To export all available ABR, IC, and Histology data for an experiment:

```matlab
% 1. Load the FEATHER experiment
ExpID = 'GEK030';
experimenterID = 'EK';
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);

% 2. Run the export
nwb = exportFeatherToNWB(ee);
```

By default, this creates a file named `<ExpID>.nwb` in the current directory.

### Selective Export (Specific Modalities)

You can toggle specific data types on or off using Name-Value arguments:

```matlab
% Export only ABR and Histology, skip IC
nwb = exportFeatherToNWB(ee, ...
    'exportIC', false, ...
    'exportABR', true, ...
    'exportHisto', true);
```

### Subset Export (Specific SeriesIDs)

To export only specific recordings (e.g., only one ABR session or specific IC recordings), provide a list of SeriesIDs:

```matlab
% Export only specific ABR recordings
targetABRs = {'2023-01-01_10-00-00_BERA', '2023-01-01_11-00-00_BERA'};

% Export only specific IC recordings
targetICs = {'GEK030_0001', 'GEK030_0005'};

nwb = exportFeatherToNWB(ee, ...
    'abrSeriesIDs', targetABRs, ...
    'icSeriesIDs', targetICs);
```

**Note:** When exporting subsets, the associated user input tables (e.g., `ODui`, `ICUserInput`) are automatically filtered to include only the rows relevant to the exported SeriesIDs.

### Custom Output Location

To specify a custom output directory or filename:

```matlab
nwb = exportFeatherToNWB(ee, ...
    'outputDir', 'C:\MyData\NWB_Exports', ...
    'filename', 'Experiment_031_Converted.nwb');
```

---

## Part 2: Importing NWB to FEATHER

The `createFeatherObjectsFromNWB` function reads an `.nwb` file and reconstructs the corresponding FEATHER files (`.mat` files) in your processed data directory.

### Basic Import

To import all data from an NWB file back into FEATHER:

```matlab
% Define the NWB file location
nwbFilename = 'GEK030.nwb';
nwbDir = 'C:\MyData\NWB_Exports';

% Run the import
% This will create E_GEK030.mat, B_*.mat, IC_*.mat, etc. in the processed data folder
ee = createFeatherObjectsFromNWB(nwbFilename, nwbDir);
```

### Selective Import

You can choose to import only specific modalities:

```matlab
% Import only ABR and Histology, skip IC
ee = createFeatherObjectsFromNWB(nwbFilename, nwbDir, ...
    'importIC', false, ...
    'importABR', true, ...
    'importHisto', true);
```

### Overwrite Protection

By default, the importer will throw an error if FEATHER files (e.g., `E_GEK030.mat`) already exist in the target directory to prevent accidental data loss. To force overwriting:

```matlab
ee = createFeatherObjectsFromNWB(nwbFilename, nwbDir, ...
    'overwrite', true);
```

---

## Verification

After exporting, you can inspect the contents of the NWB file using the provided utility:

```matlab
% Print all tables to the console
printAllNWBTables(nwb);
```

This will display:
*   Electrode configurations
*   Stimulus tables
*   Units (spike) summaries
*   Histology results
*   User input annotations

## NWB File Structure

The generated NWB file organizes data as follows:

*   **`/general/extracellular_ephys/electrodes`**: Combined table of ABR and IC electrodes.
*   **`/processing/abr`**: Contains `ElectricalSeries` (waveforms) and stimulus tables for ABR.
*   **`/processing/ic_metadata`**: Contains IC stimulus lists and analysis parameters.
*   **`/units`**: The standard NWB table for IC multi-unit activity (spike times).
*   **`/processing/histology`**: Contains histology quantification results.
*   **`/processing/feather_annotations`**: Contains copies of manual user inputs (ICUserInput, HistoUserInput, ODui) and ABR wave-peak annotations.

