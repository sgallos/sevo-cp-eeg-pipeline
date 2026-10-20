# sevo-cp-eeg-pipeline

Frontal EEG under sevoflurane anesthesia in children with cerebral palsy (CP)
and neurotypical controls, ages 10–16: F3 multitaper power spectra with a
frequency-domain bootstrap, F3–F4 coherence, and a state-space model of how the
CP–control difference changes with age.

Every figure at a glance: **[figure gallery](docs/figures.md)**.

## Requirements
- MATLAB R2024a or newer
- Statistics and Machine Learning Toolbox, Signal Processing Toolbox
- The data folder (shared separately via Dropbox to approved collaborators)

The needed parts of Chronux 2.12 are included in `external/`.

## Quick start
1. Download the **Sevofluorane** data folder from the shared Dropbox link.
2. Copy `config_template.m` to `config_local.m`, rename the function inside to
   `config_local`, and set `dataDir` to the downloaded folder.
3. In MATLAB, from this folder:
   ```matlab
   results = runtests('tests/test_00_setup.m')   % checks your setup
   run_all                                       % rebuilds every result and figure (about 15 min)
   ```
   Each `%%` section of `run_all.m` can also be run on its own (Cmd/Ctrl+Enter).

## Who is analysed
Every stage uses the same cohort: whoever in the data folder meets the rules in
`shared/cohort_criteria.m` (sevoflurane, ages 10–16, F3 present, ≥ 120 s of EEG).
To see who is in, who isn't, and why:
```matlab
check_cohort
```

## Pipeline stages
Each stage's method, parameters and equations, with figures and test results, is written up in
[`docs/`](docs/README.md) (renders on GitHub).

| Stage | Folder | Produces | Status | How it works |
|---|---|---|---|---|
| 01 | `analyses/primary/01_subject_spectra` | per-subject F3 spectrum + bootstrap | ✅ tested | [notes](docs/01_subject_spectra.md) |
| 02 | `02_cohort` | power tables, final cohort | ✅ tested | [notes](docs/02_cohort.md) |
| 03 | `03_power_spectra` | group spectra (Figs 1–2) | ✅ tested | [notes](docs/03_power_spectra.md) |
| 04 | `04_age_trajectories` | alpha power vs age (Figs 3–4) | ✅ tested (CI bug fixed) | [notes](docs/04_age_trajectories.md) |
| 05 | `05_coherence` | F3–F4 coherence (Fig 07) | ✅ tested | [notes](docs/05_coherence.md) |
| 06 | `06_state_space_model` | SSM age trajectories (Figs 05–06) | ✅ tested | [notes](docs/06_state_space_model.md) |
| 07 | `07_age_varying_spectrogram` | age-varying spectrograms (Figs 02–03) | ✅ tested | [notes](docs/07_age_varying_spectrogram.md) |

## Additional analyses
Analyses beyond the published figures live in [`analyses/additional/`](analyses/additional/).
They read the outputs of the primary stages and never change them.

<!-- publication-figures:start -->
## Figures for publication

The main-paper figures, in reading order. Click any figure for full size; every other figure is in the
[figure gallery](docs/figures.md), and how each was made is in [`docs/`](docs/README.md).

### 1. Power spectra, CP vs Control (Figs 1–2)

CP has lower F3 power than controls, most strongly in alpha.

![Fig 1. Median F3 power spectrum per group, 95% CI.](docs/figures/pipeline/mfdb_group_level/01_group_median_mfdb_spectra.png)
**Fig 1.** Median F3 power spectrum per group, 95% CI.

![Fig 2. CP − Control, 95% CI.](docs/figures/pipeline/mfdb_group_level/02_group_mfdb_difference_with_ci.png)
**Fig 2.** CP − Control, 95% CI.

### 2. The spectrum at each age (Figs 02–03)

Descriptive: median spectrum in sliding age windows. CP is lower at almost every age, most in alpha and beta.

| | |
|---|---|
| ![Fig 02. Control.](docs/figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_control.png) | ![Fig 03. CP.](docs/figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_cp.png) |
| **Fig 02.** Control. | **Fig 03.** CP. |

### 3. Alpha power vs age, every child

CP alpha power (8–13 Hz) is lower at every age: −5.3 dB [−8.5, −2.1], p = 0.002, with no change in the gap across ages (p = 0.86).

![One dot per child; right: each child adjusted to the mean age.](docs/figures/additional/alpha_vs_age_subject_level.png)
One dot per child; right: each child adjusted to the mean age.

### 4. Alpha power vs age, state-space model (Figs 05–06)

The state-space model fits smooth age curves to all 24 children at once. CP alpha is ≈ 4.9 dB lower; the 95% credible band excludes zero from 11.5 to 14.9 yr.

| | |
|---|---|
| ![Fig 06. Control and CP trajectories, 95% credible bands.](docs/figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_control_vs_cp.png) | ![Fig 05. CP − Control gap, 95% credible band.](docs/figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_group_difference.png) |
| **Fig 06.** Control and CP trajectories, 95% credible bands. | **Fig 05.** CP − Control gap, 95% credible band. |

### 5. Left–right frontal coherence (Fig 07)

CP has lower left–right alpha coherence (median 0.49 vs 0.59); alpha is significant under every test.

![Fig 07. F3–F4 coherence per group and the two-group test.](docs/figures/pipeline/coherence_group_level/02_group_f3f4_coherence_combined.png)
**Fig 07.** F3–F4 coherence per group and the two-group test.

![Alpha coherence (8–13 Hz), one value per child.](docs/figures/pipeline/coherence_group_level/03_alpha_coherence_scalar_comparison.png)
Alpha coherence (8–13 Hz), one value per child.

### 6. Coherence vs age

The coherence versions of sections 2–4. The alpha coherence gap (≈ −0.13 z) is stable with age; delta and theta show no reliable difference.

![Coherence at each age (counterpart of Figs 02–03).](docs/figures/additional/coherence/coherograms.png)
Coherence at each age (counterpart of Figs 02–03).

![Alpha coherence vs age, every child (counterpart of section 3).](docs/figures/additional/coherence/alpha_coherence_vs_age.png)
Alpha coherence vs age, every child (counterpart of section 3).

![Coherence state-space model, delta/theta/alpha (counterpart of Figs 05–06).](docs/figures/additional/coherence/coherence_state_space_all_bands.png)
Coherence state-space model, delta/theta/alpha (counterpart of Figs 05–06).

---

**Supplementary figures**

### Supplementary A. Does it generalize to new children?

Population-level versions of Figs 1–2 and Fig 07: CIs that resample children, and cluster permutation tests.

![Power: CP − Control with a children-resampled CI and significant clusters.](docs/figures/additional/power_difference_subject_level.png)
Power: CP − Control with a children-resampled CI and significant clusters.

![Coherence: CP − Control with a children-resampled CI and significant clusters.](docs/figures/additional/coherence_subject_level.png)
Coherence: CP − Control with a children-resampled CI and significant clusters.

### Supplementary B. How much does the state-space result depend on smoothness?

A grid of smoothness settings scored by likelihood: the published setting is on the plateau, and the alpha gap excludes zero in every setting the data support.

![Power: likelihood and alpha gap over a grid of smoothness settings.](docs/figures/additional/ssm_smoothness_grid_alpha.png)
Power: likelihood and alpha gap over a grid of smoothness settings.

![Power: published fit (left) vs the wobbliest fit the data still support (right).](docs/figures/additional/gallery_alpha.png)
Power: published fit (left) vs the wobbliest fit the data still support (right).

![Coherence: the same grid.](docs/figures/additional/coherence/smoothness_grid_alpha.png)
Coherence: the same grid.

![Coherence: published vs wobbliest supported.](docs/figures/additional/coherence/gallery_alpha.png)
Coherence: published vs wobbliest supported.

<!-- publication-figures:end -->
