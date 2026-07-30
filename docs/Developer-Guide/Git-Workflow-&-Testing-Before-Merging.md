---
title: Git Workflow & Testing Before Merging
---
# Developer Guide: Git Workflow & Testing Before Merging

This page explains **how changes to FEATHER should be made and verified** before
they become part of the toolbox everyone uses (the `main` branch).

If you haven't yet read **[Getting Started with Git](../User-Guide/Git-Basics.md)**,
do that first — this page assumes you already know how to clone the repo and
do a basic `git pull`.

---

## 🌳 Why We Use Branches

`main` is the version of FEATHER that everyone in the lab relies on for their
daily analysis. If you make changes directly on `main` and something breaks,
**everyone's analysis breaks** — including people running experiments right now.

To avoid this, every change (a new feature, a bug fix, support for new
hardware, etc.) is made on its own **branch** — think of it as a personal
scratch copy of the code where you can experiment freely without affecting
anyone else. Once you're confident your changes work correctly (see
**Testing**, below), the branch is **merged** back into `main`.

```
main ──●───────────────────●──────────●────►  (always stable, always usable)
        \                 /          /
         ●───●───●───●───●          /   ← your branch: "add-dpoae-support"
                                    /
                          ●───●───●     ← someone else's branch, done in parallel
```

---

## 🔧 The Basic Workflow

### 1. Make sure `main` is up to date

Before starting any new work, pull the latest version of `main`:

```bash
git checkout main
git pull
```

### 2. Create a new branch for your change

Give it a short, descriptive name (lowercase, hyphens instead of spaces):

```bash
git checkout -b add-dpoae-support
```

This creates the branch **and** switches you onto it in one step.

### 3. Make your changes

Edit/add files as needed. Commit your work in small, logical chunks rather
than one giant commit at the end — this makes it much easier for someone
else (or future-you) to understand what changed and why.

```bash
git add path/to/changed/file.m
git commit -m "Add dpoae class constructor and save/load methods"
```

Repeat as you go. Commit messages should describe *what* changed and *why*,
not just "fix stuff" or "update".

### 4. Push your branch to GitLab

```bash
git push -u origin add-dpoae-support
```

(The `-u` only needs to be included the first time you push this branch —
after that, `git push` alone is enough.)

### 5. ⚠️ Test your changes (see below) — do this before opening a merge request

### 6. Open a Merge Request (MR) on GitLab

On the GitLab website, navigate to the repository → **Merge Requests** →
**New Merge Request**. Select your branch as the source and `main` as the
target. Add a description of what you changed and — importantly — **state
which tests you ran and confirm they passed** (see checklist at the bottom
of this page).

### 7. Review & Merge

Ideally, ask someone else in the lab to look over your changes before
merging (especially for anything touching shared core functions like `anex`,
`enablecache`, or the calibration logic). Once approved, merge the branch
into `main` via GitLab, and then you can delete the branch.

---

## ✅ Testing Before You Merge

**Every new developer must run both of the following before merging into
`main`:**

1. **The automated regression suite**
   (`TestingScriptsForFeather/automated/`)
2. **The relevant `exampleScripts/` file(s)**, including their GUI steps


### 1. Run the automated regression suite

```matlab
cd TestingScriptsForFeather/automated
results = runAllAutomatedTests;
```

- Confirm no test shows **Failed** ("Failed by verification"). **Incomplete**
  ("Filtered by assumption") is expected for anything without a golden
  baseline or role registered yet — that's not a failure.
- If your change was expected to alter output values (e.g. you
  deliberately changed how an analysis function computes something),
  regenerate the relevant golden baseline(s) with
  `regenerateGoldenResults(...)`, **manually review the new numbers**
  before committing, and include the updated golden `.mat` file(s) in
  your Merge Request.
- If your change added a new class, hardware type, or experiment type,
  add the relevant experiment to `utils/TestExperimentRegistry.m` (and,
  for IC-specific protocol analyses, `utils/ICRoleRegistry.m`), then
  generate its golden baseline the same way, so the *next* developer's
  test run benefits from it too.

Full details, including how to investigate a specific failure and how
golden baselines work, are in the
**[Automated Testing Guide](../Developer-Guide/Automated-Testing-Guide.md)**.

### 2. Run the relevant `exampleScripts/` file(s)

The automated suite intentionally does not cover GUI interaction or
visual/plotting output — an automated pass/fail check can't judge
whether a GUI behaves correctly or whether a plot "looks right." This is
still checked manually:

- Run the `exampleScripts/` file(s) relevant to the part of the toolbox
  you changed (e.g. if you touched anything in `@berabr` or calibration
  handling, run `processing_new_ABR_data.m`).
- Actually click through the GUI-driven steps (`exploreBerabr`,
  `userberabrOD`, `ICuserInput`, etc.) rather than skipping past them —
  this remains our best manual check that GUI input/output still works
  correctly with your changes.

> 📌 Both the automated suite and the example scripts currently rely on
> access to the shared raw-data drive, and are therefore only runnable by
> people with access to that data.

---

## 📝 Keeping the Documentation in Sync

Code changes are only half the job — **the wiki needs to stay accurate too.**
An outdated wiki is often worse than no wiki, since it actively misleads the
next person who reads it.

Before opening your Merge Request, check whether your change affects any of
the following, and update accordingly:

| If you changed... | Update... |
|---|---|
| Any `@ClassName/` folder's behavior, properties, or file conventions | that class's `README.md` (see `@icme/README.md` or `@histimg/README.md` for the expected structure/tone) |
| Anything about calibration file formats or naming conventions | the "Calibration Files" section of the relevant class README |
| A GUI (`.mlapp`) — added/changed a field, button, or workflow step | [GUI Reference](../User-Guide/GUI-Reference.md) and, if the GUI has its own detailed walkthrough, `GUI/readme.md` |
| The overall class hierarchy or added a brand-new class | [Architecture Overview](../Developer-Guide/Architecture-Overview.md)|
| A naming convention, the caching pattern, or a core safety check |[Coding Conventions](../Developer-Guide/Coding-Conventions.md) |
| Anything a routine user would need to know to run their analysis | the relevant **User Guide** walkthrough page |
| The automated test suite itself (new registry entries, new pipeline steps, new golden baselines) | [Automated Testing Guide](../Developer-Guide/Automated-Testing-Guide.md), and `automated/PENDING_TEST_COVERAGE.md` if you closed or added a known gap |

**If you added a brand-new wiki page** (e.g. documenting a new developer
task, following the pattern of this page or
[Adding a new experimental data type object](../Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class.md),
make sure to also:

- Add a link to it from the **[Developer Guide](../Developer-Guide.md)**
  landing page (or **[User Guide](../User-Guide.md)**, if user-facing)
- Add it to the **[Home](../Home.md)** page's navigation list
- Cross-link it from any closely related existing pages (See Also sections)

A wiki page that exists but isn't linked from anywhere is effectively
invisible — GitLab won't surface it in navigation on its own.

---

## ✅ Pre-Merge Checklist

Copy this into your Merge Request description and check off each item:

- [ ] Pulled latest `main` before branching
- [ ] Ran `TestingScriptsForFeather/automated/runAllAutomatedTests` — no
      unexpected **Failed** results (Incomplete is fine if expected)
- [ ] If output values were expected to change, regenerated and manually
      reviewed the relevant golden baseline(s) via
      `regenerateGoldenResults(...)`, and included updated golden files
      in this MR
- [ ] If I added a new class/hardware/experiment type, added it to
      `TestExperimentRegistry.m` (and `ICRoleRegistry.m` if applicable)
      and generated its golden baseline
- [ ] Ran the relevant `exampleScripts/` file(s), including GUI steps,
      for the part of the toolbox I changed
- [ ] Updated any affected README.md/wiki page(s) — (see
     **Keeping the Documentation in Sync**)
      above — and linked any new page from Home/Developer Guide navigation
- [ ] Requested review from at least one other developer (for changes to
      shared/core functions)


---
