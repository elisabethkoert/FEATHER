# How to Add a New GUI Input Field

This page explains how to add a new input field (column) to one of FEATHER's user-input GUIs (`userberabrOD`, `ICuserInput`, `chooseHistImgToUse`), and — more importantly — how that new field needs to be threaded through the rest of the codebase to actually be used by analysis functions.
---

## Background: how the user-input tables work

Each user-input GUI produces and saves a single MATLAB struct, conventionally named `UT` (or `HistoTable` for the histology GUI), with (at least) two fields:

| Field | Description |
|---|---|
| `.data` | Cell array — the actual table contents, one row per recording/image |
| `.fieldNames` | Cell array of strings — one name per column, matching the columns in `.data` |

This struct is saved to disk under a predictable name per data type:

| GUI | Saved as |
|---|---|
| `userberabrOD` | `ODui_<ExpID>.mat` |
| `ICuserInput` | `ICUserInput_<ExpID>.mat` (inside the `ICME/` subfolder) |
| `chooseHistImgToUse` | `HistoUserInput_<ExpID>.mat` (inside the `HISTO/` subfolder) |

Downstream code never accesses columns by fixed numeric index — it always looks up the column by name first, then indexes into that column:

```matlab
ix_in_UT = cellfun(@(x) strcmp(x, string(L.IC_SeriesID(ii))), ...
    UT.data(:, find(contains(UT.fieldNames,'SeriesID'))));

OD = UT.data{ix_in_UT, find(contains(UT.fieldNames,'Filter'))};
```

This lookup-by-name convention is important: it means a new column can be added to a table **without breaking existing code**, as long as existing column names aren't renamed or removed, and the new column's name doesn't accidentally collide with an existing partial match (e.g. don't add a column called `Filter2` if some code does a loose `contains(UT.fieldNames,'Filter')` match that would now match both columns unexpectedly — check for this before naming your new field).

---

## Step-by-step: adding a new field

### Step a) Decide which GUI and table your field belongs to

Match your new field to the correct GUI based on what kind of metadata it is:

| Kind of information | GUI |
|---|---|
| Per-ABR-recording metadata (hardware, filters) | `userberabrOD` |
| Per-IC-recording metadata (hardware, filters, cochlear position, quality flags) | `ICuserInput` |
| Per-histology-image metadata or useage info | `chooseHistImgToUse` |

### Step b) Add the column in App Designer

Open the relevant `.mlapp` in MATLAB App Designer (double-click it, or `appdesigner('ICuserInput.mlapp')`). You will need to:

1. Add a new column to the UI table component shown in the app (in the Design View), giving it a clear column header — this header text typically becomes (or closely matches) the `fieldNames` entry used in code.
2. Locate the callback/function responsible for building the `UT`/`HistoTable` struct before saving (likely triggered by the **EXPORT**/**Done**/**Done & EXPORT** button) and make sure your new column's values get included in `.data` and that its name is added to `.fieldNames`.
3. If the GUI has a **Prefill**/**PrefillTable** button that auto-populates values from existing objects (e.g. reading `IC.ExpInfo` fields), decide whether your new field should also be auto-filled this way, and add the corresponding logic if so.
4. If the GUI supports **IMPORT** (loading a previously saved table), make sure loading an *older* saved table (created before your field existed) doesn't crash — you likely need a fallback that adds your new column with a default value (e.g. empty string or `0`) if it's missing from an imported table.

### Step c) Update anywhere that constructs a *fresh* table

Some of these GUIs build a fresh, empty table with a fixed set of columns the first time they're run for a given experiment (rather than always reading an existing saved file). If so, your new field also needs to be added to that initial-column-list logic, with a sensible default value, so it exists even for experiments analysed for the first time after your change.

### Step d) Update downstream code that should read the new field

Adding the column to the GUI only makes the data available — it does nothing on its own. Any analysis function that should use this new metadata needs an explicit lookup, following the existing pattern:

```matlab
myNewValue = UT.data{ix_in_UT, find(contains(UT.fieldNames,'MyNewFieldName'))};
```

Search the codebase for other lookups against the same table (e.g. `find(contains(UT.fieldNames,` for `ICuserInput`) to find all the places that already read from this table, and consider whether any of them should also start using your new field (for example, a new "exclude from tonotopy analysis" flag might need to be checked in `intensityThresholdIC` in addition to wherever you originally intended to use it).

### Step e) Update the GUI Reference wiki page

Once your field is working end-to-end, add a row for it to the relevant GUI's table in [[GUI Reference|User-Guide-GUI-Reference]], following the existing column-description format, so end users know what to enter.

### Step f) Test

1. Delete or rename any existing saved user-input `.mat` file for a test experiment (or use a fresh test experiment) and confirm the GUI opens with your new column present and a sensible default.
2. Fill in a value, save (EXPORT/Done), and confirm the saved `.mat` file's `UT.fieldNames`/`UT.data` contain your new column correctly.
3. Re-open the GUI (IMPORT) and confirm your saved value loads back in correctly.
4. Confirm any downstream analysis function you updated in Step d) picks up the new value as expected.
5. **Backward compatibility check:** try IMPORT-ing an *older* saved table (from before your change) and confirm the GUI doesn't crash — this is the scenario most likely to break existing users' saved work.

---

## What's next

- [GUI Reference](./|User-Guide/GUI-Reference.md)
- [How to Add Support for New Laser/Stimulus Hardware](./Developer-Guide/Adding-New-Hardware.md)
- [Coding Conventions](./Developer-Guide/Coding-Conventions.md)
