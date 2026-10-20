# Additional analyses

Analyses beyond the published figures. Each folder:
- reads the outputs of `analyses/primary/` (it never changes or re-runs them),
- gets its subjects from `get_cohort()`, like everything else,
- has a README saying what question it answers and how it differs from `primary/`.

| Folder | What it does | Status |
|---|---|---|
| [subject_level_inference](subject_level_inference/) | Complementary population-level inference for Figs 1–4 and 07 (resampling children) | ✅ tested |
