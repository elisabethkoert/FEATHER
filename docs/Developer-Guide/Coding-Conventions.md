# Coding Conventions

This page documents the recurring patterns used throughout the FEATHER codebase, so new code stays consistent with the existing toolbox. Some of these conventions are inferred from repeated patterns in the code rather than from an explicit style guide, so they are marked accordingly — please correct/confirm as needed.

---

## Naming conventions

### Classes and objects

- Class names are all lowercase, short, and typically abbreviations of the data type they represent: `anex` (animal experiment), `berabr` (BERA ABR), `icme` (IC multielectrode), `histimg` (histology image), `sunit`/`sutr` (single unit / single-unit trace)
- The conventional variable name for an instance of each class matches common usage across scripts (not enforced by MATLAB, but followed everywhere):

  | Class | Conventional variable name |
  |---|---|
  | `anex` | `ee` |
  | `berabr` | `B` |
  | `icme` | `IC` |
  | `histimg` | `histImg` or `H` |



### Functions

- Function names are `camelCase`, and start with a verb describing what they do: `calculateSpikeRate`, `getResponsiveUnits`, `plotHeatmapsIC`, `loadIcme`, `saveBerabr`.
- Functions that operate on/return data for a *specific* object type usually have that object type as a suffix: `calculateDynamicRangeICME`, `calculateDynamicRangeAnex` — the same underlying computation implemented once per class, rather than one generic function dispatching on type. When adding a new analysis, follow this pattern rather than trying to unify across classes, unless explicitly restructuring.
- Class methods live in their own file, one function per file, inside the `@classname/` folder (standard MATLAB class-folder convention) — e.g. `@icme/calculateSpikeRate.m`.

### Properties and variables

- Object properties are typically `PascalCase` (`ExpID`, `SeriesID`, `RawDataDir`), while local/loop variables are `camelCase` or `snake_case` depending on the author/era of the code — there is **no single enforced convention** for local variables; both styles appear throughout. New code should prefer `camelCase` for consistency with the class properties it's likely to interact with, but exact consistency with surrounding code in the same file takes priority over a global rule.
- `stim_criteria_array` and its documented `[column, min, max; ...]` format is a de facto standard input across nearly all IC analysis functions — reuse this exact parameter name and format when writing new analysis functions rather than inventing a new filtering convention.

### File/data naming on disk

Saved `.mat` files follow a strict `<Prefix>_<ExpID>_<SeriesID>.mat` pattern, where the prefix identifies the object type:

| Prefix | Object |
|---|---|
| `E_` | `anex` |
| `B_` | `berabr` |
| `W_` | wave annotations for a `berabr` |
| `IC_` | `icme` |
| `H_` | `histimg` |


New object types should follow this same `<Prefix>_<ExpID>_<SeriesID>.mat` convention, and the prefix should be a single, unused capital letter.

---

## The caching pattern: `enablecache` / `status_cache`

This is the most important convention to follow correctly when writing new loader/constructor code.

- `enablecache('on'|'off')` is a **persistent, session-wide** switch (implemented via a `persistent` variable), not tied to any specific object.
- `status_cache` is a helper that returns `1`/`0` for whether caching is currently on, and additionally throws an error if called **without an output argument** while caching is off — this is used as an inline safety check in some functions (`if status_cache==1 ... elseif status_cache==0 ...`).

**Convention for new constructors/loaders:**

```matlab
if status_cache == 1
    try
        obj = loadXxx(obj);   % attempt to load previously saved result
    catch
        % fall back / warn that recomputation is needed
    end
else
    % build/recompute from raw data
end
```

**Convention for new save functions:** always guard the actual disk write with a cache check, so that turning caching on protects existing saved results from being silently overwritten:

```matlab
function saveXxx(obj)
    if status_cache == 0
        % ... actually write to disk
    end
end
```

Do **not** invent a new persistent variable for a similar purpose in new code — reuse `enablecache`/`status_cache` so behavior stays predictable for users switching between different parts of the toolbox.

---

## The `testSafeDir` safety check

`testSafeDir(path)` throws an error if `path` contains the substring `archiv`, which is the raw/archive data domain. This exists to prevent processed results from ever being written into raw data storage.

**Convention:** call `testSafeDir` on any path immediately before it is used as a **write target** (not read target) — see `initProcessedExp`, `saveAnex`, `saveBerabr`, `saveHistimg`, `setProcessedDataDir` for examples. When adding a new save function for a new object type, copy this pattern:

```matlab
function saveXxx(obj)
    if status_cache == 0
        save_name = strcat("X_", obj.ExpID, "_", obj.SeriesID, ".mat");
        testSafeDir(save_name)   % or testSafeDir(fullfile(targetDir, save_name))
        X = obj;
        save(fullfile(expProcDataDir, save_name), 'X');
    end
end
```

⚠️ Note that in some existing code, `testSafeDir` is called on just the filename (`save_name`) rather than the full path — this only works because `expProcDataDir` itself is validated elsewhere. When writing new save functions, prefer validating the **full resolved path**, not just the filename, to make the safety check meaningfully robust.

---

## Processed-data folder structure

New sub-object types should follow the same folder convention as existing ones:

- Each modality gets its own subfolder under the experiment's processed-data folder if it produces more than a handful of files (see `HISTO/`, `ICME/` in [Architecture Overview](./Architecture-Overview]]´´.md).
- Use an `init<Modality>Folder(ee)` function (see `initHistoFolder`, `initIcmeFolder`, `initLightSheetHistoFolder`) to create this subfolder on first use, guarded by `testSafeDir` and a check for whether the folder already exists (warn rather than silently overwrite).
- Cached list-of-recordings files follow the `List_<Modality>[_raw].mat` naming pattern (see `listBerabr`, `listIcme`, `listHistImg`, and their `*Raw` counterparts) — reuse this pattern for new modalities rather than inventing a new listing convention.

---

## Function header/documentation style

Most functions in the codebase use a comment block immediately after the function signature, in this rough shape:

```matlab
function out = myFunction(obj, param1, param2)
% ClassOrModule\myFunction short one-line description
% longer explanation if needed
% input:
%   obj (icme): description
%   param1 (type): description
% output:
%   out (type): description
```

New functions should follow this shape: a `ClassName\functionName` prefix on the first comment line, then `input:`/`output:` sections listing each parameter with its expected type in parentheses. This isn't enforced by any linter, but it's the dominant style and keeps `help functionName` useful.

---
