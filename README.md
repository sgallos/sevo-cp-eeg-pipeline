# sevo-cp-eeg-pipeline

Frontal EEG under sevoflurane anesthesia in children with cerebral palsy (CP)
and neurotypical controls, ages 10–16: F3 multitaper power spectra with a
frequency-domain bootstrap, F3–F4 coherence, and a state-space model of how the
CP–control difference changes with age.

> 🚧 Work in progress: stages are being added and tested one at a time.

## Requirements
- MATLAB R2024a or newer
- Statistics and Machine Learning Toolbox, Signal Processing Toolbox
- The data folder (shared separately via Dropbox to approved collaborators)

The needed parts of Chronux 2.12 are included in `external/`.

## Quick start
1. Download the **Sevofluorane** data folder from the shared Dropbox link.
2. Copy `config_template.m` to `config_local.m`, rename the function inside to
   `config_local`, and set `dataDir` to the downloaded folder.
3. In MATLAB, from this folder:
   ```matlab
   results = runtests('tests/test_00_setup.m')   % checks your setup
   ```

## Who is analysed
Every stage uses the same cohort: whoever in the data folder meets the rules in
`shared/cohort_criteria.m` (sevoflurane, ages 10–16, F3 present, ≥ 120 s of EEG).
To see who is in, who isn't, and why:
```matlab
check_cohort
```

## Pipeline stages
| Stage | Folder | Produces | Status |
|---|---|---|---|
| 01 | `analyses/primary/01_subject_spectra` | per-subject F3 spectrum + bootstrap | ✅ tested |
| 02 | `02_cohort` | power tables, final cohort | ✅ tested |
| 03 | `03_power_spectra` | group spectra (Figs 1–2) | ✅ tested |
| 04 | `04_age_trajectories` | alpha power vs age (Figs 3–4) | ✅ tested (CI bug fixed) |
| 05 | `05_coherence` | F3–F4 coherence (Fig 07) | ✅ tested |
| 06 | `06_state_space_model` | SSM age trajectories | ⏳ |
| 07 | `07_age_varying_spectrogram` | age-varying spectrograms | ⏳ |
