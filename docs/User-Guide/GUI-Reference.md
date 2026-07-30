# GUI Reference

This page documents every GUI (App Designer app) that ships with FEATHER, what each button does, and where its output gets saved. Read the relevant section here before using a GUI for the first time — most GUIs require a specific button to be pressed at the end (e.g. **EXPORT**, **Done**) or your work will not be saved.

## Contents

- [`exploreBerabr`](#exploreberabr)
- [`berabrWaveGUI2`](#berabrwavegui2)
- [`userberabrOD`](#userberabrod)
- [`ICuserInput`](#icuserinput)
- [`chooseHistImgToUse`](#choosehistimgtouse)

---

## `exploreBerabr`

This GUI allows exploration of all available ABR recordings for one animal.

![exploreBerabr](uploads/4e83f0e10f5d283c66acea1103da6c00/exploreBerabr.png){width=232 height=222}
- The **top-left** shows the **ExpID**.
- The **bottom-left** lists all available `berabr` objects with their **SeriesID**.
- Select a specific ABR recording from this list to inspect it.

**Buttons:**
- **clickWaves** — opens `berabrWaveGUI2` to select ABR wave peaks (see below).
- **crossCor** — opens a figure with automatically detected waves and computed cross-correlation between points.
  ⚠️ **NEEDS INPUT FROM MAINTAINERS:** please confirm/expand what this feature is for and when users should use it — the current description just says "ask AV for details."

---

## `berabrWaveGUI2`

This GUI is used to identify the peaks of recorded ABR waves.

![berabrWaveGUI2](uploads/fedba7fa7e32ef8922f5fda876519a02/berabrWaveGUI2.png){width=594 height=600}
- **Area (1), top-left:** all available waves are plotted, including ExpID, ABR SeriesID, recording type (`aABR` acoustic or `oABR` optical), and additional stimulus information.

  ⚠️ Keep in mind that laser intensity values shown here are often **not yet calibrated** — they may show laser drive % rather than actual mW values, despite being labeled "mW".

- **Area (2), top-right:** choose individual traces.
  - Left-click a trace to work on it (e.g. the 10 mW trace).
  - To additionally display other traces alongside it in the plot below **(4)**, hold **Ctrl** and left-click them (e.g. to show 12 mW and 0 mW at the same time as 10 mW).

- **Area (3), middle row:** the selected trace is displayed here. Select peaks by clicking the pink **ClickyClicky** bar below the peak's approximate timing.
  - The tool automatically finds the nearest local minimum or maximum.
  - Save the value to the annotation table by clicking the corresponding field on the right side.
  - To manually add a timepoint instead, type the timepoint into the entry field, then click the **Manual Entry** button in area **(5)**, then click on the timepoints table.
  - The **STD3** button (bottom) draws a line at 3× the standard deviation of background activity before the trigger. The **Inspect** button in area **(5)** opens a similar window showing this standard deviation for closer inspection.

  ⚠️ You **must** press the green **Accept** button to save selected wave timepoints before moving to the next intensity level. Repeat for all waves where peaks are detectable.

**Other buttons:**
- **RESET** — overwrites all timepoints for the currently selected trace back to `NaN`.
- **metricsPlot** (top-right) — quick overview plot of amplitude and latency changes across stimuli.
- **inverse** (area 5) — inverts all traces (useful if recording electrode polarity was swapped during the experiment).
- **check** (area 3) — prints warnings to the MATLAB console based on your current annotations (e.g. peaks below 3×STD).
- **extrapolate** — currently not functional.

⚠️ To save your annotations, you must press the **EXPORT** button. If you previously worked on this ABR recording, load your saved annotations with the **IMPORT** button before continuing.

---

## `userberabrOD`

This GUI allows entering user input that cannot be read automatically from BERA raw data files — most importantly, which optical density filter (or equivalent hardware setting) was applied for each recording. This information must match the naming convention used in the calibration files (see [[ABR Analysis Walkthrough|User-Guide-ABR-Walkthrough]]) so FEATHER can find the right calibration data.

![userberabrOD](uploads/71697c7b921e25fdfb044131713cc1d9/userberabrOD.png){width=419 height=183}

- **First column:** the `berabr` SeriesID.
- **ftOD column:** manually enter the inserted optical density filter (e.g. for OBIS 594 nm lasers) or the current/voltage setting used in the BERA `.ini` file to change the laser intensity range (e.g. for the green lasers).
- **hardware column:** automatically filled with the laser name. If multiple lasers of the same name are in use on your setup, add distinguishing detail here (e.g. laser serial number or COM port).

⚠️ To save your annotations, you must press the **EXPORT** button. If you previously worked on this table, load your saved entries with the **IMPORT** button.

---

## `ICuserInput`

This GUI allows entering user input for IC recordings that FEATHER cannot read automatically from the raw data.

![ICuserInput](uploads/13b70cbc4780fbb1ee89a3b84b6522d4/ICuserInput.png){width=788 height=289}

The columns most important for the majority of `icme` analysis functions are:

| Column | Description |
|---|---|
| **SeriesID** | The `icme` SeriesID. |
| **ExpType** | The type of experiment, taken from the ExpControl module name. |
| **Filter** | Manually entered filter/current/voltage setting needed to find the matching calibration file (e.g. a physical optical density filter for OBIS 594 nm lasers, or an applied external current/voltage for Oxxius lasers). |
| **Laser/oCI ID** | Serial number of the laser, or the ID of the implant used. |
| **COMPort** | The setup-specific COM port used to address the laser — also saved with the calibration file, and used to match recordings to the correct calibration. |
| **UseRecording** | Set to `-1` if a recording should be excluded from further analysis (e.g. stopped early, excessive noise). Excluded recordings are skipped by downstream analysis functions. |
| **d fiber** | Fiber diameter used for stimulation. |
| **pos cochlea** | Cochlear position — e.g. round window/base, mid, or apex. |

Additional columns for personal notes (not required for analysis):

| Column | Description |
|---|---|
| **pos fiber** | An incrementing number if more than one fiber position was tested for the same cochlear position. |
| **orientation** | Free-text notes, e.g. "posterior" or "more lateral" fiber placement. |

In the top row, you can also specify whether the experimental metadata already contains calibrated intensity values or only laser drive percentages (for new recordings this should generally be `true`), and record the electrode array name and insertion depth as metadata for the experiment.

**Buttons:**
- **PrefillTable** — reads in all available `icme` objects and pre-fills known metadata from the raw-data `ExpInfo`.
- **Done & EXPORT** — saves your entries. ⚠️ You must press this button for your work to be saved.
- **IMPORT** — loads previously saved entries if you're returning to this table.

---

## `chooseHistImgToUse`

This GUI lets you mark whether any available histology images should be excluded from further analysis.

![chooseHistImgToUse](uploads/8e68e688b61f8e8bb8d0fde79bbc918b/chooseHistImgToUse.png){width=481 height=384}

- Mark any image you do **not** want included in further analysis with `-1` in the **Use** column.
- **Prefill** automatically selects the most recently taken image per cochlea side/position as a starting point.

⚠️ To save your annotations, you must press the **Done** button. If you previously worked on this table, load your saved entries with the **IMPORT** button.

---

## What's next

- [[ABR Analysis Walkthrough|User-Guide-ABR-Walkthrough]]
- [[IC Analysis Walkthrough|User-Guide-IC-Walkthrough]]
- [[Histology Analysis Walkthrough|User-Guide-Histology-Walkthrough]]
- [[FAQ / Troubleshooting|User-Guide-FAQ]]