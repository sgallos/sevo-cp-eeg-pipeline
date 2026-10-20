# State-space smoothness grid

**Question:** how straight or wobbly can the stage 06 state-space curves be, which
settings do the data support, and does the CP − Control gap depend on that choice?

Same model, same data as stage 06 (Figs 05–06); only the smoothness settings vary.

## What it runs (per band: delta, theta, alpha)
1. **Grid** of baseline smoothness `q_f0` × gap smoothness `q_δ`, each at the default
   `qInit = (power range)² / (age span)³` times {10⁻⁶, 10⁻⁴, 10⁻², 0.1, 0.3, 1, 3, 10, 10², 10⁴}:
   extremes plus a fine grid near the default. In every cell the noise variance `r` is
   re-fitted by maximum likelihood, so the surface is a **profile likelihood**.
   "Supported" = within 3 log-likelihood units of the best (≈ 95% region for 2 parameters).
2. **Gap shapes:** flexible, straight line, constant, and no gap, compared by marginal
   likelihood (log Bayes factors), at prior SD 3, 10 and 30 dB on the gap.
3. **Robustness** of the published setting to the prior SD (3 / 10 / 30 dB) and the
   minimum age-gap floor (0.01 / 0.05 / 0.2 yr).

## Run
After `run_all.m` sections 1–6: `run('analyses/additional/ssm_smoothness_grid/run_all_bands.m')` (about 1 min).
Results: `outputs/additional/ssm_smoothness_grid/<band>/` (`grid.csv`, `gap_shapes.csv`,
`robustness.csv`, `summary.csv`, `smoothness_grid.png`).

## Candidate gallery
`make_candidate_gallery.m` refits three versions per band (published FixedHeuristicQ, best-fit constant
gap, wobbliest still-supported) and draws them side by side with their settings:
`outputs/additional/ssm_smoothness_grid/gallery_<band>.png`.

## Check
At the published setting the re-fitted `r` and log-likelihood equal stage 06's EM fit
(`tests/test_ssm_smoothness_grid.m`).
