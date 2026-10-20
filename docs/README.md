# Methods notes

How each stage of the pipeline works: what it computes, its parameters and equations, and
the results. Code links go to the exact files and lines in this repo.

**[Figure gallery](figures.md)**: every figure at a glance.

| Page | Question it answers |
|---|---|
| [Stage 01: one subject's spectrum, plus how sure we are about it](01_subject_spectra.md) | for one child, what does the power spectrum at F3 look like, and how much would it wobble if we could record the same 2 minutes again? |
| [Stage 02: band power per subject, and who is in the cohort](02_cohort.md) | turn each child's spectrum into three numbers (delta, theta, alpha power), and decide which children are in the analysis. |
| [Stage 03: group spectra, CP vs Control (Figs 1–2)](03_power_spectra.md) | what does the typical CP spectrum look like next to the typical control spectrum, and at which frequencies do they differ? |
| [Stage 04: alpha power vs age (Figs 3–4)](04_age_trajectories.md) | how does alpha power change with age in each group, and how big is the CP − Control gap at each age? |
| [Stage 05: F3–F4 coherence (left–right frontal coupling)](05_coherence.md) | how strongly do the left (F3) and right (F4) frontal signals move together at each frequency, and is that coupling different in CP? |
| [Stage 06: state-space model of the age trajectory (Figs 5–6)](06_state_space_model.md) | how does band power change smoothly with age in each group, and how big is the CP − Control gap at each age, using all 24 children at once? |
| [Stage 07: age-varying spectrograms (Figs 7–8)](07_age_varying_spectrogram.md) | what does the whole F3 spectrum (1–30 Hz) look like at each age, for controls and for CP? A descriptive picture, no statistical test. |
| [Additional analysis: subject-level inference](additional_subject_level_inference.md) | do the group differences hold for new children? CIs that resample children, cluster permutation tests, and one age regression over everyone. |
| [Additional analysis: state-space smoothness grid](additional_ssm_smoothness_grid.md) | how much does the state-space result depend on the smoothness setting? A grid of settings, scored by likelihood. |
| [Additional analysis: coherence counterparts of the power figures](additional_coherence_state_space.md) | the coherence counterpart of each power figure (not MFDB-based): state-space model, coherograms, alpha coherence vs age. |

<sub>Generated from the authors' working notes; edits go there, not here.</sub>
