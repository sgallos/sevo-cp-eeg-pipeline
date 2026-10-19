function paths = project_paths()
%PROJECT_PATHS Every folder the pipeline reads from or writes to.
%   paths = PROJECT_PATHS() returns a struct with:
%     repoRoot   - top folder of this repository
%     dataDir    - input data (Patients.xlsx + *_focus.mat), from config_local.m
%     outputsDir - where all results go (repoRoot/outputs, not committed)
%     figuresDir - final publication figures (outputsDir/figures)
%     referenceOutputsDir    - optional original multitaper folder, used by tests/
%     referenceStateSpaceDir - optional original StateSpaceAlpha folder, used by tests/
%
%   This is the only place paths are defined. Every script calls this
%   instead of hardcoding a location, so the repo runs on any computer.

    repoRoot = fileparts(fileparts(mfilename('fullpath')));

    if exist('config_local', 'file') ~= 2
        error('project_paths:MissingConfig', ...
            ['config_local.m not found.\n' ...
             'Copy config_template.m to config_local.m in %s and set dataDir.'], repoRoot);
    end
    local = config_local();

    if ~isfolder(local.dataDir)
        error('project_paths:MissingData', ...
            ['Data folder not found:\n  %s\n' ...
             'Set dataDir in config_local.m to the folder from the shared Dropbox link.'], ...
            local.dataDir);
    end

    paths = struct();
    paths.repoRoot = repoRoot;
    paths.dataDir = local.dataDir;
    paths.outputsDir = fullfile(repoRoot, 'outputs');
    paths.figuresDir = fullfile(paths.outputsDir, 'figures');
    paths.referenceOutputsDir = '';
    if isfield(local, 'referenceOutputsDir')
        paths.referenceOutputsDir = local.referenceOutputsDir;
    end
    paths.referenceStateSpaceDir = '';
    if isfield(local, 'referenceStateSpaceDir')
        paths.referenceStateSpaceDir = local.referenceStateSpaceDir;
    end
end
