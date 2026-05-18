# FEATHER
FEATHER: a Framework for Experimental Analysis of Tissue and Electrophysiology for Heterogeneous Experiments and Researchers

This project is a toolbox developed for the institute for auditory neuroscience to process the various types of data generated in connection to an animal experiment in the institute from *in-vivo* electrophysiology recordings to results from immunohistochemical analysis of tissue.

## Authors
Tht toolbox framework was set up by Anna Vavakou. Elisabeth Koert and Niels Albrecht joined as developers. Elisabeth Koert created this public version from the institues private code in connection to the publication XXX.

# Affiliation
Institute for Auditory Neuroscience  
University Medical Center Goettingen <br>
Robert-Koch_Str. 40<br>
37075 Goettingen<br>
Germany

---

# Toolbox Overview

FEATHER is organized around a few core object types that cover the full workflow from experiment organization to signal and tissue analysis.

## Core Objects

### `anex` (experiment-level object)
`anex` is the central container for one animal experiment.  
It links metadata (experiment ID, species, experimenter/user) with raw and processed data directories, and gives an overview of which recordings and analyses are available for that experiment.

At this level, FEATHER enables:
- organizing and loading experiment data consistently,
- listing available ABR, IC, SU, and histology datasets,
- launching standard experiment-wide analyses (e.g., thresholds, dynamic range, overview metrics).

### `berabr` (ABR-level object)
`berabr` represents one ABR measurement series recorded with the BERA setup.  
It stores raw traces, processed FEATHER traces, stimulus information, and optional calibration information.

At this level, FEATHER enables:
- ABR preprocessing and quality handling,
- threshold extraction and waveform-based metrics,
- ABR-specific plotting and calibration-aware interpretation.

### `icme` (IC multielectrode recording object)
`icme` represents one inferior-colliculus multielectrode recording session.  
It combines recording metadata, stimulus definitions, spike lists, calibration, and downstream analysis results.

At this level, FEATHER enables:
- extraction/import of multi-unit spike data,
- response analysis (spike rate, evoked rate, PSTH, d-prime, vector strength),
- spatial/functional analyses (spread of excitation, tonotopy),
- generation of standard IC visualizations (heatmaps, raster/PSTH-style views).

### `histimg` (histology image object)
`histimg` represents one histology image set (typically one cochlear region / turn).  
It stores image metadata and quantified Nintendo analysis outputs such as cell counts, volumes, densities, and transduction rates.

At this level, FEATHER enables:
- importing standardized histology quantification results,
- comparing density/transduction metrics across turns/sides/experiments,
- integrating histology results with electrophysiology outcomes via the shared `anex` structure.

## Surrounding Utility Modules

### `dirManagement`
Helper functions for:
- consistent path generation,
- processed-data folder management,
- cache state handling,
- safety checks to avoid writing into raw/archive domains.

### `plotFunctions`
Reusable plotting helpers used across ABR, IC, and summary analyses to create publication-style figures and standardized visualization outputs.

### `multipleAnexFunctions`
Cross-experiment helper functions for population-level analyses (for example, pooled PSTH-style analyses across multiple `anex` objects).
