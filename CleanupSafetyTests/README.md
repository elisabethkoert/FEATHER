# CleanupSafetyTests

Minimal, non-interactive safety suite to run **before and after deleting FEATHER files/functions**.

## Goal
Provide deterministic pass/fail checks for manuscript-critical workflows so cleanup can be done in small safe batches.

## Files
- `cleanupSafetyDefaultConfig.m`: configuration template (dataset, experiment, deletion batch, golden settings)
- `runCleanupSafetySuite.m`: runs all stage-focused tests
- `test_*.m`: focused tests for each critical stage
- `cleanupSafetyPipeline.m`: core smoke path used by smoke + dependency guard
- `generateGoldenOutputs.m`, `compareGoldenOutputs.m`: golden baseline support
- `pre_delete_checklist.txt`: required run order for safe deletions

## Usage
1. Open MATLAB in FEATHER root and add this folder to path.
2. Create config:
   - `cfg = cleanupSafetyDefaultConfig;`
   - set `cfg.expID`, `cfg.regressionDataRoot`, `cfg.rawDataDirParts`
   - optionally set `cfg.processedDataDirPath`
3. Baseline run (no deletions):
   - `cfg.generateGolden = true;`
   - `runCleanupSafetySuite(cfg);`
4. Deletion batch run:
   - `cfg.generateGolden = false;`
   - set `cfg.deletedCandidates = ["relative/path/you/deleted.m"];`
   - `runCleanupSafetySuite(cfg);`

## Determinism rules used here
- no GUI/manual interactions
- no hardcoded machine-specific absolute paths in scripts
- one focused pass/fail per test file
- smoke outputs compared against golden baseline fields
