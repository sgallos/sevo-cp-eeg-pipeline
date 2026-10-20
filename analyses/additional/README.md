# Additional analyses

Analyses that extend the main figures. Each folder
- reads the outputs of `analyses/primary/` and never modifies or re-runs them,
- takes its subjects from `get_cohort()`, like every other stage,
- has a README stating the question it addresses and how it differs from `primary/`.

| Folder | Content | Status |
|---|---|---|
| [subject_level_inference](subject_level_inference/) | Population-level inference for Figs 1–2, 7 and A1–A2, resampling children | Tested |
| [ssm_smoothness_grid](ssm_smoothness_grid/) | Profile-likelihood grid over state-space smoothness, comparison of gap shapes, and robustness to the prior and age-gap floor | Tested |
| [coherence_state_space](coherence_state_space/) | Coherence counterparts of the power figures: state-space model on Fisher z, smoothness grid, age-varying coherograms and alpha coherence vs age | Tested |
