[All pages](README.md) · [Figure gallery](figures.md)

# Additional analysis: subject-level inference (2026-10-19)

**Code:** [analyses/additional/subject_level_inference/](../analyses/additional/subject_level_inference)
· run with `run_subject_level_inference.m` after `run_all.m`
· results in `outputs/additional/subject_level_inference/`

> [!IMPORTANT]
> **The alpha effects generalize to new children.** When children rather than spectra are resampled, CP alpha power is 4.8 dB lower
> (p = 0.007, cluster at 9.5–11.6 Hz), the age-adjusted gap is −5.3 dB at every age (p = 0.002, with no change across ages), and alpha
> coherence is lower (cluster at 9–11 Hz).

| Power: CP − Control, children resampled | Alpha power vs age, every child |
|---|---|
| ![Power difference with children-resampled CI and clusters](figures/additional/power_difference_subject_level.png) | ![Alpha power vs age, every child and age-adjusted](figures/additional/alpha_vs_age_subject_level.png) |

**What this is.** A complementary, population-level analysis. The published inference (MFDB group bootstrap and
Bokil test) is **conditional on the observed children**. It asks whether these recordings differ beyond
spectral-estimation uncertainty, and it is the primary, statistician-endorsed analysis. This analysis asks a second
question, **whether the differences would generalize to a new sample of children**, by resampling children instead of
spectral estimates. Both approaches are valid, and agreement between them strengthens a finding.

## The two tools (in `shared/stats/`, tested on simulated data)
| Tool | What it does | Check on simulated data |
|---|---|---|
| `subject_bootstrap_ci` | Resamples **children** with replacement within each group, recomputes the summary and takes percentiles | The 95% CI covers the true value 92% of the time with 12 per group. The percentile bootstrap is slightly narrow at small n, which a BCa bootstrap would correct |
| `cluster_permutation_test` | Computes Welch $t$ at each frequency. Adjacent frequencies above threshold form a **cluster**, whose mass $\sum \lvert t \rvert$ is compared with the largest cluster from 5,000 label shuffles | False-positive rate of **5.0%** with no true effect, and a planted effect is found in the right place |

In short, the cluster test asks whether a run of frequencies is larger than any run that random relabelling of children produces 95% of the time. This controls false positives across all frequencies at once (Maris & Oostenveld 2007).

## Results

### Power (Figs 1–2), CP − Control, 12 vs 12 children
**Clusters** (whole 1–40 Hz spectrum, corrected for multiple comparisons)
| Range | Direction | p |
|---|---|---|
| **9.5–11.6 Hz** | CP lower | **0.020** |
| 5.1–6.2 Hz | CP lower | 0.040 |

**Band power, one value per child** (difference, 95% CI from resampling children, and Hedges' g)
| Band | CP − Control | 95% CI | g | p (Welch) |
|---|---|---|---|---|
| delta 1–4 | −3.4 dB | [−5.8, −1.0] | −1.0 | 0.018 |
| theta 4–8 | −3.4 dB | [−5.9, −0.9] | −1.0 | 0.018 |
| **alpha 8–13** | **−4.8 dB** | [−7.9, −1.7] | **−1.2** | **0.007** |
| beta 13–30 | −4.7 dB | [−8.4, −0.7] | −0.9 | 0.028 |
| gamma 30–40 | −3.2 dB | [−6.6, +0.3] | −0.7 | 0.09 |

Alpha shows the strongest effect and survives Holm correction for the six bands. Delta, theta and beta are also
lower (all g ≈ −1), but only at uncorrected p ≈ 0.02–0.03. This is **suggestive** of a broadband reduction in which
alpha stands out.

### Alpha vs age (Figs A1–A2), one model with all 24 children
$\text{alpha}_i = \beta_0 + \beta_1 \text{CP}_i + \beta_2 \text{age}_i + \varepsilon_i$
| | Estimate | 95% CI | p |
|---|---|---|---|
| **CP − Control (age-adjusted)** | **−5.3 dB** | [−8.5, −2.1] | **0.002** |
| Age slope | −0.95 dB / year | | 0.064 |
| Group × age interaction | | | **0.86** |

CP alpha is about 5 dB lower **at every age**, with no evidence that the gap changes with age (10–16 yr).
**No one-year bin has at least 3 children in both groups**, so per-bin comparisons can only be descriptive. They are
still saved in `one_year_bins.csv` but no longer plotted.

**Figure.** The left panel shows every child against age, with each group's sliding-window mean. The right panel
shows each child's alpha **adjusted to the average age (13.0 yr)**, one dot per child.
The age adjustment, $\text{alpha}^{adj}_i = \text{alpha}_i - \hat\beta_2(\text{age}_i - \overline{\text{age}})$,
removes the shared age trend so that children of different ages can be compared side by side.

### Coherence (Fig 7), 12 CP vs 11 Control children
| Test | Result |
|---|---|
| **Alpha coherence per child (8–13 Hz)** | median 0.49 vs 0.59, difference −0.10 [−0.19, −0.02], **g = −1.07** |
| p: pooled t / Welch / rank-sum / permutation | 0.015 / 0.015 / 0.015 / 0.023 |
| Cluster test (Fisher-z, 0.5–40 Hz) | **9–11 Hz, p = 0.032**; nothing else |
| Published Bokil test (conditional, for reference) | 2–10.5 Hz and 30–40 Hz |

## Where the two kinds of inference agree
| Finding | Published (conditional, primary) | Population-level (complementary) |
|---|---|---|
| CP has lower alpha power | ✅ | ✅ strongest effect (g ≈ −1.2, cluster 9.5–11.6 Hz) |
| Power lower across frequencies | ✅ most of 1–40 Hz | alpha confirmed; other bands lower (g ≈ −1), p ≈ 0.02–0.03 uncorrected |
| Alpha gap across ages 10–16 | ✅ per window (after bug fix) | ✅ −5.3 dB age-adjusted, constant (interaction p = 0.86) |
| CP has lower alpha coherence | ✅ | ✅ (g ≈ −1.1, cluster 9–11 Hz) |
| Coherence differs at 2–10 and 30–40 Hz | ✅ | alpha range only at the population level |

**Use.** The published analysis carries the paper's claims. This analysis supports them by showing that the alpha
effects in power and coherence also generalize across children, which is useful for reviewers and for the discussion.
The two approaches answer different questions, so differences outside alpha are expected rather than contradictory.

---
[← 07_age_varying_spectrogram](07_age_varying_spectrogram.md) · [additional_ssm_smoothness_grid →](additional_ssm_smoothness_grid.md)
