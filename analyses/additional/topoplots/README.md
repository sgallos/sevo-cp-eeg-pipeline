# Topoplots

**Aim.** To show how delta, theta and alpha power and their CP − Control differences are spread across
the scalp, beyond F3.

The spectrum and epoch are those of stage 01 (`mtm`, TW 6, K 11, 120 s), applied to every channel, and
the band edges are those of the published F3 analyses (delta 1–4, theta 4–8, alpha 8–13 Hz, defined once
in `state_space_bands.m`), so the value at F3 is the value in the F3 analyses. The group and by-age maps
use these edges only, not the state-space model; the model is used only where a figure says so.
Cohort from `get_cohort()`.

| File | Content |
|---|---|
| `run_group_topoplots.m` | Control, CP and CP − Control (Hedges' g, spatial cluster test) for alpha, delta and theta |
| `run_peak_vs_7hz_topoplots.m` | The same for alpha peak vs 7 Hz, beside delta and theta |
| `draw_group_effect_rows.m`, `group_effect_map.m` | Draw those rows; medians, Hedges' g and the cluster test at each electrode |
| `electrode_neighbours.m` | Which electrodes are neighbours for the cluster test |
| `plot_band_by_age.m` | One map per child, youngest to oldest, for alpha, theta, delta or alpha peak vs 7 Hz |
| `run_area_tests.m` | Frontal vs occipital: difference of group medians, permutation p and 95% CI (`area_median_tests.csv`) |
| `frontal_occipital_areas.m`, `area_values.m` | The two areas, and each child's median over its electrodes in an area |
| `run_area_state_space.m` | Frontal and occipital alpha across age with the stage 06 state-space model |
| `run_state_space_maps.m` | The state-space model fitted at every electrode, maps at chosen ages |
| `state_space_fit.m` | Stage 06's published fit (fixed heuristic q, r by EM) for any one value per child |
| `run_specparam_topoplots.m` | Specparam alpha height (three fit ranges) and 1/f background maps |
| `load_map_values.m` | Every per-electrode value the maps use, from the saved tables |
| `save_statistics.m` | Writes `group_map_statistics.csv` (g, t and cluster membership per electrode) |
| `topoplot_channel_rules.m` | Which electrodes and children the maps use |
| `mask_unmeasured_area.m` | Blanks areas with no electrode nearby |
| `excluded_channels.m` | Channels left out of every map, and why |
| `plot_topoplot_position_check.m` | Maps of known patterns, to see the maps come out the right way round |
| `run_area_comparison.m` | CP vs Control in six scalp areas, beside F3 from stage 01 |
| `area_band_power.m`, `scalp_areas.m` | Mean power per area, and which electrodes are in each area |
| `load_channel_band_power.m` | Reuses the saved band power table; recomputes only when it is out of date |
| `compute_channel_band_power.m` | Band power at every channel for every child |
| `group_channel_map.m` | Group medians at each channel, applying the rules below |
| `channel_locations.m` | Template positions, `standard-10-5-cap385.elp` |

Needs EEGLAB (`eeglabDir` in `config_local.m`). Outputs go to `outputs/additional/topoplots/`.

**Rules for which channels are drawn.** A channel is usable in a child unless it is all zeros or the
Laplacian used fewer than 3 neighbours. An electrode is drawn if it is clean in at least 9 of the 12 children
of each group, so group maps use every child who has it (`topoplot_channel_rules.m`). A child gets a by-age
map with at least 24 of those electrodes.
These rules apply to the maps only: the primary analyses keep every child. CP1 is left out because its montage entry lists CP2 instead of CPz. FT7 is left out
because it sits about 15 dB above the other channels at every frequency from delta to gamma, in every
child who has it and in both groups, so it is a recording problem and not brain activity. F7, FC5 and T7
are left out because they list FT7 as a Laplacian neighbour: F7 and FC5 regress on FT7 with slopes of
−0.24 and −0.28, close to the −0.25 the Laplacian predicts. F3 does not use FT7.

**Reading the maps.**
- Control and CP share one colour scale within each band; each band has its own, because delta is about 10 dB above alpha.
- The CP − Control column is Hedges' g on a fixed −1.5 to 1.5 scale, so a colour means the same effect size everywhere.
- Positions are template positions, not each child's electrodes.
- Colours between the dots are interpolated, and interpolation can overshoot next to a strong value.
  Areas far from any drawn electrode are left blank (`mask_unmeasured_area.m`).
- At the edge of the head the Laplacian is one-sided, so power there is not comparable with the middle.
- The spatial cluster test (`shared/stats/spatial_cluster_test.m`) controls false positives over all electrodes; no cluster reaches p < 0.05, so the maps are descriptive. The methods and results are in `docs/topoplots.md`.
- The maps show fewer children than the F3 analyses, so their F3 values differ slightly from the
  published ones.
- Each extra Laplacian neighbour lowers a channel's power by about 1.3 dB. The groups have similar counts
  (3.53 CP, 3.56 Control), so this shapes the maps of single children more than the group difference.

**Tests:** `tests/test_topoplots.m` checks that F3 matches stage 01 for every child, that positions and
a known pattern come out correctly, how group medians handle missing channels, the electrode
neighbours and Hedges' g. `tests/test_stats.m` checks the spatial cluster test on simulated data.

**Area comparison.** A child counts in an area with at least 2 clean electrodes there, and stays in the
other areas otherwise. The p-values are rank-sum tests with Holm correction across areas and bands. It is
an additional, exploratory analysis; the primary analyses do not change.

## Alpha peak and background

`run_peak_vs_7hz_topoplots.m` and `run_specparam_topoplots.m` map two measures of the alpha peak itself, and the
specparam background, in the layout of the band power maps. All are exploratory; F3 absolute power stays primary.

- **Peak vs 7 Hz.** dB power at the child's own alpha peak minus dB power at 7 Hz, each averaged within 0.5 Hz.
  The comparison with 7 Hz comes from Emily Stephen's `runPowerTopoplot.m` in peds_cp, there at a fixed peak. In
  these spectra the dip below alpha has a median of 7.6 Hz at F3. 7 Hz lies in theta, so it is not pure background.
- **Specparam (FOOOF 1.1, Donoghue et al. 2020).** Each channel's spectrum is split into a 1/f background (offset
  and exponent) and peaks. The main fit is 2-30 Hz, `fit_specparam.py` also fits 1-30 and 2-40 Hz, and the settings
  were fixed before any fit. A child with no peak from 7 to 13 Hz gets height 0, so it stays in the maps.

To rebuild: run `export_spectra_for_specparam(get_cohort())` in MATLAB, then from the repo root make a `.venv` with
`requirements.txt`, run `fit_specparam.py`, then `run_specparam_topoplots()`. Spectra are saved once in
`channel_spectra.mat`.
