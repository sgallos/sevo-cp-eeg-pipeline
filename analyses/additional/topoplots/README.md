# Topoplots

**Aim.** To show how alpha power and its CP − Control difference are spread across the scalp, beyond F3.

The spectrum, epoch and alpha band are those of stage 01 (`mtm`, TW 6, K 11, 120 s, 8–13 Hz), applied
to every channel, so the value at F3 is the value in the F3 analyses. Cohort from `get_cohort()`.

| File | Content |
|---|---|
| `run_group_topoplots.m` | CP, Control and CP − Control maps: alpha power, and alpha relative to theta |
| `plot_topoplot_position_check.m` | Maps of known patterns, to see the maps come out the right way round |
| `compute_channel_band_power.m` | Band power at every channel for every child |
| `group_channel_map.m` | Group medians at each channel, applying the rules below |
| `channel_locations.m` | Template positions, `standard-10-5-cap385.elp` |

Needs EEGLAB (`eeglabDir` in `config_local.m`). Outputs go to `outputs/additional/topoplots/`.

**Rules for which channels are drawn.** A channel is usable in a child unless it is all zeros or the
Laplacian used fewer than 3 neighbours. A channel is drawn only if it is usable in at least 8 children
of each group. CP1 is left out because its montage entry lists CP2 instead of CPz.

**Reading the maps.**
- Positions are template positions, not each child's electrodes.
- Colours between the dots are interpolated, and interpolation can overshoot next to a strong value.
- At the edge of the head the Laplacian is one-sided, so power there is not comparable with the middle.
- The maps are descriptive. They carry no statistical test.
- Because of the rule above, the F3 map uses 23 children, one fewer than the F3 analyses. The primary
  analyses are unchanged.
- The bright spot at FT7 is about 7 dB above any other channel, in both groups. Treat it as a suspected
  artefact, not a finding.

**Tests:** `tests/test_topoplots.m` checks that F3 matches stage 01 for every child, that positions and
a known pattern come out correctly, and how group medians handle missing channels.
