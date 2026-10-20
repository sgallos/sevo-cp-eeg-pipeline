# State-space smoothness grid

**Aim.** To determine which smoothness settings of the stage 06 state-space model the data support,
and whether the CP − Control difference depends on that choice.

The model and data are those of stage 06 (Figs 3–4). Only the smoothness settings vary.

## Method (for each band: delta, theta and alpha)
1. **Grid.** The baseline smoothness `q_f0` and the gap smoothness `q_δ` each take the default value
   `qInit = (power range)² / (age span)³` multiplied by 10⁻⁶, 10⁻⁴, 10⁻², 0.1, 0.3, 1, 3, 10, 10² and
   10⁴. This covers the extremes and a finer grid near the default. In every cell the noise
   variance `r` is re-estimated by maximum likelihood, so the surface is a **profile likelihood**.
   Settings within 3 log-likelihood units of the best are considered supported (approximately the
   95% region for two parameters).
2. **Gap shapes.** A flexible, a straight-line, a constant and a zero gap are compared by marginal
   likelihood (log Bayes factors), with prior standard deviations of 3, 10 and 30 dB on the gap.
3. **Robustness.** The published setting is refitted with prior standard deviations of 3, 10 and
   30 dB and with minimum age gaps of 0.01, 0.05 and 0.2 years.

## Usage
After sections 1–6 of `run_all.m`, run
`run('analyses/additional/ssm_smoothness_grid/run_all_bands.m')` (about 1 min).
Results are written to `outputs/additional/ssm_smoothness_grid/<band>/` (`grid.csv`, `gap_shapes.csv`,
`robustness.csv`, `summary.csv` and `smoothness_grid.png`).

## Power and coherence
Both functions take the measure as an argument. `run_ssm_smoothness_grid("alpha", "coherence")` and
`make_candidate_gallery("coherence")` run on F3–F4 coherence (Fisher z) instead of power.
`ssm_measure.m` holds the settings for each measure: the data table, units, display transform
(`tanh` for coherence) and the prior standard deviations for the gap-shape comparison (3, 10 and
30 dB for power; 0.3, 10 and 30 z for coherence). Coherence Bayes factors are reported at 0.3 z,
because a prior standard deviation of 10 z is unrealistically wide.
Coherence outputs are written to `outputs/additional/coherence_state_space/smoothness_grid/`.

## Published and least-smooth fits
`make_candidate_gallery.m` refits two versions per band, the published setting (FixedHeuristicQ) and
the least-smooth ("wobbliest") setting still supported by the data, and draws them side by side with
their settings in `outputs/additional/ssm_smoothness_grid/gallery_<band>.png`.

## Verification
At the published setting, the re-estimated `r` and log-likelihood equal those of the stage 06 EM fit
(`tests/test_ssm_smoothness_grid.m`).
