function M = ssm_measure(name)
%SSM_MEASURE Settings that let the smoothness grid and gallery run on power or coherence.
%   M = SSM_MEASURE("power")      stage 06 power, in dB (default)
%   M = SSM_MEASURE("coherence")  F3-F4 coherence on the Fisher z scale
%
%   Fields: inputTable, column(band), outRoot, units, priorSD (SDs for the
%   gap-shape comparison; the middle one is the default prior used in the
%   fits), bfPriorSD (prior SD for the headline Bayes factor), toDisplay
%   (z -> plotted value), yLabel, gapLabel, titlePrefix.

    if nargin < 1 || isempty(name), name = "power"; end
    paths = project_paths();
    M = struct('name', string(name));
    switch string(name)
        case "power"
            M.inputTable = fullfile(state_space_outputs_dir(), 'power_table_for_ssm_subepochs_collapsed.csv');
            M.column = @(band) band.column;
            M.outRoot = fullfile(paths.outputsDir, 'additional', 'ssm_smoothness_grid');
            M.units = 'dB';
            M.priorSD = [3 10 30];
            M.toDisplay = @(y) y;
            M.yLabel = 'Power (dB)';
            M.gapLabel = 'CP - Control (dB)';
            M.titlePrefix = '';
        case "coherence"
            % Needs run_coherence_state_space() first (writes the band table)
            M.inputTable = fullfile(paths.outputsDir, 'additional', 'coherence_state_space', 'coherence_band_table.csv');
            M.column = @(band) band.name + "_z";
            M.outRoot = fullfile(paths.outputsDir, 'additional', 'coherence_state_space', 'smoothness_grid');
            M.units = 'z';
            % 10 z is the default prior in the fits (same numeric setting as power);
            % 0.3 z is informative (about 3x the spread of children's values).
            M.priorSD = [0.3 10 30];
            M.toDisplay = @tanh;
            M.yLabel = 'F3-F4 coherence';
            M.gapLabel = 'CP - Control (Fisher z)';
            M.titlePrefix = 'Coherence, ';
        otherwise
            error('ssm_measure:Unknown', 'Unknown measure "%s" (use "power" or "coherence").', name);
    end
    M.defaultPriorSD = 10;   % the prior used in the stage 06 fits (initialCovarianceScale = 100)
    % Prior SD used for the headline Bayes factor. 10 dB suits power; for coherence
    % a 10 z prior is absurdly wide (z values span ~0.3), which penalizes any gap
    % (Lindley's paradox), so the informative 0.3 z prior is reported instead.
    M.bfPriorSD = M.defaultPriorSD;
    if M.name == "coherence", M.bfPriorSD = 0.3; end
end
