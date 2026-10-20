[All pages](README.md) · [Figure gallery](figures.md)

# Additional analysis: state-space smoothness grid (2026-10-20)

**Code:** [analyses/additional/ssm_smoothness_grid/](../analyses/additional/ssm_smoothness_grid) · figures
in `outputs/additional/ssm_smoothness_grid/<band>/smoothness_grid.png`

## Why
We wanted a small but intelligent search of how straight or wobbly the curves could be.
What existed before (checked 2026-10-20):
| Earlier search | Limitation |
|---|---|
| `run_power_ssm_q_sweep`, `run_power_ssm_q_grid_2d` | Old **19-subject** cohort (July 9); 2-D grid alpha only, 0.1–10× (no extremes) |
| Profile-q inside stage 06 | Current cohort and wide range, but **`r` held fixed**, so not a true profile likelihood |
| `q_delta_wobble_sweep` | Alpha only, `q_f0` and `r` fixed, no saved outputs |
| Never varied | prior on the starting state, minimum age-gap floor, constant/no-gap models |

## How (equations unchanged from [stage 06](06_state_space_model.md))
- Grid $q_{f0}, q_\delta \in q_{\text{init}} \times \{10^{-6}, 10^{-4}, 10^{-2}, 0.1, 0.3, 1, 3, 10, 10^{2}, 10^{4}\}$, with
  $q_{\text{init}} = (\text{power range})^2/(\text{age span})^3$. Log spacing covers "essentially straight" to "follows every child".
- In each cell, $\hat r = \arg\max_r \log L(q_{f0}, q_\delta, r)$ (1-D search), so
  $\ell_p(q_{f0}, q_\delta) = \max_r \log L$ is a **profile likelihood**. (EM's E-step was near-singular at tiny $q$; direct
  maximization avoids that and matches EM exactly at the published setting: $\hat r = 13.821$, $\log L = -74.552$.)
- **Supported region:** $\ell_p \ge \ell_{\max} - 3$ (likelihood-ratio ≈ 95% region for 2 parameters, $\chi^2_{2,0.95}/2 = 3.0$).
- **Gap shapes** (baseline at its best $q_{f0}$), compared by marginal likelihood:
  flexible / straight line ($q_\delta \to 0$) / constant ($q_\delta \to 0$ and gap slope fixed at 0) / no gap (gap fixed at 0).
  $\log \text{BF} = \log L_{\text{shape}} - \log L_{\text{no gap}}$. Bayes factors depend on the prior on the gap
  (Lindley), so each is computed at prior SD 3, 10 and 30 dB.

## Results (24 children)
| | Delta | Theta | **Alpha** |
|---|---|---|---|
| Published setting vs best (log-lik) | −0.32 | −0.45 | **−0.27** |
| Supported cells / 100 | 65 | 74 | 64 |
| Mean gap, range over supported cells | −3.3 to −3.7 dB | −3.3 to −3.9 dB | **−5.0 to −5.4 dB** |
| Gap excludes 0 in every supported cell | ✅ | ✅ | ✅ |
| Best-supported shape (every band, every prior) | constant | constant | **constant** |
| Constant vs no gap, log BF (prior SD 3 / 10 / 30 dB) | 1.5 / 1.6 / 0.6 | 2.0 / 2.3 / 1.3 | **2.3 / 3.2 / 2.4** |
| Constant gap excludes 0 over | 10.0–15.2 yr | 10.0–15.2 yr | **10.0–15.2 yr** |

**Robustness of the published setting (alpha):** age-gap floor 0.01–0.2 yr changes the mean gap by ≤ 0.03 dB.
Prior SD 30 dB: −5.35 dB (vs −5.20). Prior SD 3 dB pulls the gap toward 0 (−4.5 dB), as an informative prior
centred on "no difference" should; the gap still excludes 0 from 11.7 to 15.2 yr.

## What this means
1. **The published setting is well chosen:** it sits on the flat top of the likelihood, within 0.3–0.45
   log-lik units of the best, in every band.
2. **The gap estimate doesn't depend on the smoothness choice:** across ~65 supported settings it moves by
   less than 0.6 dB, and it excludes zero in all of them.
3. **The data prefer the simplest shape, a constant gap.** In every band and every prior, a constant
   CP − Control offset beats straight-line and flexible gaps. Same conclusion as the regression
   (group × age p = 0.86) and stage 06's Profile-q boundary.
4. **Strength of evidence for a group difference** (constant gap vs none, prior SD 10 dB): alpha
   BF ≈ e^3.2 ≈ 24 (strong); theta ≈ 10 (positive to strong); delta ≈ 5 (positive). Alpha is strongest,
   as everywhere else.
5. **Too wobbly is clearly worse:** at q_δ = 10⁴ × default the alpha log-likelihood drops by 17 units.

---
[← additional_subject_level_inference](additional_subject_level_inference.md) · [additional_coherence_state_space →](additional_coherence_state_space.md)
