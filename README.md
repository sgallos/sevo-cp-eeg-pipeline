# sevo-cp-eeg-pipeline

Reproducible analysis of frontal EEG recorded under sevoflurane anesthesia in children with
cerebral palsy (CP) and neurotypical controls aged 10–16 years. The pipeline estimates F3 power
spectra by multitaper analysis with a frequency-domain bootstrap, quantifies F3–F4 coherence, and
models how the CP − Control difference changes with age using a state-space model.

All figures are shown in the **[figure gallery](docs/figures.md)**.

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
## Figures for publication

The main figures (power, Figs 1–6, and coherence, Figs 7–11) are shown in reading order, followed by
the additional analyses, in **[Figures for publication](docs/publication_figures.md)**. Thumbnails of all
figures are in the [figure gallery](docs/figures.md), and the methods for each are in [`docs/`](docs/README.md).
<!-- publication-figures:end -->
