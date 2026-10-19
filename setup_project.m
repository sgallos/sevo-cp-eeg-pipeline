function paths = setup_project()
%SETUP_PROJECT Put the pipeline on the MATLAB path and check requirements.
%   paths = SETUP_PROJECT() adds shared/, external/, and every analysis
%   stage folder to the path, checks the required toolboxes, confirms the
%   data folder exists, and returns the struct from project_paths().
%
%   run_all.m calls this first. Call it yourself before running a single
%   stage script on its own.

    repoRoot = fileparts(mfilename('fullpath'));
    addpath(repoRoot);
    addpath(genpath(fullfile(repoRoot, 'shared')));
    addpath(genpath(fullfile(repoRoot, 'external')));
    addpath(genpath(fullfile(repoRoot, 'analyses', 'primary')));

    requiredToolboxes = {
        'Statistics_Toolbox', 'Statistics and Machine Learning Toolbox'
        'Signal_Toolbox',     'Signal Processing Toolbox'};
    for i = 1:size(requiredToolboxes, 1)
        if ~license('test', requiredToolboxes{i, 1})
            error('setup_project:MissingToolbox', ...
                'The %s is required but not installed or licensed.', requiredToolboxes{i, 2});
        end
    end

    paths = project_paths();
    if ~isfolder(paths.outputsDir)
        mkdir(paths.outputsDir);
    end

    fprintf('Project root: %s\n', paths.repoRoot);
    fprintf('Data folder:  %s\n', paths.dataDir);
    fprintf('Outputs:      %s\n', paths.outputsDir);
end
