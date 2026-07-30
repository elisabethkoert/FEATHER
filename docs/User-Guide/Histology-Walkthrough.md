# Histology Analysis Walkthrough

This page walks you through analysing cochlear histology data for one animal experiment. FEATHER currently supports two histology pipelines:

- **Confocal histology** (40x objective, Arivis-based "Nintendo" analysis pipeline) — represented by `histimg` objects. This pipeline is complete and ready to use.

It assumes you have already completed [Getting Started – Installation & Toolbox Setup](./Getting-Started.md) and read [How FEATHER Works (Big Picture)](./How-FEATHER-Works.md), and that you already have an `anex` for your animal (usually created during ABR analysis — see [ABR Analysis Walkthrough](./ABR-Walkthrough.md)).

---

## Confocal Histology (`histimg`)

A full working example of everything in this section is available in the toolbox at:

```
exampleScripts/processing_new_confocalHisto_data.m
```

It's worth keeping that script open alongside this page — it's a runnable version of the steps below.

Each analysed image set (typically one cochlear turn from one side) is represented by a `histimg` object. All `histimg` objects for one animal live inside that animal's `anex`.

### Before you start

You will need:

- An existing `anex` for your animal.
- The **raw data folder path** containing the `.csv` result files exported from the confocal/Arivis ("Nintendo") analysis pipeline.
- Filenames of these `.csv` files must include the experiment ID (or the animal number) so FEATHER can associate them with the right animal — see the [GUI Reference](./GUI-Reference.md) page and the developer-level `histimg` documentation for the exact naming convention if you run into matching problems.

### Step 1: Load your `anex` and register the histology raw data folder

```matlab
ExpID = 'GEK030';
experimenterID = 'test';
enablecache on
ee = anex(ExpID, experimenterID);
ee = loadAnex(ee);

% register the histology raw data directory
D_cur = ee.RawDataDir;
histoDir = ["archiv","systems","AllDataTypesForAnalysisTests","GEK030","Histo"];
ix = find(strcmp([D_cur.type],'NintendoRes'));
if ~isempty(ix)
    D_cur(ix).dir = histoDir;
else
    D_cur(end+1).dir = histoDir;
    D_cur(end).type = "NintendoRes";
end
ee = setRawDataDir(ee, D_cur);
saveAnex(ee);

enablecache off
initHistoFolder(ee)   % creates the HISTO subfolder in your results folder
```

### Step 2: Import the analysis results for each image set

This reads every matching `.csv` result file and creates the corresponding `histimg` objects:

```matlab
enablecache off
HistImgsRaw = listHistImgsRaw(ee);
list_cochleae_pos = HistImgsRaw.HistImg_SeriesID;
NintendoRes_ix = find([ee.RawDataDir.type] == "NintendoRes");
D_Nintendo = ee.RawDataDir(NintendoRes_ix);

for img_ix = 1:length(list_cochleae_pos)
    histImg = histimg(ee, string(list_cochleae_pos(img_ix)), D_Nintendo, HistImgsRaw.Filenames{img_ix});
    [histImg, check] = readNintendoResults(histImg);
    if check == 1
        saveHistimg(histImg);
    end
end
```

If `check` comes back as `0` for a given image, it means FEATHER could not read the expected columns from that `.csv` file — double check the file matches the naming and column conventions described in the developer-level `histimg` documentation.

### Step 3: Choose which image to use per cochlea position (manual step, via GUI)

It's common to have more than one image/analysis for the same side and turn (e.g. a repeated image). Use the selection GUI to mark which one(s) should be used:

```matlab
enablecache off
HistImgs = listHistImg(ee);
chooseHistImgToUse(ee)
```

This opens the **`chooseHistImgToUse`** GUI (see [GUI Reference](./GUI-Reference.md)). Mark any image you do **not** want included in further analysis with `-1` in the **Use** column. The **Prefill** button automatically selects the most recently taken image per side/turn as a starting point. Press **Done** when finished.

### Step 4: Get the summarized results for this animal

This pools the results across all cochlear turns and sides (apex/mid/base, left/right) into a single summary for the animal, using only the images you kept in Step 3:

```matlab
enablecache off
HistoRes = getHistoResults(ee);
```

`HistoRes` will contain, for each side and turn, values such as cell density, transduced-cell density, and transduction rate — see the developer-level `histimg` documentation for the full list of fields.

---


## What's next

- [GUI Reference](./GUI-Reference.md) for detailed button-by-button GUI instructions
- [FAQ / Troubleshooting](./FAQ.md) if something goes wrong
