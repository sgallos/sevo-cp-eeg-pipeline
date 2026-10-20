[All pages](README.md) · [Figure gallery](figures.md)

# Additional analysis: state-space smoothness grid (2026-10-20)

**Question.** How much does the state-space result (Figs 3–4) depend on how smooth the curves are allowed to be?

> [!IMPORTANT]
> **Not much.** The published smoothness sits on the flat top of the likelihood in every band.
> Across every setting the data support, the alpha gap stays between −4.7 and −5.2 dB and always excludes zero.
> The best-supported shape is a constant gap of −5.0 dB at all ages [−7.9, −2.1], with a Bayes factor of about 16 against no difference.

| Smoothness grid (alpha) | Published vs wobbliest supported (alpha) |
|---|---|
| ![Likelihood and alpha gap across smoothness settings](figures/additional/ssm_smoothness_grid_alpha.png) | ![Published fit next to the wobbliest fit the data still support](figures/additional/gallery_alpha.png) |

**Code:** [analyses/additional/ssm_smoothness_grid/](../analyses/additional/ssm_smoothness_grid) · figures
in `outputs/additional/ssm_smoothness_grid/<band>/smoothness_grid.png`

## Why
The aim was a small but well-chosen search over how straight or flexible the curves could be.
The earlier searches (checked 2026-10-20) had the following limitations.
| Earlier search | Limitation |
|---|---|
| `run_power_ssm_q_sweep`, `run_power_ssm_q_grid_2d` | Old **19-subject** cohort (July 9); 2-D grid alpha only, 0.1–10× (no extremes) |
| Profile-q inside stage 06 | Current cohort and wide range, but **`r` held fixed**, so not a true profile likelihood |
| `q_delta_wobble_sweep` | Alpha only, `q_f0` and `r` fixed, no saved outputs |
| Never varied | prior on the starting state, minimum age-gap floor, constant/no-gap models |

## How (equations unchanged from [stage 06](06_state_space_model.md))
- The grid is $q_{f0}, q_\delta \in q_{\text{init}} \times \lbrace 10^{-6}, 10^{-4}, 10^{-2}, 0.1, 0.3, 1, 3, 10, 10^{2}, 10^{4}\rbrace$,
  with $q_{\text{init}} = (\text{power range})^2/(\text{age span})^3$. The logarithmic spacing runs from essentially
  straight curves to curves that follow every child.
- In each cell the noise variance is re-estimated, $\hat r = \arg\max_r \log L(q_{f0}, q_\delta, r)$, by a
  one-dimensional search, so $\ell_p(q_{f0}, q_\delta) = \max_r \log L$ is a **profile likelihood**. EM's E-step was
  near-singular at very small $q$. Direct maximization avoids this and matches EM exactly at the published setting
  ($\hat r = 13.594$, $\log L = -74.280$).
- The **supported region** is $\ell_p \ge \ell_{\max} - 3$, the likelihood-ratio region of about 95% for two parameters
  ($\chi^2_{2,0.95}/2 = 3.0$).
- **Gap shapes** are compared by marginal likelihood, with the baseline at its best $q_{f0}$. The shapes are a flexible
  gap, a straight line ($q_\delta \to 0$), a constant ($q_\delta \to 0$ with the gap slope fixed at 0) and no gap (gap
  fixed at 0), with $\log \text{BF} = \log L_{\text{shape}} - \log L_{\text{no gap}}$. Bayes factors depend on the prior
  on the gap (Lindley's paradox), so each is computed at prior SDs of 3, 10 and 30 dB.

## Statistical tests on this page
A p-value is the probability of a difference at least as large as the one observed, if there were no real group difference. Each p-value on this page names its test, which is explained here.

| Test | What it shows |
|---|---|
| Profile-likelihood region | A smoothness setting counts as supported when its log-likelihood is within 3 units of the best, which is approximately a 95% likelihood-ratio region for two parameters. |
| Bayes factor | The ratio of how well two models predict the data. A Bayes factor of 16 means the data are 16 times more likely under a constant gap than under no gap. Its value depends on the prior on the gap. |
| 95% credible band | Comes from the state-space model's posterior distribution, not from a hypothesis test, so it has no p-value. Where the band for the gap excludes 0, the model is at least 95% certain of the gap's sign at that age. |
| Linear regression t-test | Fits $y = \beta_0 + \beta_1 \text{CP} + \beta_2 \text{age}$ to one value per child. The p-value for CP tests whether the groups differ after adjusting for age. Adding a group × age term tests whether the gap changes with age. |

## Results (24 children; alpha 8–13 Hz)
| | Delta | Theta | **Alpha** |
|---|---|---|---|
| Published setting vs best (log-lik) | −0.32 | −0.45 | **−0.24** |
| Supported cells / 100 | 65 | 74 | 64 |
| Mean gap, range over supported cells | −3.3 to −3.7 dB | −3.3 to −3.9 dB | **−4.7 to −5.2 dB** |
| Gap excludes 0 in every supported cell | ✅ | ✅ | ✅ |
| Best-supported shape (every band, every prior) | constant | constant | **constant** |
| Constant vs no gap, log BF (prior SD 3 / 10 / 30 dB) | 1.5 / 1.6 / 0.6 | 2.0 / 2.3 / 1.3 | **2.2 / 2.8 / 1.9** |
| Constant gap excludes 0 over | 10.0–15.2 yr | 10.0–15.2 yr | **10.0–15.2 yr** |

**Robustness of the published setting (alpha).** Changing the minimum age gap from 0.01 to 0.2 yr moves the mean gap
by at most 0.03 dB. With a prior SD of 30 dB the gap is −5.03 dB (vs −4.91 dB). A prior SD of 3 dB pulls the gap toward
zero (−4.4 dB), as an informative prior centred on no difference should, and the gap still excludes zero from 11.7 to
14.9 yr.

## What this means
1. **The published setting is well chosen.** It sits on the flat top of the likelihood, within 0.24–0.45
   log-likelihood units of the best, in every band.
2. **The gap estimate does not depend on the smoothness choice.** Across about 65 supported settings it moves by
   less than 0.6 dB, and it excludes zero in all of them.
3. **The data prefer the simplest shape, a constant gap.** In every band and every prior, a constant
   CP − Control offset beats straight-line and flexible gaps. The regression (group × age interaction, p = 0.86) and stage 06's
   Profile-q boundary reach the same conclusion.
4. **Strength of evidence for a group difference** (constant gap vs none, prior SD 10 dB). The Bayes factor is about
   16 for alpha ($e^{2.8}$, positive to strong), about 10 for theta (positive to strong) and about 5 for delta
   (positive). Alpha is the strongest, as in every other analysis.
5. **Very flexible curves fit clearly worse.** At $q_\delta = 10^4 \times$ the default, the alpha log-likelihood drops by
   about 17 units.

## How this is used (decision 2026-10-20)
- **Main Figs 3–4 stay the published version** (FixedHeuristicQ). The grid shows it sits on the likelihood
  plateau, so it is a well-supported choice.
- **The least-smooth ("wobbliest") setting still supported by the data goes to the additional analyses.** It is drawn
  next to the published fit (`gallery_<band>.png`) to show how far the data can be pushed.

| Band | Wobbliest supported setting | Gap range | Gap below 0 |
|---|---|---|---|
| Alpha | q_f0 ≈ 0, q_δ = 10 × default (29.7) | −6.5 to −1.3 dB | 11.5–14.6 yr |
| Theta | q_f0 = 10×, q_δ = 100× (16.2, 162) | −5.8 to +1.3 dB | 11.0–15.2 yr |
| Delta | q_f0 = 3×, q_δ = 100× (4.56, 152) | −5.4 to +0.3 dB | 11.0–11.7 yr only |

- **The constant-gap result is reported in the text rather than drawn**, because a constant gap plots as a bare
  rectangle. *"A constant-difference model fit best. For alpha, CP was 5.0 dB lower at all ages (95% CrI −7.9 to
  −2.1 dB), with a Bayes factor of about 16 against no difference."*

Suggested methods sentence. *"A 10 × 10 profile-likelihood grid over the baseline and group-difference smoothness
parameters (10⁻⁶ to 10⁴ × the heuristic default, r re-estimated in each cell) showed a broad likelihood plateau
containing the default (Δ log L ≤ 0.45 in all bands). Across all supported settings the CP − Control difference varied by
< 0.6 dB and excluded zero. A constant-difference model was preferred in every band (alpha log BF = 2.8 vs no
difference)."*

---
[← additional_subject_level_inference](additional_subject_level_inference.md) · [additional_coherence_state_space →](additional_coherence_state_space.md)
