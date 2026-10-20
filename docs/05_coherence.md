[All pages](README.md) · [Figure gallery](figures.md)

# Stage 05: F3–F4 coherence (left–right frontal coupling)

**Question this stage answers:** how strongly do the left (F3) and right (F4) frontal
signals move together at each frequency, and is that coupling different in CP?

**Code:** [run_subject_f3f4_coherence_for_id.m](../analyses/primary/05_coherence/run_subject_f3f4_coherence_for_id.m)
→ [validate_group_coherence_inputs.m](../analyses/primary/05_coherence/validate_group_coherence_inputs.m)
→ [run_group_f3f4_coherence_analysis.m](../analyses/primary/05_coherence/run_group_f3f4_coherence_analysis.m)
→ plots / [write_…](../analyses/primary/05_coherence/write_group_f3f4_coherence_results.m) (console report) / publication SVG (Fig 07)
**Cohort:** `get_cohort()` subjects that also have F4 → **23** (11 Control, 12 CP; one control has no F4)

## The steps
### 1. Coherence per child (Chronux)
The 120 s epoch is cut into **60 windows of 2 s** (512 samples at 256 Hz). In each window,
multitaper Fourier transforms of F3 and F4 with tapers `[3 5]` ($TW = 3$, $K = 5$ → ±1.5 Hz smoothing):

$$
C(f) = \frac{\left|\langle X_{F3}(f)\,X_{F4}^*(f)\rangle\right|}{\sqrt{\langle|X_{F3}(f)|^2\rangle\,\langle|X_{F4}(f)|^2\rangle}}
\qquad 0 \le C \le 1
$$

($\langle\cdot\rangle$ = average over tapers and windows). 1 = perfectly locked, 0 = unrelated.
`fpass` = 0.5–40 Hz (power uses 1–40 Hz). The script **requires** exactly 256 Hz and both channels.

### 2. Group curves
Median coherence per frequency for each group, plus IQR bands.

### 3. Group test (Bokil et al., Chronux `two_group_test_coherence`)
Compares the two groups' coherence at each frequency via a transformed difference $dz$
(negative = controls > CP) with jackknife variance. Significance: p < 0.001 (primary) or
p < 0.01 (exploratory), kept only in runs ≥ 3 Hz wide (the taper bandwidth).

### 4. Alpha scalar
Each child's mean coherence over 8–13 Hz, then a two-sample t-test (pooled) and rank-sum.

## Two kinds of inference (both valid; they answer different questions)
**Published (primary): Bokil two-group coherence test.** It treats each 2 s window × taper
as a trial (3,300 control + 3,600 CP) and tests whether the two sets of recordings
differ in coherence: conditional inference given these children's data, in the
Chronux/Bokil framework.

**Complementary: population-level tests,** with each child as one observation, asking
whether the difference would generalize to new children.
(a private check script, `scripts/coherence_inference_check.m`)

| Test | Question | Significant |
|---|---|---|
| **Published Bokil test** | these recordings | 2–10.5 Hz and 30–40 Hz (p < 0.001) |
| Child-level permutation, pointwise | new children | 7.5–11.5 Hz (+ 6–6.5 Hz) |
| Child-level cluster test | new children, corrected | 9–11 Hz (p = 0.03) |
| Alpha coherence per child (8–13 Hz) | new children | p ≈ 0.015 (pooled t, Welch, rank-sum agree) |

**Where they agree:** CP has lower frontal alpha coherence (median 0.49 vs 0.59), and alpha is
significant under every test. **Worth knowing for discussion:** at 30–40 Hz the group
medians are close and one control child has high gamma coherence, so that band rests on
the recordings rather than generalizing across children. The pooled-vs-Welch t-test
question doesn't matter here (both p = 0.015).

## Questions to revisit
- Why does the CP median show a small bump at 10–11 Hz while controls have a broad 9–12 Hz plateau? (Possible
  peak-frequency shift; worth plotting individual peak frequencies.)
- fpass 0.5–40 here vs 1–40 for power. Harmless, but should be stated.

---
[← 04_age_trajectories](04_age_trajectories.md) · [06_state_space_model →](06_state_space_model.md)
