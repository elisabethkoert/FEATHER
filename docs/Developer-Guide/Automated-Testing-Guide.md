# Automated Testing Guide

This page documents FEATHER's automated regression-test suite, located at
`TestingScriptsForFeather/automated/`that run without requiring a human to manually step through a script.

See **[Git Workflow & Testing Before Merging](../Developer-Guide/Git-Workflow-&-Testing-Before-Merging.md)**
for the full pre-merge checklist, which now centers on running this suite
(this page only covers the manual GUI-driven checks that this automated
suite intentionally does not replace, since GUI interaction and visual
plot output can't be judged by an automated pass/fail check).

Running the automated tests, especially for the IC analysis is not fast, so if you have not changed anything in there it may make sense to adapt the TestExperimentRegistry.m to include less experiments for just one general test if you have not actively worked on the IC pipeline.

> 📌 If you're looking for how to run analysis on your own data, this page
> is not for you — see the **[User Guide](../User-Guide.md)** instead. This page
> is for developers verifying that a code change hasn't broken anything.

---

## 🧠 The core idea, in one paragraph

Several FEATHER pipelines (ABR wave-picking, IC hardware/filter entry,
histology image selection) normally require a human to click through a
GUI. For automated testing, we bypass this by loading **previously
recorded, real annotations** for a fixed set of experiments — stored as
`UserInputCopies/` folders sitting alongside the raw data — instead of
opening any `.mlapp`. Each pipeline is then run exactly as it would be
normally, and the resulting numbers are compared against a **golden
baseline** (a `.mat` file of previously-approved output) with a small
numeric tolerance, to catch regressions.

## 📁 Where everything lives

```

TestingScriptsForFeather/
└── automated/
├── runAllAutomatedTests.m        ← run this to execute the whole suite
├── regenerateGoldenResults.m     ← manual, dev-run-only utility (see below)
├── PENDING_TEST_COVERAGE.md      ← tracks known gaps (see below)
├── test_ABR_analysis.m
├── test_IC_analysis.m
├── test_histology_analysis.m
├── golden/                       ← committed golden .mat baselines
│    ├── ABR/<ExpID>_golden.mat
│    ├── IC/<ExpID>_golden.mat
│    ├── Histo/<ExpID>_golden.mat
├── runLogs/                       
└── utils/
│    ├── FeatherTestCase.m           ← shared base class: forces userID('TEST') isolation
│    ├── testRawDataRoot.m
│    ├── TestExperimentRegistry.m    ← MANUALLY edited: which ExpIDs to test, per modality
│    ├── ICRoleRegistry.m             ← MANUALLY edited: which icme SeriesID plays which protocol role, per animal
│    ├── generateCandidateExperimentList.m
│    ├── hasRawData.m
│    ├── getOrCreateTestAnex.m
│    ├── copyUserInputFixtures.m
│    ├── goldenResultsDir.m
│    ├── compareAgainstGolden.m
│    ├── runABRPipeline.m
│    ├── runICPipeline.m
│    └── runHistoPipeline.m

```

Raw data itself (and the `UserInputCopies/` fixture folders) live outside
this repo, on the shared raw-data drive — see the `AllDataTypesForAnalysisTests`
README for what's available per animal.

---

## ⚙️ Safety: the `'TEST'` user isolation

Every automated test run — and `regenerateGoldenResults.m` — forces the
persistent `userID` to `'TEST'` for its duration, and restores whatever
it was before, on exit (including if something errors partway through).
This guarantees test runs write to:

```

.../TESTdata//f_/...

```

and can **never** collide with or overwrite a real analyst's actual
processed results in `.../<theirUserID>data/...`.

⚠️ **If you're debugging a pipeline manually outside the test suite**
(e.g. calling `runICPipeline('gjg131644')` directly in the console to
inspect a failure), this automatic isolation does **not** apply — you
must set `userID('TEST')` yourself first, or you risk writing test data
into your own real analysis folder. See
**[[Investigating a Test Failure|#-investigating-a-specific-failure]]**
below for the recommended debugging pattern.

---

## ▶️ Running the suite

### Prerequisites

- Your usual FEATHER session setup (`ukonmap`, `processedDataMap`, toolbox
  on path) — see **[Getting Started](../User-Guide/Getting-Started.md)**.
- Access to the shared raw-data drive containing `AllDataTypesForAnalysisTests/`.
- `TestExperimentRegistry.m` and `ICRoleRegistry.m` reviewed/updated for
  any new experiments you want covered (see below).

### Run everything

```matlab
cd TestingScriptsForFeather/automated
results = runAllAutomatedTests;
```

This:
1. Adds `utils/` to the path.
2. Discovers and runs every `test_*.m` class in the folder (non-recursively — `utils/` and `golden/` are not scanned).
3. Prints a summary table.
4. **Returns `results`** so you can inspect it afterward — the local variable inside `runAllAutomatedTests` does not otherwise leak into your workspace, so don't forget to capture the output.
5. Also saves a timestamped copy to `automated/runLogs/testRunResults_<timestamp>.mat`, in case you forget to capture the return value or want to compare against an earlier run.

`runLogs/` is git-ignored — these are personal debug artifacts, not part of the committed test suite.

### Run just one modality (faster iteration)

```matlab
runtests('test_IC_analysis')
```

### Run just one experiment within a modality

```matlab
import matlab.unittest.selectors.HasParameter
suite = matlab.unittest.TestSuite.fromClass(?test_IC_analysis);
suite = selectIf(suite, HasParameter('Name','ExpID','Value','gjg131644'));
results = run(suite);
```

---

## 📖 Reading the results: Passed / Failed / Incomplete

This is the most common point of confusion, so it's worth stating clearly:

| Status | Meaning | Action needed? |
|---|---|---|
| **Passed** | Fresh output matched the committed golden baseline within tolerance | None |
| **Incomplete** ("Filtered by assumption") | An `assumeTrue(...)` check stopped the test early — most commonly because no golden file exists yet for this experiment, or a required fixture/role isn't defined | Expected for anything not yet regenerated/registered — not a bug |
| **Failed** ("Failed by verification") | A `verifyXxx(...)` check found something wrong — e.g. an empty result where one was expected | **Investigate** — this means the pipeline itself produced something unexpected |

You can see **both** an Incomplete and a Failed status on the *same* test result — this is normal, not contradictory. `verify*` checks record failures but don't stop execution; `assumeTrue` checks do stop execution. So a test can fail a `verify*` check partway through, keep running, and *then* get cut short later by an `assumeTrue` (most often the "no golden file yet" check at the very end). Both get attached to the one result.

To filter down to genuine failures only:

```matlab
failed = results(~[results.Passed] & ~[results.Incomplete]);
{failed.Name}'
```

---

## 🔍 Investigating a specific failure

Two approaches, in order of preference:

**1. Re-run just that one test, and watch the printed diagnostics:**

```matlab
import matlab.unittest.selectors.HasParameter
suite = matlab.unittest.TestSuite.fromClass(?test_IC_analysis);
suite = selectIf(suite, HasParameter('Name','ExpID','Value','gjg131644'));
result = run(suite);
```

The exact `sprintf(...)` message from whichever `verify*`/`assumeTrue`
failed will print live to the Command Window.

**2. Inspect the saved `TestResult` object directly**, without re-running:

```matlab
idx = find(strcmp({results.Name}, 'testSpikeExtractionAndProtocolSpecificAnalyses(ExpID=gjg131644)'));
results(idx).Details.DiagnosticRecord
```

**3. Bypass the test framework entirely and call the pipeline directly** —
fastest for iterative debugging, but remember to isolate your user first:

```matlab
userID('TEST')
result = runICPipeline('gjg131644');
result.tonotopy
result.repRate
result.pulseDuration
result.icAnexWideThresholds
```

Look for `NaN`, `[]`, or unexpected classes in the fields above — that's
usually the culprit. A common cause: a `stim_criteria_array` entered in
`ICRoleRegistry.m` doesn't actually match any real stimuli for that
specific recording (e.g. an intensity range that doesn't overlap with
what was actually presented), so the analysis function runs without
erroring but returns an empty result.

---

## 🧊 Golden baselines: what they are and how to (re)generate them

A "golden" result is simply a `.mat` file containing a previously
**human-approved** output of a pipeline, committed to the repo. Every
subsequent test run compares fresh output against it (within a small
relative tolerance, currently 1%) rather than against any hardcoded
expected value — this makes tests resilient to tiny floating-point
differences while still catching real regressions.

### Regenerating (or creating for the first time)

⚠️ **This is a manual, deliberate action — never run automatically by the
test suite itself.** Only run it after you've looked at the output and
judged it correct.

```matlab
regenerateGoldenResults('ABR')            % every ABR experiment in the registry
regenerateGoldenResults('ABR','GEK030')   % just one
regenerateGoldenResults('IC')
regenerateGoldenResults('Histo')
```

This calls the same `run<Modality>Pipeline.m` function the tests
themselves use (so there is no risk of the two drifting apart), isolates
`userID` to `'TEST'` for its duration exactly like the test suite does,
and overwrites `automated/golden/<Modality>/<ExpID>_golden.mat`.

### Before committing a regenerated golden file

1. **Actually load and look at it.** Don't just trust that "it ran without erroring" means the numbers are right:
   ```matlab
   g = load('automated/golden/IC/GEK030_golden.mat');
   g.result.tonotopy.slope
   g.result.pulseIntensity.SoE_mm
   ```
2. Sanity-check against domain knowledge (plausible oct/mm slope, plausible spread-of-excitation distance, etc.).
3. Re-run the test suite once more to confirm it now shows **Passed** rather than Incomplete for that experiment.
4. Commit the `.mat` file alongside whatever code/registry change prompted the regeneration, so reviewers can see both together.

### When you'll need to regenerate

- You've deliberately changed how an analysis function computes something (expected, intentional).
- You've added a new experiment to `TestExperimentRegistry.m`/`ICRoleRegistry.m` for the first time (no golden file exists yet — the test will show Incomplete until you run the regeneration step once).
- ⚠️ You should **not** need to regenerate just because a test unexpectedly failed after an *unintended* code change — that's the regression the golden file is supposed to catch. Investigate first (see above); only regenerate once you've confirmed the new behavior is actually correct and desired.

---

## ➕ Adding a new experiment to the suite

1. Confirm the raw data exists under the shared raw-data root, and that a `UserInputCopies/` folder with the relevant fixtures (`ODui_*.mat`, `W_*.mat`, `ICUserInput_*.mat`, `HistoUserInput_*.mat` as applicable) is present alongside it.
   - Optionally run `generateCandidateExperimentList('ABR'|'IC'|'Histo')` first — this scans the raw-data root and prints a ready-to-paste list of everything it can find, as a starting point (it does **not** modify the registry itself).
2. Add the `ExpID` to `utils/TestExperimentRegistry.m`, under the appropriate modality.
3. **For IC specifically:** if you want protocol-specific analyses (tonotopy/repRate/pulseIntensity/pulseDuration) run and checked for this animal — not just the baseline spike-extraction sanity check — add an entry to `utils/ICRoleRegistry.m`, following the existing GEK030/gjg131644/gth212308 entries as templates. Each role needs the exact `SeriesID` and a `stim_criteria_array` that actually matches real presented stimuli for that recording — **do not guess these values**; confirm them against the animal's actual calibrated data first, the same way the existing entries were derived from `TestingScript.m`.
4. Run the suite — the new experiment will show **Incomplete** (no golden file yet), which is expected.
5. Once you've confirmed the pipeline runs cleanly and produces sensible output, run `regenerateGoldenResults(...)` for it, review, and commit.

---

## 📌 Known gaps — see `PENDING_TEST_COVERAGE.md`

Not everything is covered yet. The following are tracked explicitly in
`automated/PENDING_TEST_COVERAGE.md` (kept in the repo, not just in
chat/PR history, so they don't get silently forgotten):

If you pick up any of these, remove the corresponding entry from
`PENDING_TEST_COVERAGE.md` once it's implemented and wired into a
`test_*.m` file.

---
