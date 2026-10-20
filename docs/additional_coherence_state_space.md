[All pages](README.md) · [Figure gallery](figures.md)

# Additional analysis: coherence counterparts of the power figures (2026-10-20)

> [!IMPORTANT]
> **CP has lower left–right alpha coherence (≈ −0.13 z, about 0.49 vs 0.59–0.61) by every method, and the gap is stable with age.**
> Delta and theta coherence show no reliable difference, so the coherence effect is alpha-specific.

| Fig 8: coherence state-space trajectories (alpha) | Fig 9: CP − Control coherence gap |
|---|---|
| ![Alpha coherence vs age per group, state-space model](figures/additional/coherence/coherence_ssm_alpha_control_vs_cp.png) | ![CP minus Control alpha coherence gap vs age](figures/additional/coherence/coherence_ssm_alpha_gap.png) |

| Fig 10: coherogram, Control | Fig 11: coherogram, CP |
|---|---|
| ![Median coherence by age window, Control](figures/additional/coherence/coherogram_control.png) | ![Median coherence by age window, CP](figures/additional/coherence/coherogram_cp.png) |

**Why:** a collaborator's request: for every power figure, within reason, a coherence figure. MFDB-based power
figures (Figs 1–2 and A1–A2) are excluded. Started with her suggestion that the state-space analysis
done for power can be done for coherence.
**Code:** [analyses/additional/coherence_state_space/](../analyses/additional/coherence_state_space);
run everything with `run_coherence_figures.m` (after `run_all.m`). The smoothness grid and gallery are the
power versions, run with `"coherence"` ([ssm_measure.m](../analyses/additional/ssm_smoothness_grid/ssm_measure.m)).

## Power figure → coherence counterpart
| Power figure | Coherence counterpart | Figure |
|---|---|---|
| Figs 1–2, 3–4 (MFDB) | excluded; Fig 7 already shows group coherence curves | — |
| Figs 5–6 age-varying spectrograms | **age-varying coherograms** (**Figs 10–11**) | [coherograms](figures/additional/coherence/coherograms.png) |
| Alpha power vs age, every child + age-adjusted | **alpha coherence vs age** (8–13 Hz) | [alpha vs age](figures/additional/coherence/alpha_coherence_vs_age.png) |
| Figs 3–4 state-space trajectories and gap | **coherence state-space** (**Figs 8–9**, alpha); delta/theta/alpha together in additional | [all bands](figures/additional/coherence/coherence_state_space_all_bands.png) |
| Smoothness grid + published-vs-wobbliest gallery | same, for coherence | [alpha gallery](figures/additional/coherence/gallery_alpha.png), [alpha grid](figures/additional/coherence/smoothness_grid_alpha.png) |
| Population-level spectra with clusters | already exists (`subject_level_inference/coherence`) | — |

## Method
- Band coherence per child: $\bar C_i = \text{mean}_{f \in \text{band}}\, C_i(f)$ from the stage 05 curve
  (reproduces stage 05's alpha value exactly for 8–13 Hz).
- Fisher z: $z_i = \operatorname{atanh}(\bar C_i)$; statistics on z; plots back in coherence with $C = \tanh(z)$.
- State-space model as in [stage 06](06_state_space_model.md) with $y_k = z_k$; bands as for power (alpha 8–13 Hz).
- **Two coherence-specific settings:**
  1. Profile-q grid scaled to each band's default q (coherence z values are ~30× smaller than dB).
  2. Bayes factors reported at prior SD **0.3 z** (≈ 3× the children's spread). The fits' default prior
     (SD 10, fine for dB) is absurdly wide for z and penalizes any gap (Lindley's paradox).
- Coherograms: same windows as stage 07 (centres 10–16 yr, ±1.25 yr), median per window, 1–30 Hz.
- Alpha coherence vs age: alpha 8–13 Hz (stage 05's band); same layout as the power version: 4-year
  sliding windows (half-width 2 yr, step 0.5 yr), mean of z per window with a children-resampled 95% CI
  (only where a window has ≥ 3 children); regression $z = \beta_0 + \beta_1\,\text{CP} + \beta_2\,\text{age}$; right panel =
  each child's z adjusted to the mean age, $z_i - \hat\beta_2(\text{age}_i - \overline{\text{age}})$, shown as $\tanh(\cdot)$.

## Results (23 children: 11 Control, 12 CP)
**State-space model** (FixedHeuristicQ; all four versions agree):
| Band | CP − Control | Credible band below 0 | Regression (age-adj.) | group × age |
|---|---|---|---|---|
| Delta | −0.05 z | nowhere | p = 0.14 | p = 0.85 |
| Theta | −0.10 z | nowhere | p = 0.07 | p = 0.97 |
| **Alpha** | **−0.13 z** | **12.3–14.9 yr** | **p = 0.023** | p = 0.31 |

**Smoothness grid:** published setting within 0.27–0.37 log-lik of the best in every band; 64–72 supported cells.
Alpha gap −0.12 to −0.14 z in **every** supported cell, always excluding zero; delta and theta never exclude zero.

**Gap shape** (prior SD 0.3 z): alpha **constant gap** best, log BF vs no gap **+0.9** (≈ 2.5 : 1, weak; gap −0.13 z, 95% CrI −0.23 to −0.02), and preferred
over a widening/flexible gap by ≈ 5 : 1. Delta (−1.1) and theta (−0.2) favour **no gap**.
With 8–12 Hz the constant gap was favoured ≈ 7 : 1; adding 12–13 Hz makes the gap a little smaller (−0.16 → −0.13 z).

**Wobbliest still supported:** alpha keeps the gap below zero from 12.2 to 14.6 yr (a swing at 10–11 yr is
driven by the youngest one or two children); delta and theta stay non-significant.

**Alpha coherence vs age (8–13 Hz):** CP − Control −0.13 z [−0.25, −0.02], p = 0.023; group × age p = 0.31.

**Coherograms:** controls show a strong 9–12 Hz band that strengthens with age; much weaker in CP. Edge
windows are thin (CP at 16 yr is **one child**), so treat edge columns as anecdotal.

## What this means
1. **CP has lower alpha coherence** (≈ −0.13 z, i.e. ≈ 0.49 vs 0.59–0.61), across every method.
2. **It's alpha-specific:** delta and theta show no reliable difference (unlike power, where they were
   lower too but weaker).
3. **The gap is best described as constant with age.** The default-smoothness curve suggests widening, but the
   regression (p = 0.31) and the gap-shape comparison (constant preferred ≈ 5 : 1) don't support it.
4. Same story as power: a focused, age-stable alpha deficit, now in both power and left–right coupling.

---
[← additional_ssm_smoothness_grid](additional_ssm_smoothness_grid.md)
