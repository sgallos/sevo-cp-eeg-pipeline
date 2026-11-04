[All pages](README.md) · [Figure gallery](figures.md)

# Topoplots: delta, theta and alpha across the scalp

**Code:** [analyses/additional/topoplots/](../analyses/additional/topoplots)
· run `run_group_topoplots`, `run_peak_vs_7hz_topoplots` and `plot_band_by_age` after `run_all.m`
· results in `outputs/additional/topoplots/`

**Question:** the published analyses use one electrode, F3. How are delta, theta and alpha power spread over the
whole scalp in each group, and where do CP and Control differ?

> [!IMPORTANT]
> **CP alpha is lower over most of the scalp, but no single area stands out once all 35 electrodes are tested
> together.** The group maps show the frontal alpha and theta of both groups, and that CP's is weaker.
> At each electrode the CP − Control difference is moderate (median Hedges' g −0.56 for alpha), and the
> spatial cluster test finds no cluster with p < 0.05 (best: alpha, 3 central electrodes, p = 0.057).
> The maps are therefore descriptive. The statistical claims about alpha rest on F3 and on the area tests.

## Figures

### Group maps: alpha, delta and theta
![Band power, group medians, CP - Control as Hedges' g](figures/pipeline/additional/topoplots/band_power_group_topoplots.png)

### Group maps: alpha peak vs 7 Hz, with delta and theta
![Alpha peak vs 7 Hz with delta and theta](figures/pipeline/additional/topoplots/peak_vs_7hz_group_topoplots.png)

### Each child by age
One map per child, youngest to oldest. Control and CP share the colour scale of each band.

| Band | Control | CP |
|---|---|---|
| Alpha | ![Alpha by age, Control](figures/pipeline/additional/topoplots/alpha_by_age_control.png) | ![Alpha by age, CP](figures/pipeline/additional/topoplots/alpha_by_age_cp.png) |
| Theta | ![Theta by age, Control](figures/pipeline/additional/topoplots/theta_by_age_control.png) | ![Theta by age, CP](figures/pipeline/additional/topoplots/theta_by_age_cp.png) |
| Delta | ![Delta by age, Control](figures/pipeline/additional/topoplots/delta_by_age_control.png) | ![Delta by age, CP](figures/pipeline/additional/topoplots/delta_by_age_cp.png) |

## How the maps are made

### 1. Power at every electrode
Each electrode gets the same spectrum as F3 in stage 01: multitaper, time-bandwidth 6, 11 tapers, the same
120 s of EEG, with the Laplacian reference (each electrode minus the mean of its neighbours). Band power is the
mean of the dB spectrum over the band:

```math
P_{\text{band}} = \frac{1}{N_f}\sum_{f \in \text{band}} 10\log_{10} S(f)
```

with delta 1–4 Hz, theta 4–8 Hz and alpha 8–13 Hz, the bands of the state-space model. At F3 this gives exactly
the value used in the published analyses (checked for every child by the tests).

**Alpha peak vs 7 Hz.** Each child's alpha peak frequency $f_{\text{peak}}$ is found once, from the median spectrum
of their clean electrodes (the most prominent maximum from 8 to 13 Hz). Then, at every electrode,

```math
\text{peak vs 7 Hz} = \overline{P}(f_{\text{peak}} \pm 0.5\ \text{Hz}) - \overline{P}(7 \pm 0.5\ \text{Hz})
```

in dB. It measures how tall the alpha peak stands above the dip below it. Any gain that raises the whole spectrum
cancels, because both terms rise by the same amount. The comparison with 7 Hz comes from the lab's earlier topoplot
code.

### 2. Which electrodes are drawn
The recordings have 58 channels. The maps draw 35.

1. **A channel is usable in a child** unless it was all zeros, or the Laplacian could use fewer than 3 neighbours
   (because neighbours were removed as bad channels). With fewer neighbours, the channel is not referenced like
   the others. Of 1,273 child × channel values, 163 have too few neighbours and 1 is all zeros.
2. **Five channels are left out for everyone**, because of recording or montage problems:
   - FT7 sits about 15 dB above every other channel at every frequency, in every child who has it.
   - F7, FC5 and T7 use FT7 as a Laplacian neighbour, so they carry its error.
   - The centro-parietal channel left of CPz has a montage entry that lists the wrong neighbour (the channel right of CPz instead of CPz).
3. **An electrode is drawn** if it is usable in at least 9 of the 12 children of **each** group. Otherwise one
   group's map would rest on too few children. This removes 18 more channels, mostly parietal, occipital and
   temporal ones (for example Pz is usable in only 4 CP children, Oz in 7).

F3 and F4, the electrodes of the published analyses, are drawn.

### 3. Which children appear
- **Group maps:** every child in the cohort (12 Control, 12 CP) counts at every drawn electrode that is usable for
  them. So the number of children differs a little between electrodes (9 to 12 per group).
- **Maps by age:** a child needs at least 24 of the 35 drawn electrodes, so their map is not mostly interpolated.
  One control child has 23 and is left out of the by-age figures (11 Control maps, 12 CP). That child still counts
  in the group maps.
- These rules apply to the maps only. The published analyses keep every child.

### 4. Group maps
At each electrode, the map shows the **median** over the children of the group. Colours between electrodes are
interpolated by EEGLAB's `topoplot`, and areas far from any drawn electrode are left blank. Control and CP share
one colour scale within each row, so the two maps can be compared by eye. Each row has its own scale, because
delta is about 10 dB stronger than alpha.

### 5. By-age maps
The same values, one map per child. The colour scale runs from the 2nd to the 98th percentile of that band
in both groups, so one extreme electrode does not set it and the Control and CP figures compare.

## Statistics: the CP − Control column

### What the colour shows: Hedges' g
A difference in dB means little until you know how much children differ from each other. A gap of 2 dB is large
if every child is within 1 dB of their group, and small if children differ by 5 dB. So the third column shows the
difference in units of how much children vary, **Hedges' g**:

```math
g = \frac{\bar x_{\text{CP}} - \bar x_{\text{Control}}}{s_p}\left(1 - \frac{3}{4(n_{\text{CP}} + n_{\text{Control}}) - 9}\right),
\qquad s_p = \sqrt{\frac{(n_{\text{CP}}-1)s_{\text{CP}}^2 + (n_{\text{Control}}-1)s_{\text{Control}}^2}{n_{\text{CP}} + n_{\text{Control}} - 2}}
```

- $\bar x$ is the group mean, $s$ the standard deviation between children in a group, and $s_p$ the two pooled.
- The bracket is a small correction for having only about 12 children per group.
- $g = -1$ means CP is one between-child standard deviation lower. As a guide, 0.2 is small, 0.5 medium and 0.8 large.
- The colour scale is fixed at −1.5 to +1.5 for every row and figure, so a colour always means the same effect size.

g uses means, while the first two columns show medians. Medians suit the pictures because one unusual child
moves them less. Means are what the test below needs.

### Is a difference real? The spatial cluster test
Testing 35 electrodes separately would find about 2 "significant" ones by chance alone (5% of 35). The
**cluster permutation test** (Maris & Oostenveld, 2007) asks the question once for the whole scalp. It is
the test used for the frequency clusters in the population-level analysis, with neighbouring electrodes in
place of neighbouring frequencies.

**Step 1. A t statistic at each electrode.** Welch's t, which does not assume equal spread in the two groups:

```math
t_e = \frac{\bar x_{\text{CP},e} - \bar x_{\text{Control},e}}{\sqrt{s_{\text{CP},e}^2 / n_{\text{CP},e} + s_{\text{Control},e}^2 / n_{\text{Control},e}}}
```

**Step 2. Clusters.** Electrodes with $|t_e|$ above a threshold that are neighbours and have the same sign form a
cluster. The threshold is the $t$ for $p < 0.05$ with $\min(n_{\text{CP}}, n_{\text{Control}}) - 1 = 11$ degrees of
freedom, $|t| > 2.20$. Two electrodes are neighbours if they share an edge of a triangulation of the cap seen from
above, so each electrode has about 4 neighbours (`electrode_neighbours.m`).

**Step 3. Cluster mass.** Each cluster gets $\text{mass} = \sum_{e \in \text{cluster}} |t_e|$. A large mass means
several neighbouring electrodes, each well above threshold.

**Step 4. What chance produces.** The CP and Control labels are shuffled 5,000 times. Each shuffle keeps every
child's whole map together and gives the largest cluster mass that random labels produce.

**Step 5. p-value.** For a real cluster, the p-value is the share of shuffles whose largest cluster is at least as big:

```math
p = \frac{1 + (\text{number of shuffles whose largest mass} \ge \text{this cluster's mass})}{5000 + 1}
```

Because each shuffle keeps only its largest cluster, the test controls false positives over all electrodes at
once: with no true difference, a cluster with p < 0.05 appears in about 5% of datasets. On simulated data with no
difference it did so in 4.0% of 200 datasets, and on the real alpha data with the labels shuffled in 3.7% of 300.
A planted difference on a patch of electrodes was found, in the right place. Electrodes in a cluster with
p < 0.05 are ringed on the map.

### Results
| Measure | Median g over electrodes | g at F3 | Largest cluster | p |
|---|---|---|---|---|
| Alpha | −0.56 | −1.13 | 3 central electrodes (Cz, C2 and the centro-parietal one right of CPz) | 0.057 |
| Delta | −0.23 | −0.85 | none above threshold | — |
| Theta | −0.33 | −1.00 | F3 alone | 0.35 |
| Alpha peak vs 7 Hz | −0.45 | −0.59 | none above threshold | — |

No cluster reaches p < 0.05, so nothing is ringed.

### How to read this
- **The maps are descriptive.** They show where each band is strong and that CP is lower over most of the scalp,
  most clearly for alpha. They do not show that any one area differs.
- **This is not a contradiction of the F3 result.** F3 was chosen before any map was made, so it is one test with
  no correction, and alpha at F3 is lower in CP (g = −1.13). The cluster test asks a harder question, *where* on the
  scalp the groups differ, and pays for looking at 35 electrodes.
- **Why no cluster forms.** The alpha difference is broad and moderate rather than strong in one place. Clusters
  need neighbouring electrodes that all pass the threshold together. The Laplacian also makes neighbouring
  electrodes less alike, because each one has its neighbours subtracted, so clusters form less easily than in
  unreferenced EEG.
- The threshold (|t| > 2.20) follows the repo's frequency cluster test. It is conservative. It was not changed after
  seeing the results.

## Limits
- Positions are template positions, not each child's electrodes.
- Interpolation can overshoot next to a strong value, and the colour beyond the outermost electrodes is
  extrapolated.
- At the edge of the head the Laplacian is one-sided, so power there is less comparable with the middle.
- Each extra Laplacian neighbour lowers a channel's power by about 1.3 dB. The groups have similar counts
  (3.53 CP, 3.56 Control), so this matters more for single children than for the group difference.

---
[← additional_coherence_state_space](additional_coherence_state_space.md)
