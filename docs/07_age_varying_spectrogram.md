[All pages](README.md) · [Figure gallery](figures.md)

# Stage 07: age-varying spectrograms (Figs 5–6)

**Question this stage answers:** what does the whole F3 spectrum (1–30 Hz) look like at each
age, for controls and for CP? A descriptive picture, no statistical test.

> [!IMPORTANT]
> **CP is lower than controls at almost every age and frequency, most strongly around 10–11 Hz (alpha) and 15–25 Hz (beta).**
> This is a descriptive figure without CIs or tests. The statistical claims come from stages 03–06.

| Fig 5: Control | Fig 6: CP |
|---|---|
| ![Median F3 spectrum by age window, Control](figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_control.png) | ![Median F3 spectrum by age window, CP](figures/pipeline/age_varying_spectrogram/age_varying_f3_timeavg_spec_10.0_to_16.0_sevo_primary_cp.png) |

## The method, in words
Compute each child's spectrum over time, then average it into one spectrum per child.
Slide an age window from 10 to 16 years and take the median spectrum of the children inside it.
These medians are stacked side by side, with age on the x-axis, frequency on the y-axis and power as colour.

## The steps, in equations
1. **Spectrogram per child** (Chronux `mtspecgramc`), with 2 s windows stepping by 1 s and tapers `[2 3]` ($TW = 2$, $K = 3$, so ±1 Hz smoothing), over 1–40 Hz.
2. **One spectrum per child.** Each spectrogram is converted to dB and then **averaged over time**,
   $\bar P_i(f) = \frac{1}{N_t}\sum_t 10\log_{10} S_i(t, f)$.
3. **Age windows.** The windows are centred at 10, 11, …, 16 yr and each covers ±1.25 yr.
   In each window, the **median** across the children of that group whose age falls in the window.
   Children count in up to 3 windows.
4. **Heatmaps** of age (x) by frequency (y), coloured by median dB, for Control (Fig 5) and CP (Fig 6).

## Settings
| Setting | Value | Meaning |
|---|---|---|
| Spectrogram windows | 2 s, step 1 s | time resolution |
| Tapers | `[2 3]`: $TW = 2$, $K = 3$ | ±1 Hz smoothing |
| Age windows | centres 10–16 yr, ±1.25 yr | each child counts in up to 3 windows |
| Summary | median across children | per window and frequency |
| Shown | 1–30 Hz | computed to 40 Hz |

## Children per window
| Age centre | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|
| Control | 2 | 4 | 4 | 5 | 7 | 6 | 4 |
| CP | 3 | 5 | 6 | 6 | 5 | 4 | **1** |

The edge windows (10 and 16) rest on few children. The oldest child is 15.2 yr, so the 16-year window mostly covers 14.75–15.2 yr.

## Verification notes
- **Descriptive only.** As its title says, the figure has no CIs or tests. Statistical claims come from stages 03–06.
- **Consistent with the other analyses:** CP is lower than controls almost everywhere, most strongly
  around 10–11 Hz (alpha) and 15–25 Hz (beta).
- **Colour scale:** Figs 5–6 keep the published "jet" map (decision 2026-10-20).
- Averaging in dB over time is a geometric mean of linear power (like stage 02), which is reasonable but should be stated in the methods.

## Code and files
- **Code:** [plot_age_varying_f3_time_averaged_spectrogram.m](../analyses/primary/07_age_varying_spectrogram/plot_age_varying_f3_time_averaged_spectrogram.m).
- **Input:** raw EEG (F3) for the 24 children in `get_cohort()`. Independent of stages 01–06.
- **Output:** `outputs/age_varying_spectrogram/` (Control and CP heatmaps = Figs 5–6, counts, sensitivity versions, CSVs).
  The CP − Control difference map is no longer drawn (decision 2026-10-20), but its numbers stay in the results file.

---
[← 06_state_space_model](06_state_space_model.md) · [additional_subject_level_inference →](additional_subject_level_inference.md)
