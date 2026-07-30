# FEATHER Wiki

**FEATHER** (Framework for Experimental Analysis of Tissue and Electrophysiology for Heterogeneous Experiments and Researchers) is the MATLAB toolbox used at the Institute for Auditory Neuroscience to process ABR, IC multielectrode, and histology data associated with animal experiments.

This wiki is organized into two tracks:

| For Users | For Developers |
|---|---|
| Running standard ABR, IC, or histology analyses using existing pipelines and GUIs. No coding experience required. | Extending or modifying the toolbox itself — adding new hardware, experiment types, or analysis methods. |
| **→ Go to [[User Guide]]** | **→ Go to [[Developer Guide]]** |

If you're unsure which applies to you: if you're clicking through GUIs and running example scripts, start with the **User Guide**. If you're opening `.m` files in the editor to change how something works, go to the **Developer Guide**.

---

## 📗 User Guide
*For running standard analyses — no prior coding experience assumed.*
- [[Getting Started – Installation & Toolbox Setup|User-Guide-Getting-Started]]
- [[Getting Started with Git|User-Guide-Git-Basics]] — for absolute beginners to Git
- [[How FEATHER Works (Big Picture)|User-Guide-How-FEATHER-Works]] — what an `anex` is, what "caching" means, where your results go. **Read this before the walkthroughs below.**
- [[ABR Analysis Walkthrough|User-Guide-ABR-Walkthrough]]
- [[IC Analysis Walkthrough|User-Guide-IC-Walkthrough]]
- [[Histology Analysis Walkthrough|User-Guide-Histology-Walkthrough]]
- [[GUI Reference|User-Guide-GUI-Reference]]
- [[FAQ / Troubleshooting|User-Guide-FAQ]]

---

## 📘 Developer Guide
*For extending or maintaining the toolbox itself.*
- [[Architecture Overview|Home/Developer-Guide/Architecture-Overview]] — class hierarchy, data flow, file conventions
- [[Coding Conventions|Home/Developer-Guide/Coding-Conventions]] — naming, caching pattern, `testSafeDir`, folder structure
- [[Adding a new experimental data type object|Home/Developer-Guide/How-to-add-a-new-experimental-data-type-as-a-new-object-class]]
- [[Adding New Hardware|Home/Developer-Guide/Adding-New-Hardware]]
- [[Developer Guide Adding New Stimulus Type for IC|Home/Developer-Guide/Adding-New-Experiment-Type]]
- [[Adding GUI Field|Home/Developer-Guide/Adding-GUI-Field]]
- [[Git Workflow & Testing Before Merging|Home/Developer-Guide/Git-Workflow-&-Testing-Before-Merging]]
- [[Automated Testing Guide|Home/Developer-Guide/Automated-Testing-Guide]]
- [[Known Limitations|Home/Developer-Guide/Known-Limitations]] — `@expsess`, `@oci`, and other early-stage code

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