[All pages](README.md) · [Figure gallery](figures.md)

# Stage 04: alpha power vs age (Figs 3–4)

**Question this stage answers:** how does alpha power change with age in each group,
and how big is the CP − Control gap at each age?

**Code:** [plot_mfdb_alpha_power_vs_age.m](../analyses/primary/04_age_trajectories/plot_mfdb_alpha_power_vs_age.m) (Fig 3)
· [plot_mfdb_alpha_power_difference_vs_age.m](../analyses/primary/04_age_trajectories/plot_mfdb_alpha_power_difference_vs_age.m) (Fig 4)
**Input:** stage 01 120 s spectra + `get_cohort()`
**Output:** `outputs/mfdb_alpha_power_vs_age/`, `outputs/mfdb_alpha_power_difference_vs_age/`

## The steps
1. **One alpha number per child** ([lines 144–150](../analyses/primary/04_age_trajectories/plot_mfdb_alpha_power_vs_age.m#L144)):
   $P_\alpha = 10\log_{10}\int_{8}^{13} \hat S(f)\,df$, plus the same integral on each of the 2,000
   bootstrap spectra. ⚠️ **8–13 Hz** here vs 8–12 Hz in stage 02.
2. **Age windows.**
   - Fig 3: **sliding** windows, half-width 2 yr, step 0.5 yr (each child counts in up to 8 windows).
   - Fig 4: **stationary** 1-yr bins (each child in exactly one bin).
3. **Window summary:** mean $P_\alpha$ of the children in the window (Fig 4: CP mean − Control mean).
4. **CI:** for 2,000 draws, pick one bootstrap value per child in the window, recompute the
   mean (or difference), take the 2.5–97.5th percentiles.

## 🐞 Bug found and fixed: CIs were built from the wrong children
Line 167 of the original script (the fix is at [line 179](../analyses/primary/04_age_trajectories/plot_mfdb_alpha_power_vs_age.m#L179) here) re-sorted the subject table by group, but **not** the list of bootstrap values.
The registry says "CP" and the table says "Patient", so the two lists were in different
orders, and each group's CI was computed from other children's draws.

**Proof** (a private check script, `scripts/stage04_ci_bug_check.m`), same 19 subjects as May:

| | Original code (= May outputs) | Fixed |
|---|---|---|
| Alpha power per child, window means | identical | identical |
| Fig 3 CIs containing their own mean | **0%** | 100% |
| Fig 4 CIs containing their own difference | **0%** | 100% |

Fix: `[results, sortOrder] = sortrows(...)`, then reorder the bootstrap cells the same way.
The estimates (lines in the figures) never changed, only the error bars.

## After the fix: what the CIs mean
With the bug fixed, the CIs follow the published (conditional) logic: each window's
uncertainty from the children's MFDB bootstrap draws. With 2 minutes of EEG per child that
estimation uncertainty is small, so the bars are narrow (≈ ±0.1 dB). That's correct for
the question *"given these children, how precisely is each window's mean estimated?"*

The old wide bars were not a different method; they were the bug (other children's draws).

**Complementary population-level view** (see
[additional_subject_level_inference.md](additional_subject_level_inference.md)): one regression over
all 24 children gives CP − Control = −5.3 dB [−8.5, −2.1], p = 0.002, with no change across
ages (interaction p = 0.86). Some one-year bins hold only 1–3 children per group, so the
age-adjusted model is a useful companion to the per-bin figure.

---
[← 03_power_spectra](03_power_spectra.md) · [05_coherence →](05_coherence.md)
