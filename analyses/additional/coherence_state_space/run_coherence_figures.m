%% run_coherence_figures
% Coherence counterparts of the power figures (Emily, 2026-10-20). Needs
% run_all.m sections 1-5. MFDB-based power figures (Figs 1-4) have no
% counterpart here. Results: outputs/additional/coherence_state_space/
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
repoRoot = fileparts(fileparts(fileparts(here)));
addpath(repoRoot);
setup_project();
addpath(here);
addpath(fullfile(repoRoot, 'analyses', 'additional', 'ssm_smoothness_grid'));

%% State-space model (counterpart of Figs 05-06)
run_coherence_state_space();

%% Smoothness grid and published-vs-wobbliest gallery
for bandName = ["delta", "theta", "alpha"]
    run_ssm_smoothness_grid(bandName, "coherence");
end
make_candidate_gallery("coherence");

%% Age-varying coherograms (Figs 02-03) and alpha coherence vs age
make_coherence_counterparts();
close all;
