# Coherence counterparts of the power figures

**Aim.** To describe how F3–F4 (left–right frontal) coherence changes with age in each group, and
how large the CP − Control difference is at each age. The state-space analysis applied to power
(stage 06, Figs 3–4) is applied here to coherence (Figs 8–9).

## Method
1. Each child's band coherence is the mean of the stage 05 coherence curve over the band
   (delta 1–4, theta 4–8 and alpha 8–13 Hz, the same edges as the power model).
2. Coherence is converted with the Fisher transform, `z = atanh(C)`, where `C` is the magnitude
   coherence returned by Chronux. Coherence is bounded in [0, 1], whereas `z` is unbounded and
   approximately normal, as the model assumes.
3. The model and its four smoothness versions are those used for power (`run_power_ssm_scalar_r`).
   The Profile-q grid is scaled to each band's default `q`, because coherence `z` values are about
   30 times smaller than power in dB.
4. Control and CP trajectories are back-transformed to coherence with `tanh`. The CP − Control
   difference is shown on the `z` scale, where the model's difference is exact.

Cohort: the 23 children in `get_cohort()` with channel F4.

## Further figures
- `make_coherence_counterparts.m` draws the age-varying coherograms (Figs 10–11, counterparts of
  Figs 5–6) and alpha coherence vs age for every child (counterpart of the power version).
- The smoothness grid and the comparison of the published fit with the least-smooth fit supported by
  the data use the power code with the measure `"coherence"`
  (`analyses/additional/ssm_smoothness_grid/ssm_measure.m`). Outputs go to `smoothness_grid/`.

## Usage
After sections 1–5 of `run_all.m`, run
```matlab
run('analyses/additional/coherence_state_space/run_coherence_figures.m')
```
Results are written to `outputs/additional/coherence_state_space/` (figures, `summary.csv` and the
per-band `coherence_ssm_<band>_*` tables).
