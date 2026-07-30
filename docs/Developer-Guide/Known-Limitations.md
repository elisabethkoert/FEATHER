# Known Limitations / Stub Classes

This page documents parts of the FEATHER codebase that are early-stage, incomplete, or otherwise not fully implemented, so that future developers don't spend time trying to use them as if they were finished features, and don't assume something is broken when it's actually just unfinished by design.

If you fix or complete any of the items below, please update this page (and remove the relevant entry) as part of that work.

---




## Superseded / duplicate analysis functions (multiple versions kept in parallel)

Several `icme` analysis functions exist in multiple versions side-by-side, without a clear marker of which is "current":

- **Spread of excitation (SoE):** `calculateSOE.m`, `calculateSOEMultipleStimVars.m`, `calculateSOEContourlinesMultipleStimVars.m`, `calculateSOEContourlinesMultipleStimVarsAtBE.m`, `calculateSOE_dieter2019.m`, `calculateSOEwithoutBE_dieter2019.m`, and a file literally named `calculateSOEOldWay - Copy.m` (including the `" - Copy"` suffix and spaces in the filename, which is unusual for MATLAB function files and may cause issues on case-sensitive filesystems or with certain path tools).
- **Spike extraction from raw Neuralynx data:** `generateSLfromRawNlxData.m`, `generateSLfromRawNlxData_BackgroundNoise.m`, `generateSLfromRawNlxData_baseline_global.m` (itself present as two near-duplicate files, one titled `... - Copy.m`), plus `evaluateDataAndSpikes.m` and `evaluateDataAndSpikes_EK.m`, which overlap significantly in purpose. The `icme.ExtractMUAfromRawDataIntoSL` method currently calls `generateSLfromRawNlxData_baseline_global`, but comments in the same file show it previously called `generateSLfromRawNlxData_BackgroundNoise`, suggesting active, recent iteration on which version is "correct."


⚠️ **NEEDS INPUT FROM MAINTAINERS:** for each group above, please confirm which function is the current recommended one so this can be stated explicitly in [IC Analysis Walkthrough](../User-Guide/IC-Walkthrough.md) and [How to Add a New IC Experiment/Protocol Type](./Adding-New-Experiment-Type.md), and whether the older/duplicate versions can be deleted or should be kept for reproducing old published analyses (in which case, consider clearly marking them as archival, e.g. moving them to an explicitly named `legacy/` folder).

---

## `ABRMaxWaveValues` — acoustic modality not yet supported

The function's own header comment states:

> `% StimModality (string): sitmulus modality ('Optical', 'Acoustic') % does not yet work for acoustic!`

This is already noted in [ABR Analysis Walkthrough|User-Guide-ABR-Walkthrough.md) as a user-facing caveat; listed here as well so it isn't lost when this function is eventually fixed.

---

## `getExperimenterFromExpID.m` — hardcoded experimenter mapping

This helper function hardcodes a lookup from `ExpID` naming prefixes to specific experimenter initials (e.g. anything containing `'gjg'` maps to `'JG'`, `'GEK'` maps to `'EK'`, etc.), with a fallback that assumes the experimenter's initials are always characters 2–3 of the `ExpID`.

⚠️ **NEEDS INPUT FROM MAINTAINERS:** this will silently misattribute experiments for any new experimenter whose initials don't follow the assumed 2-character convention, or whose `ExpID` prefix isn't already listed. Please confirm whether this function is still actively relied upon (vs. `ExperimenterID` simply being passed explicitly everywhere it matters), and whether it should be updated when new lab members join.

---
