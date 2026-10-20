> Methods notes for this pipeline, exported from the authors' working notes. Equations and figures render on GitHub. [All pages](README.md)

# Stage 06: state-space model of the age trajectory (Figs 05–06)

**Question this stage answers:** how does band power change smoothly with age in each
group, and how big is the CP − Control gap at each age, using all 24 children at once?

**Code:** [run_power_ssm_scalar_r.m](../analyses/primary/06_state_space_model/run_power_ssm_scalar_r.m)
(runs the fits, writes tables) → [SS_age_diff_em.m](../analyses/primary/06_state_space_model/SS_age_diff_em.m)
(Kalman filter, smoother, EM) → [export_fixed_heuristic_power_ssm_publication_figures.m](../analyses/primary/06_state_space_model/export_fixed_heuristic_power_ssm_publication_figures.m) (Figs 05–06)
**Input:** stage 02 table (one row per child: age, group, delta/theta/alpha dB). Alpha here is **8–12 Hz**.
**Output:** `outputs/state_space_model/power_ssm_publication_<band>_{summary,trajectories}.csv`,
`outputs/figures/requested_svg_only/05_…, 06_…` (+ PNGs)

## The model, in words
Line the children up by age. Assume the **control curve** $f_0(a)$ and the **CP − Control gap**
$\delta(a)$ both change *smoothly* with age. Each child's measured power is the curve for
their group at their age, plus noise. The model learns both curves at once from all 24 children.

## The model, in equations
State at age $a$: level and slope of each curve,
$\;x(a) = [\,f_0,\ f_0',\ \delta,\ \delta'\,]^\top$.

**How the curves move between neighbouring children** (age gap $h$), an *integrated Wiener process*
(the slope does a random walk, the level integrates the slope):

$$
x_{k} = \begin{bmatrix}1&h&0&0\\0&1&0&0\\0&0&1&h\\0&0&0&1\end{bmatrix} x_{k-1} + w_k,
\qquad
w_k \sim \mathcal N\!\left(0,\ \begin{bmatrix} q_{f0} B_h & 0\\ 0 & q_{\delta} B_h\end{bmatrix}\right),
\quad B_h = \begin{bmatrix} h^3/3 & h^2/2\\ h^2/2 & h\end{bmatrix}
$$

$q$ sets how wiggly a curve may be: small $q$ = nearly straight, large $q$ = flexible.

**What we observe** for child $k$ (group indicator $g_k$ = 1 for CP, 0 for control):

$$
y_k = f_0(a_k) + g_k\,\delta(a_k) + \varepsilon_k,\qquad \varepsilon_k \sim \mathcal N(0,\ r)
$$

A **Kalman filter + smoother** gives each curve's posterior mean and 95% credible band;
**EM** estimates the noise variance $r$.

## Four ways to set $q$ (all run; Figs 05–06 use **FixedHeuristicQ**)
| Version | $q$ | Alpha result: mean gap, ages where band excludes 0 | Notes |
|---|---|---|---|
| **FixedHeuristicQ** (published) | $q_{f0}=q_\delta=\dfrac{(\text{power range})^2}{(\text{age span})^3} = 2.99$ | **−5.2 dB**, 11.0–14.9 yr | EM for $r$ converged (8 iterations) |
| FixedSmoothQ | 0.1 × heuristic | −5.4 dB, 11.0–15.2 yr | converged |
| EM-Joint | estimated by EM | −5.3 dB, 11.0–15.2 yr | stopped at 300 iterations (not converged) |
| Profile-q | best likelihood on a grid | −5.3 dB, 11.0–15.2 yr | $q_\delta$ at the grid floor (10⁻⁸) |

$r = 13.8\ \text{dB}^2$ → noise SD ≈ 3.7 dB per child.

## What changed when moving into the repo
- Paths only: outputs go to `outputs/state_space_model/` (where stage 02 writes its table);
  figures to `outputs/figures/`. Band settings live in `state_space_bands.m`.

## Test results (2026-10-20), `tests/test_06_state_space_model.m`. No randomness, so exact.
| Check | Result |
|---|---|
| Summaries, all 4 versions × 3 bands | **identical** |
| Trajectories, 96 rows × 3 bands | **identical** |
| Figs 05–06 (3 bands, SVG + PNG) | written (12 files) |

## Verification
- **Robust to the smoothing choice:** all four $q$ versions give the same alpha gap (−5.2 to −5.4 dB),
  excluding zero over ~11–15 yr. Delta (≈ −3.5 dB) and theta (≈ −3.6 dB) likewise.
- **Agrees with an independent method:** the population-level regression (additional analysis)
  gives −5.3 dB, the same as the state-space estimate.
- **The noise term $r$ includes child-to-child variation:** each child is one observation, so the
  SD of 3.7 dB matches the between-child spread (3.0–3.6 dB, stage 04). The credible bands
  therefore already reflect how much children differ.
- **Profile-q puts $q_\delta$ at its floor:** the data prefer a gap that barely changes with age.
  That matches the regression (group × age p = 0.86) and is worth one sentence in the methods.
- **EM-Joint didn't converge** within 300 iterations; its answer matches the others, and it isn't
  the published version, so it doesn't matter for the figures.

## Questions to revisit
- Colours: Figs 05–06 use blue = Control, red = CP; Figs 3–4 use orange = Control, blue = CP. Unify (Goal 3).
- Alpha is 8–12 Hz here vs 8–13 Hz in Figs 3–4.
- The x-axis runs to 16 but data stop at 15.2 (oldest child).
