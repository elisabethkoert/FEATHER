# FEATHER Wiki

**FEATHER** (Framework for Experimental Analysis of Tissue and Electrophysiology for Heterogeneous Experiments and Researchers) is the MATLAB toolbox used at the Institute for Auditory Neuroscience to process ABR, IC multielectrode, and histology data associated with animal experiments.

This wiki is organized into two tracks:

| For Users | For Developers |
|---|---|
| Running standard ABR, IC, or histology analyses using existing pipelines and GUIs. No coding experience required. | Extending or modifying the toolbox itself — adding new hardware, experiment types, or analysis methods. |
| **→ Go to [User Guide](-\User-Guide.md)** | **→ Go to [Developer Guide](.\Developer-Guide.md)** |

If you're unsure which applies to you: if you're clicking through GUIs and running example scripts, start with the **User Guide**. If you're opening `.m` files in the editor to change how something works, go to the **Developer Guide**.

---

## 📗 User Guide
*For running standard analyses — no prior coding experience assumed.*
- [Getting Started – Installation & Toolbox Setup](./User-Guide/Getting-Started.md)
- [Getting Started with Git](./User-Guide/Git-Basics.md) — for absolute beginners to Git
- [How FEATHER Works (Big Picture)](./User-Guide/How-FEATHER-Works.md)  **Read this before the walkthroughs below.**
- [ABR Analysis Walkthrough](./User-Guide/ABR-Walkthrough.md)
- [IC Analysis Walkthrough](./User-Guide/IC-Walkthrough.md)
- [Histology Analysis Walkthrough](./User-Guide/Histology-Walkthrough.md)
- [GUI Reference](./User-Guide/GUI-Reference.md)
- [FAQ / Troubleshooting](./User-Guide/FAQ.md)

---

## 📘 Developer Guide
*For extending or maintaining the toolbox itself.*
- [Architecture Overview](./Developer-Guide/Architecture-Overview.md) — class hierarchy, data flow, file conventions
- [Coding Conventions](./Developer-Guide/Coding-Conventions.md) — naming, caching pattern, `testSafeDir`, folder structure
- [Adding a new experimental data type object](./Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class.md)
- [Adding New Hardware](./Developer-Guide/Adding-New-Hardware.md)
- [Developer Guide Adding New Stimulus Type for IC](./Developer-Guide/Adding-New-Experiment-Type.md)
- [Adding GUI Field](./Developer-Guide/Adding-GUI-Field.md)
- [Git Workflow & Testing Before Merging](./Developer-Guide/Git-Workflow-&-Testing-Before-Merging.md)
- [Automated Testing Guide](./Developer-Guide/Automated-Testing-Guide.md)
- [Known Limitations](./Developer-Guide/Known-Limitations.md)

---

## About FEATHER

FEATHER organizes all data belonging to one animal experiment under a single `anex` (animal-experiment) object, with sub-objects for each recording or image set:

- `berabr` — one ABR measurement
- `icme` — one inferior colliculus multielectrode recording
- `histimg` — one histology image set

Raw data and processed (analysed) data are always kept strictly separate, and processed results are cached to disk so they don't need to be recomputed every time. If this sentence doesn't mean much to you yet, that's exactly what [[How FEATHER Works (Big Picture)|User-Guide-How-FEATHER-Works]] is for.

---

## Contributing to this wiki

⚠️ This wiki is actively being built out. Where content is uncertain, based on inference from code rather than direct maintainer confirmation, or where the codebase contains contradictions, pages are marked with:

> ⚠️ **NEEDS INPUT FROM MAINTAINERS:** ...

If you spot one of these while reading, please help fill in the gap or ping a maintainer.

---

*Institute for Auditory Neuroscience, University Medical Center Göttingen*
