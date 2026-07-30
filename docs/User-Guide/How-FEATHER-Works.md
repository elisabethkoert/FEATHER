# How FEATHER Works (Big Picture)

This page explains the core ideas behind FEATHER in plain language, with no coding background assumed. Understanding this before you start the ABR/IC/Histology walkthroughs will save you a lot of confusion later — most error messages and unexpected behavior make sense once you understand these few concepts.

If you want the full technical version of this page (class names, properties, file formats), see the Developer Guide's [[Architecture Overview|Developer-Guide-Architecture-Overview]]. This also helps you to understand what is saved where so it is advisable to read through it once.

---

## The filing-cabinet analogy

Think of FEATHER as an electronic filing cabinet for animal experiments.

- **One animal experiment = one binder.** In FEATHER, this binder is called an `anex` (short for "animal experiment"). Every animal you work with gets exactly one `anex`.
- **Inside the binder, you have separate pages/sections for each recording or image you took from that animal.** These are separate FEATHER "objects":
  - `berabr` — one ABR recording
  - `icme` — one inferior colliculus (IC) multielectrode recording
  - `histimg`  — one histology image set

So if you recorded 5 ABR traces and 3 IC recordings from one animal, and imaged its cochlea afterwards, your `anex` binder for that animal will end up containing 5 `berabr` pages, 3 `icme` pages, and some histology pages — all linked together under that one animal.

You don't need to remember class names to work with FEATHER day to day, but you will see these words (`anex`, `berabr`, `icme`) constantly in function names, example scripts, and error messages, so it helps to know what they refer to.

---

## Raw data vs. processed data — and why they're kept apart

FEATHER strictly separates two kinds of data:

- **Raw data**: the original files straight from the recording/imaging hardware. FEATHER never modifies these. They typically live on a shared network drive (for IAN, this is the archive/raw drive).
- **Processed data**: the results FEATHER produces after reading and analysing the raw data — filtered traces, spike lists, calculated thresholds, your manual wave annotations, etc. This is saved separately, in your own personal results folder.

This separation matters for two reasons:

1. **Safety** — your raw data can never accidentally be overwritten by an analysis mistake. FEATHER has a built-in safety check (you may see errors mentioning `archiv`) that blocks you from accidentally saving processed results into the raw/archive folders.
2. **Reproducibility** — because processed results are saved to disk under your own user name, you (or someone else) can come back later and pick up exactly where you left off, without re-running the whole analysis from scratch.

---

## What "caching" actually means for you

You will see the setting `enablecache` in scripts and instructions. This controls one simple question:

> **Should FEATHER reuse results that were already calculated and saved, or should it redo the calculation from the raw data?**

- `enablecache on` → "If a saved result already exists, just load it. Don't waste time recalculating."
- `enablecache off` → "Always go back to the raw data and recalculate, even if a saved result exists already, then overwrite whatever was saved before."

**Rule of thumb for day-to-day analysis:**
- Turn caching **off** the first time you process a new dataset, or whenever you change the way something is calculated and want to redo it properly.
- Turn caching **on** afterwards, so that loading your results later (e.g. to make a plot, or to check something) is fast and doesn't repeat work unnecessarily.

You'll see this pattern constantly in the example scripts:

```matlab
enablecache off   % about to (re)compute something from raw data
...
enablecache on    % now just reload/reuse existing results
```
---

## Where your results actually get saved

Every user has their own results folder, so that multiple people can analyse the same animal without overwriting each other's work. FEATHER builds this location automatically from three pieces of information that get set once per MATLAB session (in your `startup.m`, see [[Getting Started – Installation & Toolbox Setup|User-Guide-Getting-Started]]):

- **who is running the analysis** (your initials/user ID),
- **who performed the animal experiment** (the experimenter's initials),
- **which animal experiment this is** (its experiment ID).

In practice, this means: if you and a labmate both analyse the same animal, you will each get your own separate results folder, and neither of you can accidentally overwrite the other's saved results.

You generally don't need to think about the exact folder path during normal analysis — FEATHER manages it for you once your `startup.m` is configured correctly. If you're curious about the exact folder structure, see the Developer Guide's [[Architecture Overview|Developer-Guide-Architecture-Overview]].

---

## Putting it together: a typical session

A typical FEATHER session for an animal looks roughly like this, regardless of whether you're doing ABR, IC, or histology analysis:

1. **Load or create the `anex`** for your animal — this is your entry point to everything else.
2. **Point FEATHER at the raw data** for the recording type you want to process (ABR, IC, or histology).
3. **Run the initial processing step** for that data type (this reads the raw files and creates the corresponding `berabr`/`icme`/`histimg` objects).
4. **Fill in any required manual input** using the relevant GUI (e.g. marking which optical filter was used, clicking on ABR wave peaks, flagging bad recordings).
5. **Run the analysis functions** you need (thresholds, spike rates, density calculations, etc.), with caching on so repeated calls don't recompute unnecessarily.
6. **Plot or export results.**

Each data-type walkthrough ([[ABR Analysis Walkthrough|User-Guide-ABR-Walkthrough]], [[IC Analysis Walkthrough|User-Guide-IC-Walkthrough]], [[Histology Analysis Walkthrough|User-Guide-Histology-Walkthrough]]) follows exactly this pattern with concrete commands and screenshots.

---

## What's next

Continue to whichever walkthrough matches the data you have:

- [[ABR Analysis Walkthrough|User-Guide-ABR-Walkthrough]]
- [[IC Analysis Walkthrough|User-Guide-IC-Walkthrough]]
- [[Histology Analysis Walkthrough|User-Guide-Histology-Walkthrough]]

Or, if you'd like the full technical breakdown of the classes described here, see the Developer Guide's [[Architecture Overview|Developer-Guide-Architecture-Overview]].
