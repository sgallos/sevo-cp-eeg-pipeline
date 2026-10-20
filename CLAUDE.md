# sevo-cp-eeg-pipeline — guide for Claude Code

Frontal EEG under sevoflurane: children with cerebral palsy (CP) vs controls,
ages 10–16. F3 multitaper power with a frequency-domain bootstrap (MFDB),
F3–F4 coherence, and a state-space model of the age trajectory.

## Running
- Run MATLAB with `tools/matlab_batch.sh "<command>"` from the repo root. It retries when
  R2024a crashes in a background thread (frequent on macOS 26; not our code).
- Everything starts with `setup_project()` (adds paths, checks toolboxes, returns `paths`).
- `run_all.m` runs every stage; each `%%` section also runs alone.
- Tests: `matlab -batch "runtests('tests')"`. Stage tests compare against
  `referenceOutputsDir` (the original analysis folder) and skip without it.

## Cohort (user rule: always use every eligible subject)
- The ONLY definition of who is analysed: `shared/cohort_criteria.m`, applied by `get_cohort()`.
  Every stage takes its subjects from `get_cohort()`; never hardcode ages or subject lists.
- `check_cohort()` runs at session start (hook in `.claude/settings.local.json`). Read its
  output: report new eligible subjects, or any "CHECK" exclusions, to the user.

## Rules
- We reproduce AND verify. Reproduce the original first (tests), then check the method is
  right. Flag problems in `notes/` and as a draft in `notes/emails_to_collaborators.md`.
- Inference framing: the published MFDB / Bokil analysis is **conditional inference given the
  observed subjects** and is the primary, statistician-endorsed approach. Subject-level
  analyses (`analyses/additional/subject_level_inference/`) answer a different question
  (generalization to new children) and are complementary. Don't call the published
  inference wrong or overstated unless it is truly wrong or has not been validated by a statistician; code bugs are a separate matter and do get fixed.
- No hardcoded paths. Inputs come from `project_paths().dataDir`; outputs go to `outputs/`.
- Analysis parameters live in `shared/mfdb_config.m` or at the top of each stage script.
  Don't change a parameter without saying so; results must match the original analysis.
- Bootstrap steps call `rng(cfg.randomSeed)` so reruns are identical.
- `notes/` is a separate PRIVATE repo (gitignored here). Never copy notes into this repo by
  hand. `docs/` is generated from them by `notes/scripts/export_public_docs.py`, which drops
  subject IDs and private pages and refuses to export if any are left. Edit notes, then rerun
  it; never edit `docs/` directly.
- Don't commit data (`*.mat`, `*.xlsx`) or `config_local.m`.

## Layout
- `analyses/primary/0N_*`: stages in run order (01 subject spectra → 02 cohort →
  03 group power spectra → 04 age trajectories → 05 coherence → 06 state-space model;
  07 age-varying spectrogram is independent).
- `shared/`: config, paths, `mtm.m`, data loading. `external/`: Chronux 2.12 subset.
- `analyses/additional/`: every analysis beyond the published figures (Goal 4 sub-analyses
  go here too). Reads `primary/` outputs, never modifies them; one README per folder.
  First one: `subject_level_inference/` (complementary population-level inference).

## Origin
Code was copied from three folders, which are left untouched:
`~/Documents/MATLAB_Multitaper_Hz_Domain_BTS`, `~/projects/StateSpaceAlpha`,
`~/Documents/peds_cp/src/utils`. Their `INVENTORY.md` / `METHODS.md` explain the history.
