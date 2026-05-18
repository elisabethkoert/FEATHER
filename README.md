# FEATHER
FEATHER: a Framework for Experimental Analysis of Tissue and Electrophysiology for Heterogeneous Experiments and Researchers

This project is a MATLAB toolbox developed in the Institute for Auditory Neuroscience to process the various types of data generated in connection to an animal experiment in the institute from *in-vivo* electrophysiology recordings to results from immunohistochemical analysis of cochlea tissue. The current version only works with the institute specific data types, but future releases should try to include more open source and standardized data formats.

## Authors
The toolbox framework was set up by Anna Vavakou. Elisabeth Koert and Niels Albrecht joined as developers. Elisabeth Koert created this public version from the institues private code.

# Affiliation
Institute for Auditory Neuroscience  
University Medical Center Goettingen <br>
Robert-Koch-Str. 40<br>
37075 Goettingen<br>
Germany

---

# Toolbox Overview
FEATHER is organized around a few core object types that cover the full workflow surrounding one animal experiment. GUIs allow interaction with the objects to add necessary manual user input for each experiment.

### `anex` (animal-experiment object)
`anex` is the central container for one animal experiment.  
It links metadata (experiment ID, species, experimenter/user) with raw and processed data directories, and gives an overview of which recordings and analyses are available for that experiment.

At this level, FEATHER enables:
- organizing and loading experiment data consistently,
- listing available ABR, IC, and histology datasets,
- launching standard experiment-wide analyses (e.g., threshold determination across all IC or ABR recordings, summarizing histology results from all image sets).

## Objects that can be associated to an anex

### `berabr` (Auditory Brainstem Response object)
`berabr` represents one auditory brainstem response (ABR) measurement recorded with the BERA custom MATLAB software used in the IAN. 
It stores raw traces, processed FEATHER traces, stimulus information, the raw data directory, and optional calibration information.

At this level, FEATHER enables:
- ABR preprocessing, and quality handling,
- threshold extraction and waveform-based metrics,
- ABR-specific plotting and calibration-aware interpretation.

### associated GUIs for manual user input
`exploreBerabr.mlapp` together with `berabrWaveGUI2.mlapp` allow for the manual inspection of all berabr traces associated to an anex and to detect and store the peaks for the different stimuli and recordings.

`userberabrOD.mlapp` requests user input on the used hardware and optical density filters used for each berabr associated to an anex which is necessary for correctly reading in calibration files.

### `icme` (inferior colliculus multielectrode recording object)
`icme` represents one inferior-colliculus multielectrode recording.
It currently handles data recorded using a 32 channel-NeuroNexus probe
and Cheetah recording software.
Stimuli are generated with the custom MATLAB software ExpControl used at the IAN.
It contains recording metadata, stimulus definitions and calibration values,
the raw data directory, and the spike-list with multi-unit activity extracted
from raw data for downstream analysis.

At this level, FEATHER enables:
- extraction/import of multi-unit spike data,
- response analysis (spike rate, PSTH, d-prime, temporal precision, spread of excitation, tonotopy),
- generation of standard IC visualizations for individual recordings (heatmaps, raster-plot, PSTH).

### associated GUIs for manual user input
`ICuserInput.mlapp` requests user input on the used hardware and optical density filters, recording quality as well as stimulation positions within the cochlea used for each icme associated to an anex.  



### `histimg` (histology image object)
`histimg` represents the results obtained from one histology image set (typically one cochlear region / turn).  
It stores image metadata and loads quantified outputs (such as cell counts, volumes, densities, and transduction rate) from our custom made, Arivis based histology analysis pipeline that runs on confocal cochlea images (described in Thirumalai _et al._ 2025 doi:10.7150/thno.104474).

At this level, FEATHER enables:
- importing histology quantification results from standardized .csv sheets

### associated GUIs for manual user input
`chooseHistImgToUse.mlapp` requests user input to define which histimg should be used when analysing across the full anex in case multiple images have been obtained from the same region.  

## Surrounding Utility Modules

### `dirManagement`
Helper functions for:
- consistent path generation,
- processed-data folder management,
- cache state handling,
- safety checks to avoid writing into raw/archive domains.

### `plotFunctions`
Reusable plotting helpers used across ABR, IC, and summary analyses to create for quickly visualizing results.

### `multipleAnexFunctions`
Cross-experiment helper functions for pooling results from multiple animals (for example, pooled PSTH-style analyses across multiple `anex` objects).

## Directory Management and Processed Data Layout

As basic infrastructure, FEATHER needs three path settings in the MATLAB session (example initialization shown in the testingScripts):
- **Raw data map/drive** via `ukonmap` (base mapping used for raw directories).
- **Processed data map/drive** via `processedDataMap`.
- **Processed data base directory** via `processedDataDirPath`.

For a given experiment, FEATHER resolves the processed experiment folder as:

`<processedDataMap>/<processedDataDirPath>/<userID>/data/<ExperimenterID>/f_<ExpID>`

and raw-data lookups are resolved from:

`<ukonmap>/<rawDataDir segments...>`

When an `anex` is initialized, FEATHER creates the processed data folder for this animal experiment and stores the `anex` object there as:
- `E_<ExpID>.mat`
  
For adding analysis-specific comments a KIWI file can be created using `initKiwi(anex)` that serves as a notepad.

As additional objects are created/processed, files are stored in a consistent structure:

```text
f_<ExpID>/
  E_<ExpID>.mat                     # anex object (experiment-level container)
  <ExpID>_kiwi.m                    # notepad file

  B_<ExpID>_<SeriesID>.mat          # berabr objects (ABR)
  W_<ExpID>_<SeriesID>.mat          # detected waves/ peaks for the berabr object
  List_ABR_raw.mat                  # cached ABR raw list
  List_ABR.mat                      # cached ABR processed list
  ODui_<ExpID>.mat                  # user input table with all berabr associated info
  *.mat                             # additional anex wide ABR analysis results (eg. thresholds)

  List_IC_raw.mat                   # cached IC raw list
  List_IC.mat                       # cached IC processed list
  *.mat                             # additional anex wide IC analysis results  (eg. thresholds)



  HISTO/
    H_<ExpID>_<SeriesID>.mat        # histimg objects
    List_Hist_raw.mat               # cached histology raw list
    List_Hist.mat                   # cached histology processed list
    HistoRes.mat                    # anex wide summary of the histology results across all cochlea turns
    HistoUserInput_<ExpID>.mat      # user input table with all histimg associated info

  ICME/
    IC/
      IC_<ExpID>_<SeriesID>.mat     # icme objects
    RESORT/
      <ExpID>_<SeriesID>_Resort.txt # files containing the metadata, analysis parameters and extracted multiunit activity as the spike-list in a more standardized and easy read in format (if generated)
    SR/
      SR_<ExpID>_<SeriesID>_<t_start>_<t_stop>.mat    # calculated spike rates in specific time windows that can be loaded to avoid recalculating every time (if generated)
  ICUserInput_<ExpID>.mat           # user input table with all icme associated info
  <SeriesID>_tonotopy_res_*.mat     # tonotopy results for acoustic recordings with different analysis methods indicated at the *
```
