# 📘 Developer Guide

This section is for anyone who needs to **extend, modify, or maintain**
FEATHER itself — for example, adding support for a new piece of hardware, a
new type of experiment, or a whole new data modality.

**This guide assumes you're comfortable writing MATLAB code** and have
already read the **[[User Guide|User-Guide]]**, especially
*[[How FEATHER Works (Big Picture)|User-Guide-How-FEATHER-Works]]* — the
patterns described here build directly on those concepts (the `anex` object,
the caching system, and the processed-data folder structure).

---

## 🧭 Where to start

1. **[[Architecture Overview|Home/Developer-Guide/Architecture-Overview]]**
   Start here. This explains the overall class hierarchy (`anex` → `berabr` /
   `icme` / `histimg` / ...), how data flows through the toolbox, and the
   file-naming conventions used everywhere.

2. **[[Coding Conventions|Home/Developer-Guide/Coding-Conventions]]**
   Naming patterns, the `enablecache`/`status_cache` caching mechanism,
   the `testSafeDir()` safety check, and the processed-data folder layout.
   Please follow these conventions in any code you contribute.

3. Then, depending on what you're trying to do:

   | I want to... | Go to |
   |---|---|
   | Add an entirely new **kind** of recording (e.g. a new modality that doesn't fit any existing class) | [[Adding a new experimental data type object\|Home/Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class]] |
   | Add support for a **new piece of hardware** (e.g. a new laser) within ABR or IC recordings | [[Adding New Hardware\|Home/Developer-Guide/Adding-New-Hardware]] |
   | Add a **new stimulus/experiment type** for existing IC recordings | [[Developer Guide: Adding New Stimulus Type for IC\|Home/Developer-Guide/Adding-New-Experiment-Type]] |
   | Add a new **input field to a GUI** (e.g. `ICuserInput`) | [[Adding GUI Field\|Home/Developer-Guide/Adding-GUI-Field]] |
   | Verify my change didn't break anything (automated regression tests) | [[Automated Testing Guide\|Home/Developer-Guide/Automated-Testing-Guide]] |


4. Before diving in, it's worth skimming:
   **[[Known Limitations|Home/Developer-Guide/Known-Limitations]]** —
   explains which classes (`@expsess`, `@oci`) are early-stage/incomplete,
   so you don't accidentally build on top of unfinished code.

---

## 📄 All Developer Guide Pages

- [[Architecture Overview|Home/Developer-Guide/Architecture-Overview]]
- [[Coding Conventions|Home/Developer-Guide/Coding-Conventions]]
- [[Adding a new experimental data type object|Home/Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class]]
- [[Adding New Hardware|Home/Developer-Guide/Adding-New-Hardware]]
- [[Developer Guide Adding New Stimulus Type for IC|Home/Developer-Guide/Adding-New-Experiment-Type]]
- [[Adding GUI Field|Home/Developer-Guide/Adding-GUI-Field]]
- [[Git Workflow & Testing Before Merging|Home/Developer-Guide/Git-Workflow-&-Testing-Before-Merging]]
- [[Automated Testing Guide|Home/Developer-Guide/Automated-Testing-Guide]]
- [[Known Limitations|Home/Developer-Guide/Known-Limitations]]

---

🧬 Just want to run an existing analysis instead of modifying code?
Head back to the **[[User Guide|User-Guide]]**.

⬅ [[Back to Home|Home]]