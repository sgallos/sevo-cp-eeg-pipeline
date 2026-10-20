%% run_all
% Rebuild every result and figure from the raw data, stage by stage.
%
% Run the whole file (F5 / Run), or one section at a time (Cmd/Ctrl+Enter).
% Each section only needs the sections above it to have been run once.
% Outputs go to outputs/; nothing outside this repo is changed.
%
% Who is analysed: get_cohort() (rules in shared/cohort_criteria.m).
% Subjects that already have stage 01/05 outputs are skipped unless
% forceRecompute is true.

%% 0. Setup and cohort check
clear; clc; close all;
repoRoot = fileparts(mfilename('fullpath'));
if isempty(repoRoot), repoRoot = pwd; end
addpath(repoRoot);
paths = setup_project();

forceRecompute = false;   % true = recompute every subject (about 25 s each)

cohort = check_cohort();
cfg = mfdb_config();

%% 1. Stage 01: subject spectra (120 s MFDB, then 4 x 30 s sub-epochs)
for i = 1:height(cohort)
    sid = char(cohort.subjectID(i));
    if forceRecompute || isempty(dir(fullfile(cfg.outputDir, sid, '*_mfdb.mat')))
        run_subject_mfdb_bootstrap_for_id(sid, true, cfg);
    end
end
validate_group_mfdb_inputs();

for i = 1:height(cohort)
    sid = char(cohort.subjectID(i));
    if forceRecompute || isempty(dir(fullfile(cfg.subEpochOutputDir, sid, '*_mfdb_subepochs.mat')))
        run_subject_mfdb_bootstrap_subepochs_for_id(sid, true, cfg);
    end
end

%% 2. Stage 02: band-power tables (delta, theta, alpha) per subject
extract_band_power_subepochs();
collapse_subepoch_power_table_for_ssm();

%% 3. Stage 03: group spectra (Figs 1-2)
run_group_mfdb_bootstrap();
plot_group_mfdb_results();
close all;

%% 4. Stage 04: alpha power vs age (Figs 3-4)
plot_mfdb_alpha_power_vs_age();
close all;
plot_mfdb_alpha_power_difference_vs_age();
close all;

%% 5. Stage 05: F3-F4 coherence (Fig 07)
coherenceCohort = cohort(cohort.hasF4, :);
coherenceDir = fullfile(paths.outputsDir, 'coherence_subject_level');
for i = 1:height(coherenceCohort)
    sid = char(coherenceCohort.subjectID(i));
    if forceRecompute || ~isfile(fullfile(coherenceDir, sid, [sid '_F3F4_coherence.mat']))
        run_subject_f3f4_coherence_for_id(sid, true, true, 'sevo');
    end
end
validate_group_coherence_inputs();
run_group_f3f4_coherence_analysis();
write_group_f3f4_coherence_results();
plot_group_f3f4_coherence_results();
close all;
export_group_f3f4_coherence_publication_svg();
close all;

%% 6. Stage 06: state-space model (Figs 05-06)
% Fits Control / CP / CP-Control age trajectories for delta, theta and alpha
% from the stage 02 power table (about 30 s per band).
bands = state_space_bands();
for b = 1:numel(bands)
    run_power_ssm_scalar_r('bandName', bands(b).name, 'bandLowHz', bands(b).lowHz, ...
        'bandHighHz', bands(b).highHz, 'inputTable', "power_table_for_ssm_subepochs_collapsed.csv", ...
        'powerColumn', bands(b).column, 'qMode', "all", 'outputPrefix', "power_ssm_publication");
    close all;
end
export_fixed_heuristic_power_ssm_publication_figures();
close all;

%% 7. Stage 07: age-varying spectrograms (Figs 02-03)
% Not yet moved into this repo.

%% Done
fprintf('\nAll available stages finished. Results are in %s\n', paths.outputsDir);
