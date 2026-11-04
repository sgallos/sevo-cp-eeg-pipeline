function outFile = run_area_state_space()
%RUN_AREA_STATE_SPACE Frontal and occipital alpha across age, with the stage 06 state-space model.
%   Each child's value is the median alpha over its usable electrodes in the area
%   (area_values.m), fitted with the published setting (state_space_fit.m). Draws the
%   Control and CP curves with 95% credible bands and the CP - Control gap, and saves
%   area_state_space_alpha.csv (mean gap and the ages where the band excludes 0).
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    cohort = get_cohort();
    T = load_map_values(cohort);
    areas = frontal_occipital_areas();
    colours = group_colors();

    summary = table();
    fig = figure('Color', 'w', 'Position', [50 50 1300 450 * numel(areas)], 'Visible', 'off');
    tl = tiledlayout(fig, numel(areas), 2, 'TileSpacing', 'compact');
    for a = 1:numel(areas)
        A = area_values(T, "alpha", areas(a));
        [~, where] = ismember(A.subjectID, string(cohort.subjectID));
        tr = state_space_fit(A.subjectID, A.groupLabel, cohort.ageYears(where), A.value);
        below = tr.deltaCIHigh_dB < 0;
        if any(below)
            span = sprintf('95%% band excludes 0 from %.1f to %.1f years', min(tr.ageYears(below)), max(tr.ageYears(below)));
            ages = [min(tr.ageYears(below)), max(tr.ageYears(below))];
        else
            span = '95% band includes 0 at every age';  ages = [NaN NaN];
        end
        summary = [summary; table(areas(a).name, sum(A.groupLabel == "CP"), sum(A.groupLabel == "Control"), ...
            mean(tr.deltaMean_dB), ages(1), ages(2), 'VariableNames', {'area', 'nCP', 'nControl', ...
            'meanGap_dB', 'excludesZeroFromAge', 'excludesZeroToAge'})]; %#ok<AGROW>
        name = sprintf('%s alpha', areas(a).name);

        ax = nexttile(tl);  hold(ax, 'on');
        isControl = tr.groupIndicator == 0;
        band(ax, tr.ageYears, tr.baselineCILow_dB, tr.baselineCIHigh_dB, colours.controlFill);
        band(ax, tr.ageYears, tr.cpCILow_dB, tr.cpCIHigh_dB, colours.cpFill);
        plot(ax, tr.ageYears, tr.baselineMean_dB, 'Color', colours.controlLine, 'LineWidth', 2.2);
        plot(ax, tr.ageYears, tr.cpMean_dB, 'Color', colours.cpLine, 'LineWidth', 2.2);
        scatter(ax, tr.ageYears(isControl), tr.alpha_dB(isControl), 50, colours.controlLine, 'filled', 'MarkerEdgeColor', 'w');
        scatter(ax, tr.ageYears(~isControl), tr.alpha_dB(~isControl), 50, colours.cpLine, 'filled', 'MarkerEdgeColor', 'w');
        legend(ax, {'Control 95% band', 'CP 95% band', 'Control', 'CP', 'Control child', 'CP child'}, ...
            'Location', 'best', 'Box', 'off');
        xlabel(ax, 'Age (years)');  ylabel(ax, sprintf('%s power (dB re 1 \\muV^2/Hz)', name));  grid(ax, 'on');
        title(ax, sprintf('%s, %d Control and %d CP children', name, sum(isControl), sum(~isControl)), 'FontWeight', 'normal');

        ax = nexttile(tl);  hold(ax, 'on');
        band(ax, tr.ageYears, tr.deltaCILow_dB, tr.deltaCIHigh_dB, [0.70 0.80 0.90]);
        plot(ax, tr.ageYears, tr.deltaMean_dB, 'Color', [0.2 0.3 0.45], 'LineWidth', 2.2);
        yline(ax, 0, '--k');  ylim(ax, [-12 6]);  grid(ax, 'on');
        xlabel(ax, 'Age (years)');  ylabel(ax, 'CP - Control (dB)');
        title(ax, {sprintf('%s gap, mean %.1f dB', name, mean(tr.deltaMean_dB)), span}, 'FontWeight', 'normal');
    end
    title(tl, 'Alpha across age, stage 06 state-space model (fixed heuristic q, r by EM); each child = median of its electrodes in the area', ...
        'FontWeight', 'bold');
    exportgraphics(fig, fullfile(outDir, 'area_state_space_alpha.png'), 'Resolution', 200);
    close(fig);
    outFile = fullfile(outDir, 'area_state_space_alpha.csv');
    writetable(summary, outFile);
end

function band(ax, x, low, high, colour)
    fill(ax, [x; flipud(x)], [low; flipud(high)], colour, 'EdgeColor', 'none', 'FaceAlpha', 0.35);
end
