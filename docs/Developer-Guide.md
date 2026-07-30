# 📘 Developer Guide

This section is for anyone who needs to **extend, modify, or maintain**
FEATHER itself — for example, adding support for a new piece of hardware, a
new type of experiment, or a whole new data modality.

**This guide assumes you're comfortable writing MATLAB code** and have
already read the **[User Guide](./User-Guide.md)**, especially
*[How FEATHER Works (Big Picture)](./User-Guide/How-FEATHER-Works.md)* — the
patterns described here build directly on those concepts (the `anex` object,
the caching system, and the processed-data folder structure).

---

## 🧭 Where to start

1. **[Architecture Overview](./Developer-Guide/Architecture-Overview.md)**
   Start here. This explains the overall class hierarchy (`anex` → `berabr` /
   `icme` / `histimg` / ...), how data flows through the toolbox, and the
   file-naming conventions used everywhere.

2. **[Coding Conventions](./Developer-Guide/Coding-Conventions.md)**
   Naming patterns, the `enablecache`/`status_cache` caching mechanism,
   the `testSafeDir()` safety check, and the processed-data folder layout.
   Please follow these conventions in any code you contribute.

3. Then, depending on what you're trying to do:

   | I want to... | Go to |
   |---|---|
   | Add an entirely new **kind** of recording (e.g. a new modality that doesn't fit any existing class) | [Adding a new experimental data type object](./Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class.md) |
   | Add support for a **new piece of hardware** (e.g. a new laser) within ABR or IC recordings | [Adding New Hardware](./Developer-Guide/Adding-New-Hardware.md) |
   | Add a **new stimulus/experiment type** for existing IC recordings | [Developer Guide: Adding New Stimulus Type for IC](./Developer-Guide/Adding-New-Experiment-Type.md) |
   | Add a new **input field to a GUI** (e.g. `ICuserInput`) | [Adding GUI Field](./Developer-Guide/Adding-GUI-Field.md) |
   | Verify my change didn't break anything (automated regression tests) | [Automated Testing Guide](./Developer-Guide/Automated-Testing-Guide.md) |


4. Before diving in, it's worth skimming:
   **[Known Limitations](./Developer-Guide/Known-Limitations.md)** 

---

## 📄 All Developer Guide Pages

- [Architecture Overview](./Developer-Guide/Architecture-Overview.md)
- [Coding Conventions](./Developer-Guide/Coding-Conventions.md)
- [Adding a new experimental data type object](./Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class.md)
- [Adding New Hardware](./Developer-Guide/Adding-New-Hardware.md)
- [Developer Guide Adding New Stimulus Type for IC](./Developer-Guide/Adding-New-Experiment-Type.md)
- [Adding GUI Field](./Developer-Guide/Adding-GUI-Field.md)
- [Git Workflow & Testing Before Merging](./Developer-Guide/Git-Workflow-&-Testing-Before-Merging.md)
- [Automated Testing Guide](./Developer-Guide/Automated-Testing-Guide.md)
- [Known Limitations](./Developer-Guide/Known-Limitations.md)

---

🧬 Just want to run an existing analysis instead of modifying code?
Head back to the **[User Guide](./User-Guide.md)**.

