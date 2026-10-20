[All pages](README.md) · [Figure gallery](figures.md)

# Stage 07: age-varying spectrograms (Figs 02–03)

**Question this stage answers:** what does the whole F3 spectrum (1–30 Hz) look like at each
age, for controls and for CP? A descriptive picture, no statistical test.

**Code:** [plot_age_varying_f3_time_averaged_spectrogram.m](../analyses/primary/07_age_varying_spectrogram/plot_age_varying_f3_time_averaged_spectrogram.m)
**Input:** raw EEG (F3) for the 24 children in `get_cohort()`. Independent of stages 01–06.
**Output:** `outputs/age_varying_spectrogram/` (Control and CP heatmaps = Figs 02–03, counts,
sensitivity versions, CSVs). The CP − Control difference map is no longer drawn (decision 2026-10-20);
its numbers stay in the results file.

## The steps
1. **Spectrogram per child** (Chronux `mtspecgramc`): 2 s windows stepping by 1 s, tapers `[2 3]`
   ($TW = 2$, $K = 3$, so ±1 Hz smoothing), 1–40 Hz.
2. **One spectrum per child:** convert to dB, then **average over time**:
   $\bar P_i(f) = \frac{1}{N_t}\sum_t 10\log_{10} S_i(t, f)$.
3. **Age windows:** centres at 10, 11, …, 16 yr, each covering ±1.25 yr. In each window, the **median**
   across the children of that group whose age falls in the window. Children count in up to 3 windows.
4. **Heatmaps:** age (x) × frequency (y), colour = median dB; Control (Fig 02) and CP (Fig 03).

## Children per window
| Age centre | 10 | 11 | 12 | 13 | 14 | 15 | 16 |
|---|---|---|---|---|---|---|---|
| Control | 2 | 4 | 4 | 5 | 7 | 6 | 4 |
| CP | 3 | 5 | 6 | 6 | 5 | 4 | **1** |

The edge windows (10 and 16) rest on few children; the oldest child is 15.2 yr, so "16" is mostly 14.75–15.2.

## Verification notes
- **Descriptive only**, as its title says: no CIs or tests. Statistical claims come from stages 03–06.
- **Consistent with the other analyses:** CP is lower than controls almost everywhere, most strongly
  around 10–11 Hz (alpha) and 15–25 Hz (beta).
- **Colour scale:** the "jet" rainbow map is not perceptually uniform (it can show bands that aren't there).
  A perceptually uniform map (e.g. `parula`) would be safer for Figs 02–03.
- Averaging in dB over time is a geometric mean of linear power (like stage 02), which is fine; say so in methods.

---
[← 06_state_space_model](06_state_space_model.md) · [additional_subject_level_inference →](additional_subject_level_inference.md)
