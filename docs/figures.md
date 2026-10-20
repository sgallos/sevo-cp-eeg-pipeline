> Methods notes for this pipeline, exported from the authors' working notes. Equations and figures render on GitHub. [All pages](README.md)

# Figures: new pipeline vs original

Press **Cmd+Shift+V** to see the images. "New" images are read from `../outputs/`,
which the pipeline regenerates (not committed), so they only show on this computer.
Originals are copied into `figures/original/` for comparison.

> Until stages 01–02 are run end to end in the new repo, stage 03 here is computed
> from the **original** stage 01/02 outputs. It's the same code path the tests use.

## Stage 03: group spectra (Figs 1–2)

### Fig 1: group median spectra with 95% CI
| New pipeline | Original |
|---|---|
| ![new](figures/pipeline/mfdb_group_level/01_group_median_mfdb_spectra.png) | ![original](figures/original/01_group_median_mfdb_spectra.png) |

### Fig 2: CP − Control difference with 95% CI
| New pipeline | Original |
|---|---|
| ![new](figures/pipeline/mfdb_group_level/02_group_mfdb_difference_with_ci.png) | ![original](figures/original/02_group_mfdb_difference_with_ci.png) |

### Significance mask, and difference + mask
| New pipeline | Original |
|---|---|
| ![new](figures/pipeline/mfdb_group_level/03_group_mfdb_significance_mask.png) | ![original](figures/original/03_group_mfdb_significance_mask.png) |
| ![new](figures/pipeline/mfdb_group_level/04_group_mfdb_difference_and_significance.png) | ![original](figures/original/04_group_mfdb_difference_and_significance.png) |

### Population-level comparison
See [Additional: population-level inference](#additional-population-level-inference-complementary) below.

## Stage 04: alpha power vs age (Figs 3–4)

### Fig 3: fixed, current 24-subject cohort (top) vs May original (bottom, 19 subjects, CI bug)
With the bug fixed, the bars show the conditional (MFDB) uncertainty, which is small with 2 min
of EEG per child. May's wide bars came from the bug (built from other children's draws). See [04_age_trajectories.md](04_age_trajectories.md).

![new fig 3](figures/pipeline/mfdb_alpha_power_vs_age/mfdb_alpha_f3_10.0_to_16.0_sevo_mean_sliding_hw2.00_step0.50_plot_6B_age_window_with_ci.png)
![may fig 3](figures/original/fig3_may_age_window_with_ci.png)

### Fig 4: CP − Control by 1-year bin, fixed (top) vs May original (bottom)
![new fig 4](figures/pipeline/mfdb_alpha_power_difference_vs_age/mfdb_alpha_difference_f3_10.0_to_16.0_sevo_mean_stationary_hw0.50_step0.50_plot_age_window_difference_with_ci.png)
![may fig 4](figures/original/fig4_may_difference_with_ci.png)

## Stage 05: F3–F4 coherence

### Group curves and significance: new (top) vs original (bottom)
The new pipeline reproduces the numbers exactly. The original PNGs are from April (older plot style/cohort).
See [05_coherence.md](05_coherence.md) for how the published Bokil test and population-level tests compare.

![new](figures/pipeline/coherence_group_level/02_group_f3f4_coherence_combined.png)
![original](figures/original/02_group_f3f4_coherence_combined.png)

### Alpha coherence, one value per child (p ≈ 0.015)
![new](figures/pipeline/coherence_group_level/03_alpha_coherence_scalar_comparison.png)

## Stage 06: state-space model (Figs 05–06), alpha shown
Reproduced exactly (numbers identical). New (top) vs original (bottom). See [06_state_space_model.md](06_state_space_model.md).

### Fig 06: Control and CP trajectories
![new](figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_control_vs_cp.png)
![original](figures/original/ssm/power_ssm_24_subjects_fixed_heuristic_alpha_control_vs_cp.png)

### Fig 05: CP − Control gap with 95% credible band
![new](figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_group_difference.png)
![original](figures/original/ssm/power_ssm_24_subjects_fixed_heuristic_alpha_group_difference.png)

Delta and theta versions: `outputs/figures/power_ssm_24_subjects/figures/`.

## Stage 07: age-varying spectrograms (Figs 02–03)
Reproduced exactly. New (top) vs original (bottom). See [07_age_varying_spectrogram.md](07_age_varying_spectrogram.md).

### Fig 02: Control
![new](figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_control.png)
![original](figures/original/spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_control.png)

### Fig 03: CP
![new](figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_cp.png)
![original](figures/original/spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_cp.png)

## Additional: population-level inference (complementary)
See [additional_subject_level_inference.md](additional_subject_level_inference.md).

![power](figures/additional/power_difference_subject_level.png)
![age](figures/additional/alpha_vs_age_subject_level.png)
![coherence](figures/additional/coherence_subject_level.png)

## Additional: state-space smoothness grid (alpha)
See [additional_ssm_smoothness_grid.md](additional_ssm_smoothness_grid.md). Delta/theta: `outputs/additional/ssm_smoothness_grid/`.

![grid](figures/additional/ssm_smoothness_grid_alpha.png)

## State-space gallery (published vs wobbliest supported)

![alpha](figures/additional/gallery_alpha.png)
![theta](figures/additional/gallery_theta.png)
![delta](figures/additional/gallery_delta.png)

## Additional: coherence counterparts of the power figures
See [additional_coherence_state_space.md](additional_coherence_state_space.md).

### State-space model, all bands (counterpart of Figs 05–06)
![coherence ssm](figures/additional/coherence/coherence_state_space_all_bands.png)

### Published vs wobbliest supported (alpha)
![gallery](figures/additional/coherence/gallery_alpha.png)

### Age-varying coherograms (counterpart of Figs 02–03)
![coherograms](figures/additional/coherence/coherograms.png)

### Alpha coherence vs age (counterpart of the age-adjusted power figure)
![alpha coherence vs age](figures/additional/coherence/alpha_coherence_vs_age.png)
