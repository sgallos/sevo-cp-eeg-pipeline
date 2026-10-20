# sevo-cp-eeg-pipeline

Reproducible analysis of frontal EEG recorded under sevoflurane anesthesia in children with
cerebral palsy (CP) and neurotypical controls aged 10–16 years. The pipeline estimates F3 power
spectra by multitaper analysis with a frequency-domain bootstrap, quantifies F3–F4 coherence, and
models how the CP − Control difference changes with age using a state-space model.

All figures, including those for publication, are shown in the **[figure gallery](docs/figures.md)**.

## Requirements
- MATLAB R2024a or later
- Statistics and Machine Learning Toolbox and Signal Processing Toolbox
- The data folder, shared separately with approved collaborators via Dropbox

The required components of Chronux 2.12 are included in `external/`.

## Reproducing the results
1. Download the **Sevofluorane** data folder from the shared Dropbox link.
2. Copy `config_template.m` to `config_local.m`, rename the function inside it to
   `config_local`, and set `dataDir` to the downloaded folder.
3. In MATLAB, from this folder, run
   ```matlab
   results = runtests('tests/test_00_setup.m')   % verifies the installation
   run_all                                       % regenerates every result and figure (about 15 min)
   ```
   Each `%%` section of `run_all.m` can also be run on its own (Cmd/Ctrl+Enter).

## Cohort and inclusion criteria
All stages analyse the same cohort, defined in `shared/cohort_criteria.m`. A child is included if
the recording was made under sevoflurane, the child was aged 10–16 years, channel F3 is present,
and at least 120 s of EEG are available. The final cohort comprises 24 children (12 Control,
12 CP). Coherence analyses use the 23 children who also have channel F4.

The inclusion and exclusion of every recording, with the reason, is listed by
```matlab
check_cohort
```

## Analysis pipeline
The method, parameters, equations, results and verification of each stage are described in
[`docs/`](docs/README.md).

| Stage | Folder | Output | Verification | Methods |
|---|---|---|---|---|
| 01 | `analyses/primary/01_subject_spectra` | Per-subject F3 spectrum and bootstrap | Reproduced and tested | [01](docs/01_subject_spectra.md) |
| 02 | `02_cohort` | Band-power tables and final cohort | Reproduced and tested | [02](docs/02_cohort.md) |
| 03 | `03_power_spectra` | Group power spectra (Figs 1–2) | Reproduced and tested | [03](docs/03_power_spectra.md) |
| 04 | `04_age_trajectories` | Alpha power vs age (additional Figs A1–A2) | Reproduced and tested (CI error corrected) | [04](docs/04_age_trajectories.md) |
| 05 | `05_coherence` | F3–F4 coherence (Fig 7) | Reproduced and tested | [05](docs/05_coherence.md) |
| 06 | `06_state_space_model` | State-space age trajectories (Figs 3–4) | Reproduced and tested | [06](docs/06_state_space_model.md) |
| 07 | `07_age_varying_spectrogram` | Age-varying spectrograms (Figs 5–6) | Reproduced and tested | [07](docs/07_age_varying_spectrogram.md) |

## Additional analyses
Analyses beyond the main figures are in [`analyses/additional/`](analyses/additional/).
They read the outputs of the primary stages and never modify them.

<!-- publication-figures:start -->
## Figures

All figures are in the **[figure gallery](docs/figures.md)**. The main figures intended for publication
(power, Figs 1–6, and coherence, Figs 7–11) are tagged <kbd>For publication</kbd>, and the methods for each
figure are in [`docs/`](docs/README.md).
<!-- publication-figures:end -->

## Contributions

Juan Jose Navarrete Pérez collected the clinical data. Emily Stephen and Emery Brown guided the overall
direction of the project, and Juan Jose Navarrete Pérez and Emery Brown provided the clinical
interpretation of the results. Emily Stephen and Sebastian Gallo jointly directed the analysis. Sebastian
Gallo performed all of the analyses, including their validation and the extension of the original
methods.

## A note on the use of AI: A goal for augmentation, not automation

This project used Claude (Anthropic), an AI model, through Claude Code. Following the principles of
MIT's [report on AI use in teaching, learning and research training](https://aiandeducation.mit.edu/report/)
(2026), this section states how and why it was used and how its work was checked. We encourage anyone
using AI in research to read the report, especially its principle of augmentation rather than
automation.

**Human-led.** The clinical data, the scientific direction, the analysis and the interpretation of the
results come from the authors, whose individual contributions are listed under [Contributions](#contributions).
Every scientific decision was made by the authors, including the cohort definition, the framing of the
statistical inference, the choice of alpha band, which results to report and the selection of figures.

**What Claude did, and why.**
- Reorganised the original scripts into this pipeline, with a single cohort definition, a
  configuration file and `run_all.m`, so that collaborators can reproduce every result from the data
  alone.
- Wrote the test suite in `tests/`, which checks every stage against the original outputs, to confirm
  that the reorganised code gives the same results. This process found an error in the confidence
  intervals of the original alpha-vs-age figures, which was then corrected.
- Implemented additional analyses specified by the authors (population-level inference, the
  state-space smoothness grid, the coherence counterparts of the power figures and the two-stage
  bootstrap), to test how robust the main findings are.
- Drafted the documentation (this README, the methods pages in `docs/` and the figure gallery) and
  formatted figures, so that the methods and results are easy to read and check.

**How its work was checked.** AI tools can produce plausible but incorrect code and text. Every stage
is tested against the original outputs, every reported number is generated by code in this repository,
and each change was reviewed by Sebastian Gallo. Every commit made with Claude is marked
"Co-Authored-By: Claude" in the history. The authors take full responsibility for all content,
including any errors.

**Open to revision.** The instructions Claude followed are in [CLAUDE.md](CLAUDE.md). This statement
will be updated as practice evolves.
