---
title: Adding New Stimulus Type for IC
---
# How to Add a New IC Stimulus Protocol Type

This page explains how a new **IC** stimulation protocol — i.e. a new ExpControl module producing a new `exp_type` string — gets integrated into FEATHER's analysis functions. It assumes you already have a working ExpControl module that produces a `.m` log file with a `stimlist`, and focuses on what FEATHER-side changes are needed to make that new protocol analyzable.

> **Note on ABR/single-unit recordings:** this page applies to `icme` (IC) recordings only. `berabr` (ABR)  recordings do not have an equivalent "registered protocol type" concept — their `Stim.protocol` field (`'I'`/`'D'`/`'R'`/`' '`) is auto-detected from which single stimulus parameter varies across traces, so a new ABR/single-unit stimulation paradigm generally works automatically without any new registration step. If you're adding a new **hardware device** for ABR/single-unit/IC recordings instead, see [[How to Add Support for New Laser/Stimulus Hardware|Developer-Guide-Adding-New-Hardware]].

---

## Background: what defines a "protocol type" in FEATHER

For `icme` objects, everything about a protocol's stimuli is captured in four fields, all copied directly from the ExpControl `.m` log file when `loadLogFileInfo`/`stim` runs:

| Field | Description |
|---|---|
| `Stim.exp_type` | String identifying the protocol, e.g. `'MX_tones'`, `'OBIS_LS594_PulseTrain_Attenuation'`, `'OBIS_LS594_PulseTrain_f_train'` |
| `Stim.stimlist` | Matrix where each **row** is one stimulus condition, and each **column** is a stimulus parameter |
| `Stim.stimheader` | Cell array of column names describing `stimlist`'s columns |
| `Stim.dura`, `Stim.n_rep` | Stimulus duration and number of repetitions per condition |

FEATHER's generic analysis functions (`calculateSpikeRate`, `calculateDprime`, `calculateDprimeMultipleStimVars`, `calculatePSTH`, `plotHeatmapsIC`, etc.) don't know anything about specific protocols — they operate purely on `stimlist`/`stimheader` via the `stim_criteria_array` filtering mechanism (see [[Architecture Overview|Developer-Guide-Architecture-Overview]]). This means **most new protocols require no changes to these generic functions at all** — as long as your `stimlist` follows the expected row/column convention, existing functions will work immediately.

You only need to write new code when:
1. Your protocol needs **calibration handling** that doesn't fit the existing `getCalibration`/`calculateCalibration` branches (see below), or
2. Your protocol needs a **specialized analysis** that doesn't reduce to filtering + spike rate/d′ on a `stim_criteria_array` (e.g. tonotopy's `calculateTonotopicSlope`, or artefact-removal logic keyed on `exp_type` in `calculatePSTH`), or
3. You need the protocol recognised correctly in the `ICuserInput` GUI / user-input-driven filtering used by cross-recording functions like `intensityThresholdIC`.

---

## Step-by-step: integrating a new protocol type

### Step a) Confirm your `stimlist`/`stimheader` follow convention

Before writing any FEATHER code, load your new recording and inspect the raw structure:

```matlab
enablecache off
IC = loadLogFileInfo(icme(ee, SeriesID, D));
IC.Stim.exp_type
IC.Stim.stimheader
IC.Stim.stimlist
```

Check that:
- `stimlist` has one row per stimulus condition, in the same order/count as `n_rep` expects,
- `stimheader` has exactly as many entries as `stimlist` has columns,
- numeric values are actually numeric (not cells) — if your ExpControl module produces a cell array for `stimlist` (as some older LED protocols do), make sure `icme.m`'s existing cell-to-double conversion logic (in `loadLogFileInfo`/`stim`) actually succeeds for your data; if it doesn't, you may need to extend that conversion block.

If this all looks correct, most generic analysis functions will already work on this recording using an appropriate `stim_criteria_array` — try this before writing anything new:

```matlab
stim_criteria_array = [1, 0, 100];  % example: use column 1, any value 0-100
[meanSpikeRates, ~] = calculateSpikeRate(IC, 0, 50);
```

### Step b) Add calibration handling, if your protocol uses optical/electrical stimuli

`getCalibration.m` and `calculateCalibration.m` both currently gate calibration logic on `IC.Stim.exp_type` using `contains(...)` checks, e.g.:

```matlab
if contains(IC.Stim.exp_type,'OBIS') || contains(IC.Stim.exp_type,'OXXIUS') || contains(IC.Stim.exp_type,'DarkRedLaser')
    ...
elseif contains(IC.Stim.exp_type,'SBcreeLED10x1')
    ...
end
```

If your new protocol's `exp_type` doesn't match any existing branch and it involves a calibrated stimulus (laser power, LED current, etc.), add a new `elseif` branch following the pattern of an existing one that's structurally similar (e.g. copy the `OBIS`/`OXXIUS` branch if your protocol is also a single-laser power-controlled stimulus).

If your protocol is **acoustic** (like `MX_tones`), no calibration branch is needed — acoustic stimuli are assumed already calibrated by the stimulation software, and `stimlistCal` is just set equal to `stimlist`:

```matlab
elseif contains(UT.data{ii,find(contains(UT.fieldNames,'ExpType'))},'MX')
    IC.C(1).stimlistCal = IC.Stim.stimlist;
    IC.C(1).impossibleStimuli = [];
```

### Step c) Register the protocol in `ICuserInput`

The `ICuserInput.mlapp` GUI's **ExpType** column is populated from each recording's `Stim.exp_type` automatically (via `PrefillTable`) — you don't need to modify the GUI itself for a new protocol to show up there. However, several analysis functions filter *across* recordings by matching against an expected `ExpType` substring, for example:

```matlab
function [ExpIntThr] = intensityThresholdIC(ee, dPrimeMode, ExpType, ...)
...
if ~exist('ExpType','var')
   ExpType = {'PulseTrain_Attenuation'};
end
```

If you want your new protocol type to be picked up by a cross-recording function like `intensityThresholdIC`, either:
- pass your `exp_type` string explicitly as the `ExpType` argument when calling the function, or
- if you want it included in default behavior for everyone, discuss changing the function's default with a maintainer, since changing defaults affects all existing callers.

### Step d) Add specialized analysis code, if needed

If your protocol requires genuinely new analysis logic (not just spike-rate/d′ filtering), write it as a new function following the conventions in [[Coding Conventions|Developer-Guide-Coding-Conventions]]:

- Put it in `@icme/` if it operates on a single `icme` object.
- Follow the `stim_criteria_array` convention for stimulus filtering if at all applicable, even if the rest of the function is bespoke — this keeps the calling convention consistent with the rest of the toolbox.
- If your function needs to special-case behavior based on protocol type (the way `calculatePSTH` does for artefact removal, checking `contains(IC.ExpInfo.exp_type,'f_train')` vs `'eCI'` vs default), add a new branch there rather than writing a fully separate function, if the rest of the logic is otherwise shared.

As a concrete existing example of a protocol needing bespoke analysis, look at how the tonotopy protocol (`MX_tones`) is handled: `calculateTonotopicSlope.m` and `calculateTonotopicSlopeSortedbyElectrode.m` both start with an explicit guard:

```matlab
if ~strcmp(obj.Stim.exp_type,'MX_tones')
    ...
    disp('tontotopy slope calculation called for a non tontotopy script!!!')
    return
end
```

If you're writing an analysis that only makes sense for your new protocol type, add a similar guard so it fails clearly (rather than silently producing meaningless output) if accidentally called on the wrong data.

### Step e) Test using the example scripts as templates

`exampleScripts/processing_new_IC_data.m` contains four fully worked examples (pulse intensity, tonotopy, repetition-rate, pulse-duration protocols) that each demonstrate the standard analysis sequence for a protocol type. Use whichever is structurally closest to your new protocol as a template, and confirm:

1. `allIcme(ee)` correctly reads your new protocol's log file and populates `Stim.exp_type`/`stimlist`/`stimheader`.
2. `ICuserInput` correctly displays your new `ExpType`.
3. Calibration (Step b) produces sensible `IC.C.stimlistCal` values.
4. Your chosen `stim_criteria_array` filters produce the expected subset of stimuli when tested with `getStimuliFromStimCriteriaArray`.
5. Any generic or bespoke analysis functions run without errors and produce plausible results.

---
