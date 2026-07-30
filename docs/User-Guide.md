# 📗 User Guide

Welcome! This section is for anyone who wants to **run standard analyses** with
FEATHER — ABR thresholding, IC spike analysis, or histology quantification.

**No prior coding experience is assumed.** If you've never used Git
before, that's completely fine — the pages below are designed to walk you
through everything step by step.

---

## 🧭 Where to start

If you are brand new to FEATHER, we recommend working through the pages in
this order:

1. **[Getting Started – Installation & Toolbox Setup](./User-Guide/Getting-Started.md)**
   Set up MATLAB, add the toolbox to your path, and configure your raw/processed
   data locations. Do this first — everything else assumes this is done.

2. **[Getting Started with Git](./User-Guide/Git-Basics.md)**
   FEATHER lives in a Git repository (on GitLab). This page explains what Git
   is in plain language and how to get the latest version of the toolbox onto
   your computer — even if you've never typed a Git command before.

3. **[How FEATHER Works (Big Picture)](./User-Guide/How-FEATHER-Works.md)**
   ⭐ **Please read this before jumping into any of the walkthroughs below.**
   It explains what an `anex` (animal experiment) object is, what "caching"
   means and why it matters, and where your analysis results actually get
   saved. Skipping this page is the #1 cause of confusion later on.

4. Then pick the walkthrough for the data type you're working with:
   - **[ABR Analysis Walkthrough](./User-Guide/ABR-Walkthrough.md)**
   - **[IC Analysis Walkthrough](./User-Guide/IC-Walkthrough.md)**
   - **[Histology Analysis Walkthrough](./User-Guide/Histology-Walkthrough.md)**

5. Keep these two open as references while you work:
   - **[GUI Reference](./User-Guide/GUI-Reference.md)** — explains every button
     and field in the FEATHER GUIs (wave-picking, calibration input, user
     annotation tables, etc.)
   - **[FAQ / Troubleshooting](./User-Guide/FAQ.md)** — common error messages
     and what they mean

---

## 📄 All User Guide Pages

- [Getting Started – Installation & Toolbox Setup](./User-Guide/Getting-Started.md)
- [Getting Started with Git](./User-Guide/Git-Basics.md)
- [How FEATHER Works (Big Picture)](./User-Guide/How-FEATHER-Works.md)
- [ABR Analysis Walkthrough](./User-Guide/ABR-Walkthrough.md)
- [IC Analysis Walkthrough](./User-Guide/IC-Walkthrough.md)
- [Histology Analysis Walkthrough](./User-Guide/Histology-Walkthrough.md)
- [GUI Reference](./User-Guide/GUI-Reference.md)
- [FAQ / Troubleshooting](./User-Guide/FAQ.md)

---

🔧 Looking to modify or extend the toolbox itself instead? Head over to the
**[Developer Guide](./Developer-Guide.md)**.
