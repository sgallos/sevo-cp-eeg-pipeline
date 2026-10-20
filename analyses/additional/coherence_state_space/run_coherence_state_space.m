function out = run_coherence_state_space()
%RUN_COHERENCE_STATE_SPACE The stage 06 state-space model, applied to F3-F4 coherence.
%   Same model, settings and four q versions as the power analysis (stage 06),
%   for delta, theta and alpha F3-F4 coherence:
%   1. Each child's band coherence = mean of their stage 05 coherence curve
%      over the band (same band edges as the power model).
%   2. Fisher z transform, z = atanh(coherence): coherence lives in [0, 1];
%      z is unbounded and close to normal, which the model assumes.
%   3. Fit run_power_ssm_scalar_r on z (EM-Joint, FixedHeuristicQ, FixedSmoothQ,
%      Profile-q), exactly as for power.
%   4. Figures: Control and CP trajectories back-transformed to coherence
%      (tanh is monotone, so credible-band ends transform directly); the
%      CP - Control gap on the z scale, where the model difference is exact.
%   Needs run_all.m sections 1-5. Writes outputs/additional/coherence_state_space/.

    paths = project_paths();
    outDir = fullfile(paths.outputsDir, 'additional', 'coherence_state_space');
    if ~isfolder(outDir), mkdir(outDir); end
    bands = state_space_bands();

    % ---- 1-2. One row per child: band coherence and its Fisher z ------------
    cohort = get_cohort();
    cohort = cohort(cohort.hasF4, :);   % coherence needs F3 and F4
    T = table(cohort.subjectID, cohort.groupLabel, cohort.ageYears, ...
        'VariableNames', {'subjectID', 'groupLabel', 'ageYears'});
    for i = 1:height(T)
        id = char(T.subjectID(i));
        S = load(fullfile(paths.outputsDir, 'coherence_subject_level', id, [id '_F3F4_coherence.mat']), ...
            'freq', 'coherence_subject');
        for b = 1:numel(bands)
            mask = S.freq >= bands(b).lowHz & S.freq <= bands(b).highHz;
            c = mean(S.coherence_subject(mask), 'omitnan');
            T.(bands(b).name + "_coherence")(i) = c;
            T.(bands(b).name + "_z")(i) = atanh(c);
        end
    end
    tableFile = fullfile(outDir, 'coherence_band_table.csv');
    writetable(T, tableFile);

    % ---- 3. Same state-space fits as for power -------------------------------
    % The Profile-q grid in run_power_ssm_scalar_r is written in dB units
    % (q from 1e-2). Coherence z values are ~30x smaller, so the default q is
    % ~1e-3 and would sit below that grid. Scale the grid to each band's
    % default q, covering the same relative range as for power (qInit ~ 3).
    for b = 1:numel(bands)
        z = T.(bands(b).name + "_z");
        qInit = (max(z) - min(z))^2 / (max(T.ageYears) - min(T.ageYears))^3;
        qF0Grid = qInit * logspace(-2.5, 2.5, 30);
        qDeltaGrid = qInit * logspace(-8.5, 2.5, 45);
        evalc(['run_power_ssm_scalar_r(''bandName'', bands(b).name, ''bandLowHz'', bands(b).lowHz, ' ...
            '''bandHighHz'', bands(b).highHz, ''inputTable'', tableFile, ' ...
            '''powerColumn'', bands(b).name + "_z", ''qMode'', "all", ' ...
            '''qF0Grid'', qF0Grid, ''qGroupDifferenceGrid'', qDeltaGrid, ' ...
            '''outputPrefix'', "coherence_ssm", ''outputsDir'', outDir)']);
        close all;
    end

    % ---- 4. Figures -------------------------------------------------------------
    summary = table();
    fig = figure('Color', 'w', 'Position', [60 60 1650 900]);
    tl = tiledlayout(fig, 2, numel(bands), 'TileSpacing', 'compact', 'Padding', 'compact');
    title(tl, sprintf('F3-F4 coherence state-space model (FixedHeuristicQ), %d children', height(T)), ...
        'FontWeight', 'bold', 'FontSize', 15);
    for b = 1:numel(bands)
        band = bands(b);
        R = load(fullfile(outDir, sprintf('coherence_ssm_%s_all_versions.mat', band.name)), 'versionResults');
        v = R.versionResults([R.versionResults.versionName] == "FixedHeuristicQ");
        traj = sortrows(v.trajectory, 'ageYears');
        [axTop, axBottom] = deal(nexttile(tl, b), nexttile(tl, b + numel(bands)));
        plot_trajectories(axTop, T, traj, band);
        gapText = plot_gap(axBottom, traj);
        title(axTop, {sprintf('%s (%g-%g Hz)', title_case(band.name), band.lowHz, band.highHz), ...
            sprintf('q = %.3g, r = %.3g (z^2)', v.qF0, v.r)}, 'FontSize', 12);
        title(axBottom, gapText, 'FontSize', 11);

        % One figure each, like power Figs 5-6: trajectories (coherence) and gap (Fisher z)
        single = figure('Color', 'w', 'Position', [100 100 900 540]);
        ax = axes(single);
        plot_trajectories(ax, T, traj, band);
        xlabel(ax, 'Age (years)');
        title(ax, sprintf('%s (%g-%g Hz) F3-F4 coherence, Control and CP', title_case(band.name), ...
            band.lowHz, band.highHz), 'FontSize', 13);
        exportgraphics(single, fullfile(outDir, sprintf('coherence_ssm_%s_control_vs_cp.png', band.name)), 'Resolution', 200);
        close(single);
        single = figure('Color', 'w', 'Position', [100 100 900 540]);
        ax = axes(single);
        title(ax, {sprintf('%s (%g-%g Hz) coherence, CP - Control', title_case(band.name), band.lowHz, band.highHz), ...
            plot_gap(ax, traj)}, 'FontSize', 13);
        exportgraphics(single, fullfile(outDir, sprintf('coherence_ssm_%s_gap.png', band.name)), 'Resolution', 200);
        close(single);

        below = traj.deltaCIHigh_dB < 0;
        ages = [NaN NaN];
        if any(below), ages = [min(traj.ageYears(below)) max(traj.ageYears(below))]; end
        summary = [summary; table(string(band.name), height(T), mean(traj.deltaMean_dB), ...
            min(traj.deltaMean_dB), max(traj.deltaMean_dB), ages(1), ages(2), v.r, v.qF0, ...
            'VariableNames', {'band', 'nChildren', 'meanGap_z', 'minGap_z', 'maxGap_z', ...
            'gapBelowZeroFromAge', 'gapBelowZeroToAge', 'r', 'q'})]; %#ok<AGROW>
    end
    exportgraphics(fig, fullfile(outDir, 'coherence_state_space_all_bands.png'), 'Resolution', 160);
    close(fig);
    writetable(summary, fullfile(outDir, 'summary.csv'));
    out = struct('outDir', outDir, 'table', T, 'summary', summary);
end

function plot_trajectories(ax, T, traj, band)
    gc = group_colors();   % shared/group_colors.m: Control blue, CP red
    controlColor = gc.controlLine;
    cpColor = gc.cpLine;
    hold(ax, 'on');
    shade(ax, traj.ageYears, tanh(traj.baselineCILow_dB), tanh(traj.baselineCIHigh_dB), controlColor);
    shade(ax, traj.ageYears, tanh(traj.cpCILow_dB), tanh(traj.cpCIHigh_dB), cpColor);
    plot(ax, traj.ageYears, tanh(traj.baselineMean_dB), '-', 'Color', controlColor, 'LineWidth', 2.2);
    plot(ax, traj.ageYears, tanh(traj.cpMean_dB), '-', 'Color', cpColor, 'LineWidth', 2.2);
    isCP = T.groupLabel == "CP";
    y = T.(band.name + "_coherence");
    scatter(ax, T.ageYears(~isCP), y(~isCP), 38, controlColor, 'filled', 'MarkerEdgeColor', 'w');
    scatter(ax, T.ageYears(isCP), y(isCP), 38, cpColor, 'filled', 'MarkerEdgeColor', 'w');
    style(ax);  ylabel(ax, 'F3-F4 coherence');
    legend(ax, {'', '', 'Control', 'CP'}, 'Location', 'northeast');
end

function txt = plot_gap(ax, traj)
    hold(ax, 'on');
    shade(ax, traj.ageYears, traj.deltaCILow_dB, traj.deltaCIHigh_dB, [0.35 0.40 0.50]);
    plot(ax, traj.ageYears, traj.deltaMean_dB, '-', 'Color', [0.2 0.25 0.35], 'LineWidth', 2.2);
    yline(ax, 0, '--', 'Color', [0.4 0.4 0.4]);
    style(ax);  xlabel(ax, 'Age (years)');  ylabel(ax, 'CP - Control (Fisher z)');
    below = traj.deltaCIHigh_dB < 0;
    where = 'nowhere';
    if any(below)
        where = sprintf('%.1f-%.1f yr', min(traj.ageYears(below)), max(traj.ageYears(below)));
    end
    txt = sprintf('CP - Control: %.2f to %.2f z; 95%% credible band below 0: %s', ...
        min(traj.deltaMean_dB), max(traj.deltaMean_dB), where);
end

function shade(ax, x, lo, hi, c)
    fill(ax, [x; flipud(x)], [lo; flipud(hi)], c, 'FaceAlpha', 0.18, 'EdgeColor', 'none');
end

function style(ax)
    grid(ax, 'on');  box(ax, 'off');  ax.FontSize = 11;  ax.TickDir = 'out';  xlim(ax, [10 15.5]);
end

function out = title_case(s)
    s = char(s);
    out = [upper(s(1)) s(2:end)];
end
