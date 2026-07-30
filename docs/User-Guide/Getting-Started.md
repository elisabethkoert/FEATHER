---
title: Getting Started
---
# Getting Started: Installation & Toolbox Setup

This page walks you through getting FEATHER running on your computer for the first time. It assumes you have already followed [Getting Started with Git](./Git-Basics.md) and have a local copy of the `invivoEphysFEATHER` repository on your computer.

---

## What you need before starting

- **MATLAB** installed on your computer. The toolbox has been tested on MATLAB 2021a/b and 2022a/b but should also work with newer versions. 
- Access to the network drives where **raw data** and **processed data** are stored (for IAN members, this is the `UKON100` drive — ask a labmate or supervisor for access if you don't have it yet).
- A local clone of the FEATHER repository (see [Getting Started with Git](./Git-Basics.md)).
- If you will be analysing IC (inferior colliculus) recordings: the Neuralynx MATLAB import tools (`Nlx2MatCSC`, `Nlx2MatEV`). A compatible version is bundled in `FEATHER/cheetah/` and should already be on your path once you add the toolbox as described below. In that case you also need a computer with at least 32 GB RAM otherwise you will run into memory issues when extracting multi-unit spikes from raw data for recordings that are longer than 10 min. 

---

## Step 1: Use the example startup script

FEATHER ships with a ready-to-use startup script at exampleScripts\startup.m


This script adds the toolbox to your MATLAB path and configures where FEATHER should look for raw data and where it should save processed data.

**To use it:**

1. Copy `exampleScripts/startup.m` somewhere convenient (e.g. your own personal scripts folder — do not edit the copy inside the toolbox repository itself).
2. Open your copy and edit the paths at the top so they point to:
   - the location of your local FEATHER toolbox clone (`tb_path`),
   - your raw-data drive (`ukonmap`),
   - your processed-data drive (`processedDataMap`),
   - your initials (`userID`).
3. Run this script at the start of every MATLAB session where you want to use FEATHER.

The script also sets `enablecache('on')`. Leave this as `'on'` for normal day-to-day use. See [How FEATHER Works (Big Picture)](./How-FEATHER-Works.md) for what this setting actually does before changing it.

### Running entirely on your own computer (no network drive)

If you want to try FEATHER without access to the institute network drives (e.g. to test on a local example dataset), see `exampleScripts/ExampleProcessingLocalData.m` for a version of the startup steps that points `ukonmap`,'processedDataMap' and `processedDataDirPath` at local folders instead of network drives.

---

## Step 2: Run your startup script

Every time you open MATLAB to work on FEATHER, run your startup script first using the green run arrow in the editor menu or via the matlab Command Window:

```matlab
run('C:\path\to\your\startup.m')
