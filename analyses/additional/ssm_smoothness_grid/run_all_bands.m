%% run_all_bands
% Smoothness grid for delta, theta and alpha. Needs run_all.m sections 1-2
% (the stage 02 power table). Results: outputs/additional/ssm_smoothness_grid/
here = fileparts(mfilename('fullpath'));
if isempty(here), here = pwd; end
addpath(fileparts(fileparts(fileparts(here))));
setup_project();
addpath(here);

summaries = table();
for bandName = ["delta", "theta", "alpha"]
    o = run_ssm_smoothness_grid(bandName);
    summaries = [summaries; o.summary]; %#ok<AGROW>
end
writetable(summaries, fullfile(fileparts(o.outDir), 'summary_all_bands.csv'));
disp(summaries);
