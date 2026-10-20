[All pages](README.md) · [Figure gallery](figures.md)

# Stage 06: state-space model of the age trajectory (Figs 3–4)

**Question this stage answers:** how does band power change smoothly with age in each
group, and how big is the CP − Control gap at each age, using all 24 children at once?

> [!IMPORTANT]
> **CP alpha power is about 4.9 dB lower than controls, and the gap barely changes with age.**
> The 95% credible band for the gap excludes zero from 11.5 to 14.9 yr.
> All four ways of setting the smoothness agree (−4.9 to −5.1 dB).

| Fig 3: Control and CP trajectories (alpha) | Fig 4: CP − Control gap, 95% credible band |
|---|---|
| ![Alpha power vs age, Control and CP, with credible bands](figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_control_vs_cp.png) | ![CP minus Control alpha gap vs age, with credible band](figures/pipeline/figures/power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_alpha_group_difference.png) |

## The model, in words
Line the children up by age.
Assume the **control curve** $f_0(a)$ and the **CP − Control gap** $\delta(a)$ both change *smoothly* with age.
Each child's measured power is the curve for their group at their age, plus noise.
The model learns both curves at once from all 24 children.

## The model, in equations
The state at age $a$ holds the level and slope of each curve,
$x(a) = [ f_0, f_0', \delta, \delta' ]^\top$.

**How the curves move between neighbouring children** (age gap $h$):

```math
x_{k} = \left[\begin{matrix}1&h&0&0\\0&1&0&0\\0&0&1&h\\0&0&0&1\end{matrix}\right] x_{k-1} + w_k
```

```math
w_k \sim \mathcal N\left(0,\ \left[\begin{matrix} q_{f0} B_h & 0\\ 0 & q_{\delta} B_h\end{matrix}\right]\right)
```

```math
B_h = \left[\begin{matrix} h^3/3 & h^2/2\\ h^2/2 & h\end{matrix}\right]
```

**What we observe** for child $k$ (group indicator $g_k$ = 1 for CP, 0 for control):

```math
y_k = f_0(a_k) + g_k\,\delta(a_k) + \varepsilon_k,\qquad \varepsilon_k \sim \mathcal N(0,\ r)
```

A **Kalman filter + smoother** gives each curve's posterior mean and 95% credible band.
**EM** estimates the noise variance $r$.

<details>
<summary><b>Why this transition, and where</b> $B_h$ <b>comes from</b></summary>

This is an *integrated Wiener process*, in which each curve's slope follows a random walk and its level is the integral of the slope.
If the slope gains random increments with variance $q$ per year, then after an age step $h$ the level and slope
have covariance $q B_h$. The $h^3/3$ term is the level's variance, $h$ is the slope's, and $h^2/2$ is how the two move together.

So $q$ sets how flexible a curve may be. A small $q$ gives a nearly straight curve, and a large $q$ a flexible one.
Children closer in age (small $h$) constrain each other more.
</details>

## Settings
| Setting | Value | Meaning |
|---|---|---|
| Bands | delta 1–4, theta 4–8, **alpha 8–13 Hz** | from the stage 02 table, one value per child |
| Smoothness $q_{f0} = q_\delta$ | $\dfrac{(\text{power range})^2}{(\text{age span})^3} = 2.97$ | "FixedHeuristicQ", the published setting |
| Noise variance $r$ | 13.6 dB² (estimated by EM) | noise SD ≈ 3.7 dB per child |
| Credible band | 95% | from the Kalman smoother's posterior variance |

## Results
| Band | Mean CP − Control gap |
|---|---|
| Delta | ≈ −3.5 dB |
| Theta | ≈ −3.6 dB |
| **Alpha** | **−4.9 dB**, band excludes 0 from 11.5 to 14.9 yr |

<details>
<summary><b>Four ways to set</b> $q$ <b>(all give the same alpha gap)</b></summary>

| Version | $q$ | Alpha: mean gap, ages where band excludes 0 | Notes |
|---|---|---|---|
| **FixedHeuristicQ** (published) | $q_{f0}=q_\delta=2.97$ (heuristic above) | **−4.9 dB**, 11.5–14.9 yr | EM for $r$ converged (7 iterations) |
| FixedSmoothQ | 0.1 × heuristic | −5.1 dB, 11.5–15.2 yr | converged |
| EM-Joint | estimated by EM | −5.0 dB, 11.5–15.2 yr | stopped at 300 iterations (not converged) |
| Profile-q | best likelihood on a grid | −5.0 dB, 11.5–15.2 yr | $q_\delta$ at the grid floor (10⁻⁸) |
</details>

## Verification
- **Robust to the smoothing choice.** All four $q$ versions give the same alpha gap (−4.9 to −5.1 dB),
  excluding zero over ~11.5–15 yr. Delta (≈ −3.5 dB) and theta (≈ −3.6 dB) likewise.
- **Agrees with an independent method.** The population-level regression (additional analysis)
  gives −5.3 dB. It uses each child's full 120 s spectrum rather than the mean of four 30 s
  sub-epochs, so a few tenths of a dB apart is expected.
- **The noise term $r$ includes child-to-child variation.** Each child is one observation, so the
  SD of 3.7 dB matches the between-child spread (3.0–3.6 dB, stage 04). The credible bands
  therefore already reflect how much children differ.
- **Profile-q puts $q_\delta$ at its floor.** The data prefer a gap that barely changes with age.
  That matches the regression (group × age p = 0.86) and is worth one sentence in the methods.
- **EM-Joint did not converge** within 300 iterations. Its answer matches the others, and it is not
  the published version, so it doesn't matter for the figures.

## Questions to revisit
- The x-axis runs to 16 but data stop at 15.2 (oldest child).

## Code and files
- **Code:** [run_power_ssm_scalar_r.m](../analyses/primary/06_state_space_model/run_power_ssm_scalar_r.m)
  (runs the fits, writes tables) → [SS_age_diff_em.m](../analyses/primary/06_state_space_model/SS_age_diff_em.m)
  (Kalman filter, smoother, EM) → [export_fixed_heuristic_power_ssm_publication_figures.m](../analyses/primary/06_state_space_model/export_fixed_heuristic_power_ssm_publication_figures.m) (Figs 3–4).
  Bands: [state_space_bands.m](../analyses/primary/06_state_space_model/state_space_bands.m).
- **Input:** the stage 02 table, with one row per child (age, group, and delta, theta and alpha power in dB).
- **Output:** `outputs/state_space_model/power_ssm_publication_<band>_{summary,trajectories}.csv`, with
  figures in `outputs/figures/` (delta and theta versions there too).

---
[← 05_coherence](05_coherence.md) · [07_age_varying_spectrogram →](07_age_varying_spectrogram.md)
