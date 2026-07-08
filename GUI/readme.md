# FEATHER GUI Documentation

This document explains how to use the GUIs associated with FEATHER.

## `exploreBerabr`

This GUI allows exploration of all available ABR recordings.

![exploreBerabr](exploreBerabr.png)

- The **top-left** shows the **ExpID**.
- The **bottom-left**  lists all available `berabr` objects with their **SeriesID**.
- In this list, you can select a specific ABR recording and inspect it.

Buttons:
- **clickWaves**: Opens `berabrWaveGUI2.mlapp` to select ABR wave peaks.
- **crossCor**: Opens a figure with automatically detected waves and computed cross-correlation between points (ask AV for details).

---

## `berabrWaveGUI2`

This GUI is used to identify the peaks of recorded ABR waves.

![berabrWaveGUI2](berabrWaveGUI2.png)

- In the **top-left area (1)**, all available waves are plotted, including:
  - ExpID
  - ABR SeriesID
  - recording type: acoustic (`aABR`) or optical (`oABR`)
  - additional stimulus information

  ⚠️ Keep in mind that the laser intensity values are often not yet calibrated and do not actually show mW values but laser intensity % values despite being labeled as mW.

- In the **top-right area (2)**, you can choose individual traces.
  - Left-click a trace to work on it (for example, the 10 mW trace).
  - To additionally display other traces in the area below **(4)** left click on them while holding the ctr key (here 12 mW and 0 mW are displayed as well).

- The selected trace is displayed in the **middle row (3)**. Here you can select peaks by clicking the pink **ClickyClicky** bar below the peak time.
  - The tool finds the local minimum or maximum timing.
  - You can save this value to the annotation array by clicking on the corresponding field on the right side.
  - If you manually want to add a timepoint use the **Manual Entry** buttom in the area **(5)** after typing the timepoint in the window before clicking  on the timepoints table.
  - The **STD3** button (bottom) draws a line at `3 ×` the standard deviation of background activity before trigger.
    - The **Inspect** button in area **(5)** opens a similar inspection window with the standard deviation.

  ⚠️ You must press the green **Accept** button to save selected wave time points before moving to the next intensity level.  
Repeat for all waves where peaks are detectable.

Additional buttons:
- **RESET?**: Overwrites all timepoints for the selected trace with NaN again.
- **metricsPlot** (top-right): Quick overview of amplitude and temporal delay changes across stimuli.
- **inverse?** (area 5): Inverts all traces (useful if recording electrodes were swapped during recording).
- **check** (area 3): Prints warnings in the MATLAB console based on your annotations (e.g., peaks below `3 × STD`).
- **extrapolate**: Currently not functional.

 ⚠️ To save your annotations you need to press the **EXPORT** button. If you previously worked on the ABR recording you can load your results annotations with the **IMPORT** button.

---

## `userberabrOD`

This GUI allows adding user input that cannot be automatically read from BERA raw data files, such as applied mechanical optical density filters. These inputs are needed to find the correct calibration files so they should reflect what gets saved in the calibration filename. 

![userberabrOD](userberabrOD.png)

- The **first column** shows the `berabr` SeriesID.
- The **ftOD column** allow manual input of inserted mechanical optical density filters (e.g., for OBIS 594 nm lasers) or current values that were set in the bera ini file to change the laser intensity range (eg. for the greem lasers).
- The **hardware** column automatically reads in the laser name. If there are mutliple lasers of the same name you can add e.g. the LaserSerial Nr. or COM Port in here to differentiate.


 ⚠️ To save your annotations you need to press the **EXPORT** button. If you previously worked on the table you can load your results annotations with the **IMPORT** button.

 ## `ICuserInput`
 This GUI allows adding user input to the IC recordings. 
 ![userberabrOD](ICuserInput.png)

 The most important collumns necessary for most ICME functions are:
 
 - The **fSeriesID column** shows the `icme` SeriesID.
 - The **ExpType column** shows the type of experiment via the name of the ExpControl module.
  - The **Filter column** is used to input manually added filters necessary to find the corresponding calibration files. This could be a physical optical density filter (used in eg. OBIS 594nm lasers) or an applied external current/voltage for oxxius lasers to change the intensity range. 
 - The **Laser/oCI ID column** shows the Serial Nr of the Laser or the ID of the used implant.
 - The **COMPort column** shows the setup specific COMPort used to address the laser since this is an identifier saved with the calibration file as well and used to retriee the correct one.
 - The **UseRecording column** can be set to -1 in case a recording did not go well, e.g if it was stopped before the 30 repetitions were done/ there was a lot of unexpected noise etc. These recordings will be skipped in further analysis steps.

 - The **d fiber column** shows the fiber diameter that was used for the stimulation.
 - The **pos cochlea column** describes the position such as RW/base, mid or apex.

 Other collumns that are more for personal notes but not necessary for the analysis
 - The **pos fiber column** can be an increasing number in case more than one prosition was tested for a specific cochlea position.
 - The **orientation column** is for additional notes such as "posterior" or more "lateral" fiber position.


 In the top row you can also choose if the experimental metadata saved already calibrated values or only the laser intensities in %. Usually for new recordings this should be always true. In addition you can save the electrode array name and insertion depth as metadata for the exeriment.
 The **PrefillTable** button reads in all available `icme` objects and the already known metadata from the raw-data ExpInfo.

 ⚠️ To save your annotations you need to press the **Done & EXPORT** button. If you previously worked on the table you can load your results annotations with the **IMPORT** button.


  ## `chooseHistImgToUse`
 This GUI lets us mark if any of the available histology images should not be included in further analysis.
 ![userberabrOD](chooseHistImgToUse.png)

 This table allows to makr individual histology images with -1 in the **Use column** if we do not want to use them in further analysis. Prefill always chooses the last image taken per cochlea side and position.

 ⚠️ To save your annotations you need to press the **Done** button. If you previously worked on the table you can load your results annotations with the **IMPORT** button.