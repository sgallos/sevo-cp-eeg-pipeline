# Subject-level inference

**Question:** would the CP vs control differences hold up with a different sample of
children? The published figures (`analyses/primary/`) measure how precisely we measured
*these* 24 children. This folder measures how much the results depend on *which*
children were sampled, which is what a claim about CP vs controls needs.

Nothing about the EEG processing changes: spectra, coherence and cohort come straight
from `primary/`. Only the uncertainty and significance steps differ.

| Subfolder | Figures | Change |
|---|---|---|
| `power_spectra/` | 1–2 | CI by resampling children (subject bootstrap); cluster permutation test over frequencies instead of the ≥ 1 Hz rule |
| `age_trajectories/` | 3–4 | Each child shown individually; error bars from resampling children; no per-bin significance where bins hold 1–5 children |
| `coherence/` | 07 | Per-child alpha coherence test as the main result; significance bands from permuting children, not pooled 2 s windows |

Why: see the "Verification" sections of the stage 03, 04 and 05 notes. In short, the
current tests treat repeated measurements from one child (bootstrap draws, or 300 EEG
windows) as if they came from different children.

Status: planned. Built after Goal 1 (full reproduction) is finished.
