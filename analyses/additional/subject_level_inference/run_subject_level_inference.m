%% run_subject_level_inference
% Figs 1-4 and 07 with each child as the unit of analysis.
% Needs run_all.m sections 1-5 to have been run (it reads their outputs).
% Results: outputs/additional/subject_level_inference/

%% Setup
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
repoRoot = fileparts(fileparts(fileparts(here)));
addpath(repoRoot);
setup_project();
addpath(genpath(here));

%% Power spectra (Figs 1-2)
power = run_subject_level_power_spectra();
close all;

%% Alpha vs age (Figs 3-4)
age = run_subject_level_age_trajectories();
close all;

%% Coherence (Fig 07)
coherence = run_subject_level_coherence();
close all;
