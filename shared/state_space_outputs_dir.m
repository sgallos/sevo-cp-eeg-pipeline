function outDir = state_space_outputs_dir()
%STATE_SPACE_OUTPUTS_DIR Folder for power tables and state-space model results.
%   The power table written here also defines the final cohort used by the
%   group MFDB step (stage 03).
    paths = project_paths();
    outDir = fullfile(paths.outputsDir, 'state_space_model');
end
