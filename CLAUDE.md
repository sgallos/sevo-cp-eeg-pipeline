# sevo-cp-eeg-pipeline — guide for Claude Code

Frontal EEG under sevoflurane: children with cerebral palsy (CP) vs controls,
ages 10–16. F3 multitaper power with a frequency-domain bootstrap (MFDB),
F3–F4 coherence, and a state-space model of the age trajectory.

## Running
- MATLAB R2024a: `/Applications/MATLAB_R2024a.app/bin/matlab -batch "..."` from the repo root.
- Everything starts with `setup_project()` (adds paths, checks toolboxes, returns `paths`).
- `run_all.m` runs every stage; each `%%` section also runs alone.
- Tests: `matlab -batch "runtests('tests')"`. Stage tests compare against
  `referenceOutputsDir` (the original analysis folder) and skip without it.

## Rules
- No hardcoded paths. Inputs come from `project_paths().dataDir`; outputs go to `outputs/`.
- Analysis parameters live in `shared/mfdb_config.m` or at the top of each stage script.
  Don't change a parameter without saying so; results must match the original analysis.
- Bootstrap steps call `rng(cfg.randomSeed)` so reruns are identical.
- `notes/` is a separate PRIVATE repo (gitignored here). Never copy notes into this repo
  unless the user asks.
- Don't commit data (`*.mat`, `*.xlsx`) or `config_local.m`.

## Layout
- `analyses/primary/0N_*`: stages in run order (01 subject spectra → 02 cohort →
  03 group power spectra → 04 age trajectories → 05 coherence → 06 state-space model;
  07 age-varying spectrogram is independent).
- `shared/`: config, paths, `mtm.m`, data loading. `external/`: Chronux 2.12 subset.

## Origin
Code was copied from three folders, which are left untouched:
`~/Documents/MATLAB_Multitaper_Hz_Domain_BTS`, `~/projects/StateSpaceAlpha`,
`~/Documents/peds_cp/src/utils`. Their `INVENTORY.md` / `METHODS.md` explain the history.
