[All pages](README.md) · [Figure gallery](figures.md)

# Additional analysis: subject-level inference (2026-10-19)

**Code:** [analyses/additional/subject_level_inference/](../analyses/additional/subject_level_inference)
· run with `run_subject_level_inference.m` after `run_all.m`
· results in `outputs/additional/subject_level_inference/`

> [!IMPORTANT]
> **The alpha effects generalize to new children.** Resampling children (not spectra), CP alpha power is 4.8 dB lower (p = 0.007; cluster 9.5–11.6 Hz),
> alpha vs age gives −5.3 dB at every age (p = 0.002, no change with age), and alpha coherence is lower (cluster 9–11 Hz).

| Power: CP − Control, children resampled | Alpha power vs age, every child |
|---|---|
| ![Power difference with children-resampled CI and clusters](figures/additional/power_difference_subject_level.png) | ![Alpha power vs age, every child and age-adjusted](figures/additional/alpha_vs_age_subject_level.png) |

**What this is:** a complementary, population-level analysis. The published inference
(MFDB group bootstrap, Bokil test) is **conditional on the observed children**: it asks
whether these recordings differ beyond spectral-estimation uncertainty, and it is the
primary, statistician-endorsed analysis. This analysis asks a second question: **would the
differences generalize to a new sample of children?** It resamples children instead of
spectral estimates. Both are valid; agreement between them strengthens a finding.

## The two tools (in `shared/stats/`, tested on simulated data)
| Tool | What it does | Check on simulated data |
|---|---|---|
| `subject_bootstrap_ci` | Resample **children** with replacement within each group, recompute the summary, take percentiles | 95% CI covers the truth 92% of the time with 12 per group (percentile bootstrap runs a bit narrow at small n; a BCa bootstrap would fix this) |
| `cluster_permutation_test` | Welch $t$ at each frequency; adjacent frequencies above threshold form a **cluster**; compare each cluster's mass $\sum \lvert t \rvert$ with the largest cluster from 5,000 label shuffles | False-positive rate **5.0%** with no true effect; finds a planted effect in the right place |

Cluster test in one line: *"is this run of frequencies bigger than any run that random relabelling of children produces 95% of the time?"* That controls false positives across all frequencies at once (Maris & Oostenveld 2007).

## Results

### Power (Figs 1–2): CP − Control, 12 vs 12
**Clusters (whole 1–40 Hz spectrum, corrected):**
| Range | Direction | p |
|---|---|---|
| **9.5–11.6 Hz** | CP lower | **0.020** |
| 5.1–6.2 Hz | CP lower | 0.040 |

**Band power, one value per child** (difference, 95% CI resampling children, Hedges' g):
| Band | CP − Control | 95% CI | g | p (Welch) |
|---|---|---|---|---|
| delta 1–4 | −3.4 dB | [−5.8, −1.0] | −1.0 | 0.018 |
| theta 4–8 | −3.4 dB | [−5.9, −0.9] | −1.0 | 0.018 |
| **alpha 8–13** | **−4.8 dB** | [−7.9, −1.7] | **−1.2** | **0.007** |
| beta 13–30 | −4.7 dB | [−8.4, −0.7] | −0.9 | 0.028 |
| gamma 30–40 | −3.2 dB | [−6.6, +0.3] | −0.7 | 0.09 |

→ Alpha is the strongest and survives correction for 6 bands (Holm). Delta/theta/beta are
lower too (all g ≈ −1) but only at uncorrected p ≈ 0.02–0.03: **suggestive** of a broadband
reduction, with alpha standing out.

### Alpha vs age (Figs 3–4): one model with all 24 children
$\text{alpha}_i = \beta_0 + \beta_1\,\text{CP}_i + \beta_2\,\text{age}_i + \varepsilon_i$
| | Estimate | 95% CI | p |
|---|---|---|---|
| **CP − Control (age-adjusted)** | **−5.3 dB** | [−8.5, −2.1] | **0.002** |
| Age slope | −0.95 dB / year | | 0.064 |
| Group × age interaction | | | **0.86** |

→ CP alpha is ~5 dB lower **at every age**; no evidence the gap changes with age (10–16 yr).
**No one-year bin has ≥ 3 children in both groups**, so per-bin comparisons can only be
descriptive (still saved in `one_year_bins.csv`, no longer plotted).

**Figure:** left = every child vs age with each group's sliding-window mean; right = each
child's alpha **adjusted to the average age (13.0 yr)**, CP vs Control, one dot per child.
Age adjustment: $\text{alpha}^{adj}_i = \text{alpha}_i - \hat\beta_2(\text{age}_i - \overline{\text{age}})$,
which removes the shared age trend so children of different ages can sit side by side.

### Coherence (Fig 07): 12 CP vs 11 Control
| Test | Result |
|---|---|
| **Alpha coherence per child (8–13 Hz)** | median 0.49 vs 0.59, difference −0.10 [−0.19, −0.02], **g = −1.07** |
| p: pooled t / Welch / rank-sum / permutation | 0.015 / 0.015 / 0.015 / 0.023 |
| Cluster test (Fisher-z, 0.5–40 Hz) | **9–11 Hz, p = 0.032**; nothing else |
| Published Bokil test (conditional, for reference) | 2–10.5 Hz and 30–40 Hz |

## Bottom line: where the two kinds of inference agree
| Finding | Published (conditional, primary) | Population-level (complementary) |
|---|---|---|
| CP has lower alpha power | ✅ | ✅ strongest effect (g ≈ −1.2, cluster 9.5–11.6 Hz) |
| Power lower across frequencies | ✅ most of 1–40 Hz | alpha confirmed; other bands lower (g ≈ −1), p ≈ 0.02–0.03 uncorrected |
| Alpha gap across ages 10–16 | ✅ per window (after bug fix) | ✅ −5.3 dB age-adjusted, constant (interaction p = 0.86) |
| CP has lower alpha coherence | ✅ | ✅ (g ≈ −1.1, cluster 9–11 Hz) |
| Coherence differs at 2–10 and 30–40 Hz | ✅ | alpha range only at the population level |

**Use:** the published analysis carries the paper's claims. This analysis supports them by
showing the alpha effects (power and coherence) also generalize across children, which is
useful for reviewers and for the discussion. The two approaches answer different questions,
so differences outside alpha are expected, not contradictions.

---
[← 07_age_varying_spectrogram](07_age_varying_spectrogram.md) · [additional_ssm_smoothness_grid →](additional_ssm_smoothness_grid.md)
