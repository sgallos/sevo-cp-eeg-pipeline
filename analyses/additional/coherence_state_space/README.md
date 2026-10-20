# Coherence counterparts of the power figures

**Question:** how does F3–F4 (left–right frontal) coherence change with age in each group,
and how big is the CP − Control gap at each age? The same state-space analysis as for power
(stage 06, Figs 05–06), applied to coherence.

## What it does
1. Each child's band coherence = mean of their stage 05 coherence curve over the band
   (delta 1–4, theta 4–8, alpha 8–12 Hz; same edges as the power model).
2. Fisher z, `z = atanh(C)` (Chronux returns magnitude coherence). Coherence is bounded in
   [0, 1]; z is unbounded and close to normal, as the model assumes.
3. Same model and same four smoothness versions as for power (`run_power_ssm_scalar_r`). The
   Profile-q grid is scaled to each band's default q (coherence z values are ~30× smaller than dB).
4. Figures: Control and CP trajectories back-transformed to coherence (`tanh`); the CP − Control
   gap on the z scale, where the model's difference is exact.

Cohort: `get_cohort()` children with F4 (23).

## Also here
- `make_coherence_counterparts.m`: age-varying coherograms (counterpart of Figs 02–03) and alpha
  coherence vs age (counterpart of the every-child + age-adjusted power figure).
- Smoothness grid and published-vs-wobbliest gallery: the power versions run with `"coherence"`
  (`analyses/additional/ssm_smoothness_grid/ssm_measure.m`), written to `smoothness_grid/`.

## Run
After `run_all.m` sections 1–5:
```matlab
run('analyses/additional/coherence_state_space/run_coherence_figures.m')
```
Results: `outputs/additional/coherence_state_space/` (`coherence_state_space_all_bands.png`,
`summary.csv`, per-band `coherence_ssm_<band>_*` tables).
