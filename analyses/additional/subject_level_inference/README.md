# Subject-level inference

**Aim.** To test whether the CP − Control differences would generalize to a new sample of children.

The primary analyses (`analyses/primary/`) use conditional inference. Given these children's
recordings, they ask whether the groups differ beyond spectral-estimation uncertainty (the MFDB
frequency-domain bootstrap and the Bokil two-group coherence test). This folder adds a
complementary, population-level analysis that resamples **children** instead. The two approaches
address different questions, and where they agree the finding holds at both levels.

The EEG processing is unchanged. Spectra, coherence and cohort are taken directly from `primary/`.

| Subfolder | Figures | Method |
|---|---|---|
| `power_spectra/` | 1–2 | Confidence intervals by resampling children (subject bootstrap) and a cluster permutation test across frequencies |
| `age_trajectories/` | A1–A2 | Every child shown individually, and one age-adjusted regression over all children |
| `coherence/` | 7 | Per-child alpha coherence test and a cluster test permuting children |

## Usage
After sections 1–5 of `run_all.m`, run
`run('analyses/additional/subject_level_inference/run_subject_level_inference.m')`.
Results are written to `outputs/additional/subject_level_inference/{power_spectra,age_trajectories,coherence}/`.

The statistical functions are in `shared/stats/`. `subject_bootstrap_ci.m` and `cluster_permutation_test.m`
are validated on simulated data in `tests/test_stats.m`, and `two_stage_window_ci.m` is tested in
`tests/test_04_age_trajectories.m`.
