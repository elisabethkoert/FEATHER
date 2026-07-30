---
title: Adding a new experimental data type object
---
# Adding a New Experimental Data Type as a New Object Class

This guide explains the **architectural pattern** FEATHER uses for every experimental
data type (`berabr`, `icme`, `histimg`), and walks through how
to add a **new** class following that same pattern.

> 📌 **When to use this guide:** Use this if you are recording an entirely new *kind*
> of data (e.g. a new physiological signal such as DPOAEs, or a new imaging modality) that
> doesn't fit into any existing class. If you just need to support a new **stimulus
> hardware** (e.g. a new laser) within an *existing* class like `berabr` or `icme`,
> see the separate page **[Adding New Hardware](../Developer-Guide/Adding-New-Hardware.md)** instead.

We'll use **DPOAE** (Distortion Product Otoacoustic Emission) recording
class as a running worked example since it is something recorded in the lab but not yet in FEATHER

---

## 1. Overview of the Pattern

Every FEATHER data-type class follows the same skeleton:

```
@ClassName/
  ClassName.m          ← classdef + constructor + save/load + core methods
  otherMethod1.m
  otherMethod2.m
  README.md
```

And every class is *always* linked back to its parent `anex` (the animal experiment)
via `ExpID`, and usually a `SeriesID` identifying the specific recording.

The parent `anex` object needs a small set of **integration functions** added so that
users can discover, initialize, and loop through all recordings of the new type —
mirroring functions like `allIcme`, `listIcRaw`, `initIcmeFolder`.

---

## 2. Step-by-Step Instructions

### Step 1 — Create the Class Folder

Create a new folder named `@dpoae` (the `@` prefix is MATLAB's syntax for a class
folder) directly in the toolbox root, alongside `@berabr`, `@icme`, etc.

```
FEATHER/
  @anex/
  @berabr/
  @icme/
  @histimg/
  @dpoae/          ← new
```

The main class definition file **must** be named identically to the folder
(without the `@`):

```
@dpoae/dpoae.m
```

---

### Step 2 — Define the Class Properties

Compare the property blocks of `berabr`, `icme`, and `histimg` — they share a
recognizable pattern:

| Property | Purpose | Present in |
|---|---|---|
| `ExpID` | Links back to the parent `anex` | all classes |
| `SeriesID` | Identifies this specific recording | all classes |
| `ExpInfo` / `Stim` | Raw metadata / stimulus parameters | `berabr`, `icme`, `sutr` |
| `R` | Raw data (usually emptied before saving) | `berabr`, `icme` |
| `C` | Calibration info (if the modality needs it) | `berabr`, `icme` |
| `D` | Raw data directory reference | all classes |

For our DPOAE example:

```matlab
classdef dpoae
    % DPOAE - one Distortion Product Otoacoustic Emission recording
    %   A DPOAE object represents one DPOAE measurement associated with an
    %   animal experiment (anex). It stores stimulus parameters, raw traces,
    %   and calculated DP-gram results.

    properties (SetAccess=private)
        ExpID string          % Exp/Animal ID, e.g. GEK111
        SeriesID string       % DPOAE recording ID, e.g. GEK111_0001
        ExpInfo struct        % metadata from the recording software log file
        Stim struct           % f1/f2 frequencies, levels, etc.
        R struct               % raw recorded microphone trace
        C struct               % calibration info (mic sensitivity, speaker calib)
        D struct               % raw data directory
    end

    methods
        % constructor and other methods go here (see Step 3)
    end
end
```

⚠️ **Adjust the property list above to match what a DPOAE recording actually
needs** — this is illustrative based on the standard FEATHER pattern, not a
DPOAE-specific spec.

---

### Step 3 — Implement the Constructor

The constructor must:

1. Accept the parent `anex` object (conventionally named `ee`) and a `SeriesID`
2. Populate `ExpID` from `ee.ExpID`
3. Look up the matching raw-data directory from `ee.RawDataDir` by `type`
4. Respect the caching pattern (`status_cache` / `enablecache`) used everywhere
   in FEATHER

Compare this to the `icme` constructor:

```matlab
function obj = icme (ee, SeriesID, D)
    obj.ExpID = ee.ExpID;
    obj.SeriesID = SeriesID;
    % check if we can get the D from the ee
    ix_D = find([ee.RawDataDir.type] == "IC");
    if ~isempty(ix_D)
        obj.D=ee.RawDataDir(ix_D);
    end
    % overwrite with other directory if given
    if nargin>2 && ~isempty(D)
        obj.D = D;
    end
end
```

The DPOAE equivalent:

```matlab
function obj = dpoae (ee, SeriesID, D)
    % constructor - initializes the object with ExpID, SeriesID, RawDataDir
    obj.ExpID = ee.ExpID;
    obj.SeriesID = SeriesID;

    % look up the matching raw data directory by type
    ix_D = find([ee.RawDataDir.type] == "DPOAE");
    if ~isempty(ix_D)
        obj.D = ee.RawDataDir(ix_D);
    end

    % allow overriding the directory if explicitly given
    if nargin > 2 && ~isempty(D)
        obj.D = D;
    end
end
```

> ⚠️ Note the **new unique raw-data type string** `"DPOAE"` — see Step 7 for
> where else this string must be used consistently.

---

### Step 4 — Implement Save/Load Methods

Follow the naming convention seen throughout FEATHER:
`save<ClassName>(obj)` / `load<ClassName>(obj)`.

Compare `icme`'s save/load:

```matlab
function saveIcme(obj)
    if status_cache==0
        save_name = strcat("IC_",obj.ExpID,"_",obj.SeriesID,".mat");
        testSafeDir(save_name)
        IC = obj;
        IC.R=[]; % empty the raw data to save only the processed part
        save(fullfile(expProcDataDir,'ICME','IC',save_name),'IC');
    end
end

function obj = loadIcme(obj)
    load_name = strcat("IC_",obj.ExpID,"_",obj.SeriesID,".mat");
    LO = load(fullfile(expProcDataDir,'ICME','IC',load_name),'IC');
    obj = LO.IC;
end
```

The DPOAE equivalent:

```matlab
function saveDpoae(obj)
    % dpoae\saveDpoae - stores the dpoae object in the processed data dir
    if status_cache==0
        save_name = strcat("DP_",obj.ExpID,"_",obj.SeriesID,".mat");
        testSafeDir(save_name)
        DP = obj;
        DP.R = []; % empty raw data before saving to keep files light
        save(fullfile(expProcDataDir,'DPOAE',save_name),'DP');
    end
end

function obj = loadDpoae(obj)
    % dpoae\loadDpoae - loads the dpoae object from the processed data dir
    load_name = strcat("DP_",obj.ExpID,"_",obj.SeriesID,".mat");
    LO = load(fullfile(expProcDataDir,'DPOAE',load_name),'DP');
    obj = LO.DP;
end
```

**Key conventions to preserve:**
- Always call `testSafeDir()` before writing, to prevent accidentally writing
  into the raw/archive data domain.
- Always check `status_cache==0` before overwriting saved data (i.e. only
  save when caching is *off*, meaning we intend to (re)compute fresh results).
- Clear heavy raw-data fields (`R`) before saving — only the processed
  results should persist long-term.

---

### Step 5 — Create a Dedicated Processed-Data Subfolder

New data types get their own subfolder under the experiment's processed data
directory — parallel to `HISTO/` and `ICME/`.

Add an `init<Subfolder>Folder(obj)` function to **`@anex`**, following the
pattern of `initHistoFolder.m` / `initIcmeFolder.m`:

```matlab
function initIcmeFolder (obj)
    % anex/initIcmeFolder initializes the ICME subfolder in the ProcessedDataDir
    testSafeDir (fullfile(getProcessedDataDir(obj),'ICME','IC'));
    if isfolder(fullfile(getProcessedDataDir(obj),'ICME','IC')) == 0
        mkdir(fullfile(getProcessedDataDir(obj),'ICME','IC'));
        saveAnex(obj);
    elseif isfolder(fullfile(getProcessedDataDir(obj),'ICME','IC')) == 1
        warning('Experiment is already initialized, overwrite aborted.');
    end
end
```

DPOAE equivalent (add this file to `@anex/initDpoaeFolder.m`):

```matlab
function initDpoaeFolder (obj)
    % anex/initDpoaeFolder initializes the DPOAE subfolder in the ProcessedDataDir
    testSafeDir (fullfile(getProcessedDataDir(obj),'DPOAE'));
    if isfolder(fullfile(getProcessedDataDir(obj),'DPOAE')) == 0
        mkdir(fullfile(getProcessedDataDir(obj),'DPOAE'));
        saveAnex(obj);
    elseif isfolder(fullfile(getProcessedDataDir(obj),'DPOAE')) == 1
        warning('Experiment is already initialized, overwrite aborted.');
    end
end
```

---

### Step 6 — Add Anex-Level Integration Functions

This is the key organizational step. The parent `anex` needs its own set of
functions (added as new files in `@anex/`) that let a user discover and bulk-
process all recordings of the new type. Use the `icme`/`histimg` versions as
templates:

| Existing pattern | New function needed for DPOAE | Purpose |
|---|---|---|
| `listIcRaw(ee)` / `listHistImgsRaw(ee)` | `listDpoaeRaw(ee)` | Scans the **raw** data directory and lists available recordings |
| `listIcme(ee)` / `listHistImg(ee)` | `listDpoae(ee)` | Scans the **processed** data directory and lists what's already been analyzed |
| `allIcme(ee)` | `allDpoae(ee)` | Bulk-initializes a `dpoae` object for every raw recording found |
| `initIcmeFolder(ee)` | `initDpoaeFolder(ee)` | Creates the processed-data subfolder (see Step 5) |
| `ICuserInput.mlapp` | *(optional)* `DpoaeUserInput.mlapp` | GUI for manual metadata input, if needed |

`all<ClassName>(ee)` is the typical **entry point** a user calls after
registering the new raw data directory type on their `anex`. Compare `allIcme`:

```matlab
function allIcme (obj)
    % anex\allIcme finds all IC raw data log files and initializes the icme objects
    L = listIcRaw(obj);
    initIcmeFolder(obj);
    for ii = 1 : numel(L.IC_SeriesID)
        I = icme (obj,L.IC_SeriesID(ii),L.rawDataDir);
        I = initIcme(I);
        saveIcme(I);
        fprintf('icme initialization done for %s \n',L.IC_SeriesID(ii))
    end
end
```

DPOAE equivalent (add as `@anex/allDpoae.m`):

```matlab
function allDpoae (obj)
    % anex\allDpoae finds all DPOAE raw data files and initializes the dpoae objects
    L = listDpoaeRaw(obj);
    initDpoaeFolder(obj);
    for ii = 1 : numel(L.DPOAE_SeriesID)
        DP = dpoae (obj, L.DPOAE_SeriesID(ii), L.rawDataDir);
        DP = initDpoae(DP);   % your class's own init/preprocessing method
        saveDpoae(DP);
        fprintf('dpoae initialization done for %s \n', L.DPOAE_SeriesID(ii))
    end
end
```

You will also need to write `listDpoaeRaw(ee)`, which scans the raw directory
matching `type == "DPOAE"` and builds a list struct (see `listIcRaw.m` or
`listBerabrRaw.m` for the exact pattern of parsing filenames/log files into a
`SeriesID` list).

---

### Step 7 — Register the New Raw Data Type String

`anex.RawDataDir(ii).type` is a string such as `"ABR"`, `"IC"`, `"NintendoRes"`,
or `"SU"`. Your new class needs its **own unique type string** — we used
`"DPOAE"` throughout this example.

This string **must be used consistently** in:
- the constructor's directory lookup (Step 3)
- `listDpoaeRaw` / `allDpoae` (Step 6)
- wherever the user registers the raw data directory on their `anex`, e.g.:

```matlab
D_cur = ee.RawDataDir;
D_cur(end+1).dir = ["path","to","dpoae","rawdata"];
D_cur(end).type = "DPOAE";
ee = setRawDataDir(ee, D_cur);
saveAnex(ee);
```

---

### Step 8 — (Optional) GUI for Manual User Input

If manual metadata is needed per recording (hardware used, quality flags,
cochlea position, etc.), follow the `ICuserInput.mlapp` / `userberabrOD.mlapp`
pattern:

- A user input table is saved as `<Type>UserInput_<ExpID>.mat` in the
  processed data directory (or subfolder).
- Other analysis functions read this table to filter or annotate recordings
  (e.g. skipping recordings marked as bad with `Use == -1`).

This is **optional** — only add it if downstream analysis genuinely needs
manual annotation that can't be extracted automatically from the raw data.

---

## 3. Full Worked Example — Minimal `@dpoae` Class

Putting it all together, a minimal working `@dpoae` implementation requires:

```
@dpoae/
  dpoae.m              ← classdef, constructor, saveDpoae, loadDpoae, initDpoae
  README.md

@anex/
  listDpoaeRaw.m       ← scans raw dir for DPOAE recordings
  listDpoae.m          ← scans processed dir for existing dpoae objects
  allDpoae.m           ← bulk constructor/initializer
  initDpoaeFolder.m    ← creates DPOAE/ subfolder in processed data dir
```

```matlab
classdef dpoae
    properties (SetAccess=private)
        ExpID string
        SeriesID string
        ExpInfo struct
        Stim struct
        R struct
        C struct
        D struct
    end

    methods
        function obj = dpoae (ee, SeriesID, D)
            obj.ExpID = ee.ExpID;
            obj.SeriesID = SeriesID;
            ix_D = find([ee.RawDataDir.type] == "DPOAE");
            if ~isempty(ix_D)
                obj.D = ee.RawDataDir(ix_D);
            end
            if nargin > 2 && ~isempty(D)
                obj.D = D;
            end
        end

        function obj = initDpoae(obj)
            % dpoae\initDpoae - loads raw data and runs initial processing
            obj = loadRawDpoae(obj);   % you would write this method
            obj = processDpoae(obj);   % you would write this method
        end

        function saveDpoae(obj)
            if status_cache==0
                save_name = strcat("DP_",obj.ExpID,"_",obj.SeriesID,".mat");
                testSafeDir(save_name)
                DP = obj;
                DP.R = [];
                save(fullfile(expProcDataDir,'DPOAE',save_name),'DP');
            end
        end

        function obj = loadDpoae(obj)
            load_name = strcat("DP_",obj.ExpID,"_",obj.SeriesID,".mat");
            LO = load(fullfile(expProcDataDir,'DPOAE',load_name),'DP');
            obj = LO.DP;
        end
    end
end
```

⚠️ `loadRawDpoae` and `processDpoae` are placeholders — you'll write these
to match your actual raw DPOAE file format and desired preprocessing
(analogous to `berabr/loadRaw.m` and `berabr/processBerabr.m`).

---

## 4. Final Checklist

Before considering your new class "done," verify each of the following —
we recommend literally diffing your new class's file list against
`@histimg/` as a sanity check:

- [ ] `@ClassName/` folder created with a `ClassName.m` file matching the
      folder name exactly
- [ ] Class properties include at minimum `ExpID`, `SeriesID`, `D`
- [ ] Constructor accepts `(ee, SeriesID, D)` and looks up `D` from
      `ee.RawDataDir` by a **unique** `type` string
- [ ] `save<ClassName>` / `load<ClassName>` methods implemented, using
      `testSafeDir()` and respecting `status_cache`
- [ ] Raw data (`R`) is emptied before saving
- [ ] `init<ClassName>Folder(ee)` added to `@anex/`
- [ ] `list<ClassName>Raw(ee)` added to `@anex/` (scans raw directory)
- [ ] `list<ClassName>(ee)` added to `@anex/` (scans processed directory)
- [ ] `all<ClassName>(ee)` added to `@anex/` (bulk initializer/entry point)
- [ ] New raw-data `type` string used **consistently** everywhere
- [ ] `README.md` written for the new class (see `@icme/README.md` or
      `@histimg/README.md` as templates for structure/tone)
- [ ] *(Optional)* GUI added for manual metadata input, following the
      `ICuserInput.mlapp` pattern

---

## See Also

- [Architecture Overview](../Developer-Guide/Architecture-Overview.md)
- [Adding New Hardware](../Developer-Guide/Adding-New-Hardware.md)
- [Coding Conventions](../Developer-Guide/Coding-Conventions.md)
