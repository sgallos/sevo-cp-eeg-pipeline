[All pages](README.md) · [Figure gallery](figures.md)

# Figures for publication

The main figures (power, Figs 1–6, and coherence, Figs 7–11) in reading order, followed by the additional
analyses. Select a figure to view it at full size. The methods for each figure are described in the
[methods pages](README.md).

## Power spectra (Figs 1–2)

CP has lower F3 power than controls, most strongly in alpha.

![Fig 1. Group spectra: Median F3 power spectrum per group, 95% CI.](figures/pipeline/mfdb_group_level/01_group_median_mfdb_spectra.png)
**Fig 1.** Group spectra: Median F3 power spectrum per group, 95% CI.

![Fig 2. CP − Control: Difference spectrum, 95% CI.](figures/pipeline/mfdb_group_level/02_group_mfdb_difference_with_ci.png)
**Fig 2.** CP − Control: Difference spectrum, 95% CI.

## State-space model of alpha power vs age (Figs 3–4)

Smooth age curves fitted to all 24 children at once. CP alpha is ≈ 4.9 dB lower; the 95% credible band excludes zero from 11.5 to 14.9 yr.

![Fig 3. State-space trajectories: Alpha power vs age per group, 95% credible bands.](figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_control_vs_cp.png)
**Fig 3.** State-space trajectories: Alpha power vs age per group, 95% credible bands.

![Fig 4. State-space gap: CP − Control vs age, 95% credible band.](figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_group_difference.png)
**Fig 4.** State-space gap: CP − Control vs age, 95% credible band.

## Spectrum at each age (Figs 5–6)

Descriptive: median spectrum in sliding age windows. CP is lower at almost every age, most in alpha and beta.

| | |
|---|---|
| ![Fig 5. Spectrogram, Control: Median spectrum in sliding age windows.](figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_control.png) | ![Fig 6. Spectrogram, CP: Median spectrum in sliding age windows.](figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_cp.png) |
| **Fig 5.** Spectrogram, Control: Median spectrum in sliding age windows. | **Fig 6.** Spectrogram, CP: Median spectrum in sliding age windows. |

## F3–F4 coherence (Fig 7)

CP has lower left–right alpha coherence (median 0.49 vs 0.59); alpha is significant under every test.

![Fig 7. F3–F4 coherence: Coherence per group; Bokil two-group test.](figures/pipeline/coherence_group_level/02_group_f3f4_coherence_combined.png)
**Fig 7.** F3–F4 coherence: Coherence per group; Bokil two-group test.

## State-space model of alpha coherence vs age (Figs 8–9)

The coherence version of Figs 3–4. CP alpha coherence is ≈ 0.13 z lower; the credible band excludes zero from 12.3 to 14.9 yr.

![Fig 8. Coherence state-space trajectories: Alpha coherence vs age per group, 95% credible bands.](figures/additional/coherence/coherence_ssm_alpha_control_vs_cp.png)
**Fig 8.** Coherence state-space trajectories: Alpha coherence vs age per group, 95% credible bands.

![Fig 9. Coherence state-space gap: CP − Control (Fisher z) vs age, 95% credible band.](figures/additional/coherence/coherence_ssm_alpha_gap.png)
**Fig 9.** Coherence state-space gap: CP − Control (Fisher z) vs age, 95% credible band.

## Coherence at each age (Figs 10–11)

The coherence version of Figs 5–6.

| | |
|---|---|
| ![Fig 10. Coherogram, Control: Median coherence in sliding age windows.](figures/additional/coherence/coherogram_control.png) | ![Fig 11. Coherogram, CP: Median coherence in sliding age windows.](figures/additional/coherence/coherogram_cp.png) |
| **Fig 10.** Coherogram, Control: Median coherence in sliding age windows. | **Fig 11.** Coherogram, CP: Median coherence in sliding age windows. |

---

## Additional analyses

All remaining figures, ordered by the main figures they extend. The methods for each are linked from
the [figure gallery](figures.md).

### 1. Do the differences generalize to new children? (extends Figs 1–2, 7)

![Population-level: power. CP − Control, CI resampling children, cluster permutation test.](figures/additional/power_difference_subject_level.png)
**Population-level: power.** CP − Control, CI resampling children, cluster permutation test.

![Population-level: coherence. CP − Control coherence, CI resampling children, cluster permutation test.](figures/additional/coherence_subject_level.png)
**Population-level: coherence.** CP − Control coherence, CI resampling children, cluster permutation test.

![Alpha coherence per child. One value per child; Wilcoxon rank-sum and t-test.](figures/pipeline/coherence_group_level/03_alpha_coherence_scalar_comparison.png)
**Alpha coherence per child.** One value per child; Wilcoxon rank-sum and t-test.

### 2. Alpha power and coherence vs age, by age window and by child

![Fig A1 · Alpha power vs age, two-stage CI. 4-year sliding windows; CI resamples children, then each child's MFDB draw.](figures/pipeline/mfdb_alpha_power_vs_age/mfdb_alpha_f3_10.0_to_16.0_sevo_mean_sliding_hw2.00_step0.50_plot_6C_age_window_two_stage_ci.png)
**Fig A1 · Alpha power vs age, two-stage CI.** 4-year sliding windows; CI resamples children, then each child's MFDB draw.

![Fig A2 · Alpha gap by age, two-stage CI. CP − Control, 4-year sliding windows; same two-stage CI.](figures/pipeline/mfdb_alpha_power_difference_vs_age/mfdb_alpha_difference_f3_10.0_to_16.0_sevo_mean_stationary_hw0.50_step0.50_plot_age_window_difference_two_stage_ci.png)
**Fig A2 · Alpha gap by age, two-stage CI.** CP − Control, 4-year sliding windows; same two-stage CI.

![Fig A1 · Alpha power vs age, MFDB-only CI (as published). Measurement uncertainty given these children (≈ ±0.04 dB).](figures/pipeline/mfdb_alpha_power_vs_age/mfdb_alpha_f3_10.0_to_16.0_sevo_mean_sliding_hw2.00_step0.50_plot_6B_age_window_with_ci.png)
**Fig A1 · Alpha power vs age, MFDB-only CI (as published).** Measurement uncertainty given these children (≈ ±0.04 dB).

![Fig A2 · Alpha gap by 1-year bin, MFDB-only CI (as published). CP − Control in 1-year bins; measurement uncertainty only.](figures/pipeline/mfdb_alpha_power_difference_vs_age/mfdb_alpha_difference_f3_10.0_to_16.0_sevo_mean_stationary_hw0.50_step0.50_plot_age_window_difference_with_ci.png)
**Fig A2 · Alpha gap by 1-year bin, MFDB-only CI (as published).** CP − Control in 1-year bins; measurement uncertainty only.

![Alpha power vs age, every child. Every child, and age-adjusted by group; linear regression.](figures/additional/alpha_vs_age_subject_level.png)
**Alpha power vs age, every child.** Every child, and age-adjusted by group; linear regression.

![Alpha coherence vs age, every child. Every child, and age-adjusted by group; linear regression.](figures/additional/coherence/alpha_coherence_vs_age.png)
**Alpha coherence vs age, every child.** Every child, and age-adjusted by group; linear regression.

### 3. Delta and theta state-space models (extends Figs 3–4, 8–9)

![Power: Delta (1–4 Hz) trajectories. Control and CP, 95% credible bands.](figures/additional/power_ssm_delta_control_vs_cp.png)
**Power: Delta (1–4 Hz) trajectories.** Control and CP, 95% credible bands.

![Power: Delta (1–4 Hz) gap. CP − Control, 95% credible band.](figures/additional/power_ssm_delta_group_difference.png)
**Power: Delta (1–4 Hz) gap.** CP − Control, 95% credible band.

![Power: Theta (4–8 Hz) trajectories. Control and CP, 95% credible bands.](figures/additional/power_ssm_theta_control_vs_cp.png)
**Power: Theta (4–8 Hz) trajectories.** Control and CP, 95% credible bands.

![Power: Theta (4–8 Hz) gap. CP − Control, 95% credible band.](figures/additional/power_ssm_theta_group_difference.png)
**Power: Theta (4–8 Hz) gap.** CP − Control, 95% credible band.

![Coherence: Delta (1–4 Hz) trajectories. Control and CP, 95% credible bands.](figures/additional/coherence/coherence_ssm_delta_control_vs_cp.png)
**Coherence: Delta (1–4 Hz) trajectories.** Control and CP, 95% credible bands.

![Coherence: Delta (1–4 Hz) gap. CP − Control (Fisher z), 95% credible band.](figures/additional/coherence/coherence_ssm_delta_gap.png)
**Coherence: Delta (1–4 Hz) gap.** CP − Control (Fisher z), 95% credible band.

![Coherence: Theta (4–8 Hz) trajectories. Control and CP, 95% credible bands.](figures/additional/coherence/coherence_ssm_theta_control_vs_cp.png)
**Coherence: Theta (4–8 Hz) trajectories.** Control and CP, 95% credible bands.

![Coherence: Theta (4–8 Hz) gap. CP − Control (Fisher z), 95% credible band.](figures/additional/coherence/coherence_ssm_theta_gap.png)
**Coherence: Theta (4–8 Hz) gap.** CP − Control (Fisher z), 95% credible band.

### 4. How much do the state-space results depend on smoothness? (extends Figs 3–4, 8–9)

![Power: Delta (1–4 Hz) smoothness grid. Likelihood and gap across smoothness settings.](figures/additional/ssm_smoothness_grid_delta.png)
**Power: Delta (1–4 Hz) smoothness grid.** Likelihood and gap across smoothness settings.

![Power: Delta (1–4 Hz) published vs wobbliest. Least-smooth fit the data still support.](figures/additional/gallery_delta.png)
**Power: Delta (1–4 Hz) published vs wobbliest.** Least-smooth fit the data still support.

![Power: Theta (4–8 Hz) smoothness grid. Likelihood and gap across smoothness settings.](figures/additional/ssm_smoothness_grid_theta.png)
**Power: Theta (4–8 Hz) smoothness grid.** Likelihood and gap across smoothness settings.

![Power: Theta (4–8 Hz) published vs wobbliest. Least-smooth fit the data still support.](figures/additional/gallery_theta.png)
**Power: Theta (4–8 Hz) published vs wobbliest.** Least-smooth fit the data still support.

![Power: Alpha (8–13 Hz) smoothness grid. Likelihood and gap across smoothness settings.](figures/additional/ssm_smoothness_grid_alpha.png)
**Power: Alpha (8–13 Hz) smoothness grid.** Likelihood and gap across smoothness settings.

![Power: Alpha (8–13 Hz) published vs wobbliest. Least-smooth fit the data still support.](figures/additional/gallery_alpha.png)
**Power: Alpha (8–13 Hz) published vs wobbliest.** Least-smooth fit the data still support.

![Coherence: Delta (1–4 Hz) smoothness grid. Likelihood and gap across smoothness settings.](figures/additional/coherence/smoothness_grid_delta.png)
**Coherence: Delta (1–4 Hz) smoothness grid.** Likelihood and gap across smoothness settings.

![Coherence: Delta (1–4 Hz) published vs wobbliest. Least-smooth fit the data still support.](figures/additional/coherence/gallery_delta.png)
**Coherence: Delta (1–4 Hz) published vs wobbliest.** Least-smooth fit the data still support.

![Coherence: Theta (4–8 Hz) smoothness grid. Likelihood and gap across smoothness settings.](figures/additional/coherence/smoothness_grid_theta.png)
**Coherence: Theta (4–8 Hz) smoothness grid.** Likelihood and gap across smoothness settings.

![Coherence: Theta (4–8 Hz) published vs wobbliest. Least-smooth fit the data still support.](figures/additional/coherence/gallery_theta.png)
**Coherence: Theta (4–8 Hz) published vs wobbliest.** Least-smooth fit the data still support.

![Coherence: Alpha (8–13 Hz) smoothness grid. Likelihood and gap across smoothness settings.](figures/additional/coherence/smoothness_grid_alpha.png)
**Coherence: Alpha (8–13 Hz) smoothness grid.** Likelihood and gap across smoothness settings.

![Coherence: Alpha (8–13 Hz) published vs wobbliest. Least-smooth fit the data still support.](figures/additional/coherence/gallery_alpha.png)
**Coherence: Alpha (8–13 Hz) published vs wobbliest.** Least-smooth fit the data still support.
