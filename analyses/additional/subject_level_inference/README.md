# Subject-level inference

**Question:** would the CP vs control differences generalize to a new sample of children?

The primary analyses (`analyses/primary/`) use conditional inference: given these
children's recordings, do the groups differ beyond spectral-estimation uncertainty
(MFDB frequency-domain bootstrap; Bokil two-group coherence test). This folder adds a
complementary, population-level view that resamples **children** instead. The two answer
different questions; where they agree, the finding holds at both levels.

Nothing about the EEG processing changes: spectra, coherence and cohort come straight
from `primary/`.

| Subfolder | Figures | Change |
|---|---|---|
| `power_spectra/` | 1–2 | CI by resampling children (subject bootstrap); cluster permutation test across frequencies |
| `age_trajectories/` | 3–4 | Each child shown individually; one age-adjusted model over all children |
| `coherence/` | 07 | Per-child alpha coherence test; cluster test permuting children |

## Run
After `run_all.m` (sections 1–5): `run('analyses/additional/subject_level_inference/run_subject_level_inference.m')`.
Results: `outputs/additional/subject_level_inference/{power_spectra,age_trajectories,coherence}/`.

Statistics live in `shared/stats/`: `subject_bootstrap_ci.m` and `cluster_permutation_test.m`
(validated on simulated data in `tests/test_stats.m`).
