# FEATHER GUI Documentation

This document explains how to use the GUIs associated with FEATHER.

## `exploreBerabr`

This GUI allows exploration of all available ABR recordings.

![exploreBerabr](exploreBerabr.png)

- The **top-left** panel shows the **ExpID**.
- The **bottom-left** panel lists all available `berabr` objects with their **SeriesID**.
- In this list, you can select a specific ABR recording and inspect it.

Buttons:
- **clickWaves**: Opens `berabrWaveGUI2.mlapp` to select ABR wave peaks.
- **crossCor**: Opens a figure with automatically detected waves and computed cross-correlation between points (ask AV for details).

---

## `berabrWaveGUI2`

This GUI is used to identify the peaks of recorded ABR waves.

![berabrWaveGUI2](berabrWaveGUI2.png)

- In the **top-left area (1)**, all available waves are shown, including:
  - ExpID
  - ABR SeriesID
  - recording type: acoustic (`aABR`) or optical (`oABR`)
  - additional stimulus information

- In the **top-right area (2)**, you can choose individual traces.
  - Left-click a trace to work on it (for example, the 10 mW trace).
  - The selected trace is displayed in the **middle row (3)**.

- In the displayed trace, you can select peaks by clicking the pink **ClickyClicky** bar near the expected peak time.
  - The tool finds the local minimum or maximum timing.
  - You can save this value to the annotation array.

- The **STD3** button (bottom) draws a line at `3 ×` the standard deviation of background activity before trigger.
  - This helps determine whether a feature is still a valid peak.

- The **Inspect** button in area **(5)** opens a detailed inspection window.

⚠️ You must press the green **Accept** button to save selected wave time points before moving to the next intensity level.  
Repeat for all waves where peaks are detectable.

Additional buttons:
- **metricsPlot** (top-right): Quick overview of amplitude and temporal delay changes across stimuli.
- **inverse?** (area 5): Inverts all traces (useful if recording electrodes were swapped during recording).
- **check** (area 3): Prints warnings in the MATLAB console based on your annotations (e.g., peaks below `3 × STD`).
- **extrapolate**: Currently not functional.

---

## `userberabrOD`

This GUI allows adding user input that cannot be automatically read from BERA raw data files, such as applied mechanical optical density filters.

![userberabrOD](userberabrOD.png)

- The **first column** shows the `berabr` SeriesID.
- The **next column(s)** allow manual input of:
  - optical density filters (e.g., for OBIS 594 nm lasers)
  - applied currents, when relevant and not available in the raw input data
