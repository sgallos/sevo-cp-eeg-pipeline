function out = make_coherence_counterparts()
%MAKE_COHERENCE_COUNTERPARTS Coherence versions of two power figures.
%   1. Age-varying coherograms (counterpart of Figs 02-03): each child's
%      F3-F4 coherence curve (stage 05), median within the same sliding age
%      windows as stage 07 (centres 10-16 yr, +/-1.25 yr).
%   2. Alpha coherence vs age (counterpart of the every-child + age-adjusted
%      power figure in subject_level_inference): alpha 8-13 Hz coherence per
%      child (as in stage 05). Statistics on the Fisher z scale (window means
%      with children-resampled CIs; regression z ~ group + age), plotted
%      back in coherence units.
%   Needs run_all.m sections 1-5. Writes outputs/additional/coherence_state_space/.

    paths = project_paths();
    outDir = fullfile(paths.outputsDir, 'additional', 'coherence_state_space');
    if ~isfolder(outDir), mkdir(outDir); end
    controlColor = [0.00 0.38 0.95];
    cpColor = [0.92 0.02 0.08];

    cohort = get_cohort();
    cohort = cohort(cohort.hasF4, :);
    n = height(cohort);
    for i = n:-1:1
        id = char(cohort.subjectID(i));
        S = load(fullfile(paths.outputsDir, 'coherence_subject_level', id, [id '_F3F4_coherence.mat']), ...
            'freq', 'coherence_subject');
        curves(i, :) = S.coherence_subject;
    end
    freq = S.freq(:).';
    isCP = cohort.groupLabel == "CP";

    % ---- 1. Age-varying coherograms ------------------------------------------
    centers = 10:1:16;
    halfWidth = 1.25;
    show = freq >= 1 & freq <= 30;
    [mapControl, nControl] = window_median(curves(~isCP, :), cohort.ageYears(~isCP), centers, halfWidth);
    [mapCP, nCP] = window_median(curves(isCP, :), cohort.ageYears(isCP), centers, halfWidth);
    clim = [min([mapControl(:, show); mapCP(:, show)], [], 'all'), max([mapControl(:, show); mapCP(:, show)], [], 'all')];

    names = {'Control', 'CP'};  maps = {mapControl, mapCP};  counts = {nControl, nCP};
    files = {'coherogram_control.png', 'coherogram_cp.png'};
    for g = 1:2
        fig = figure('Color', 'w', 'Position', [80 80 900 560]);
        ax = axes(fig);
        draw_map(ax, centers, freq(show), maps{g}(:, show).', clim, counts{g});
        title(ax, sprintf('%s: F3-F4 coherence by age (median, half-width = %.2f years)', names{g}, halfWidth));
        exportgraphics(fig, fullfile(outDir, files{g}), 'Resolution', 160);
        close(fig);
    end
    fig = figure('Color', 'w', 'Position', [80 80 1500 560]);
    tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
    title(tl, 'Age-varying F3-F4 coherence (counterpart of Figs 02-03); numbers = children per window', ...
        'FontWeight', 'bold');
    for g = 1:2
        ax = nexttile(tl);
        draw_map(ax, centers, freq(show), maps{g}(:, show).', clim, counts{g});
        title(ax, names{g});
    end
    exportgraphics(fig, fullfile(outDir, 'coherograms.png'), 'Resolution', 160);
    close(fig);

    % ---- 2. Alpha coherence vs age ----------------------------------------------
    alphaMask = freq >= 8 & freq <= 13;
    C = mean(curves(:, alphaMask), 2);
    children = table(cohort.subjectID, categorical(cohort.groupLabel, ["Control", "CP"]), ...
        cohort.ageYears, C, atanh(C), 'VariableNames', {'subjectID', 'group', 'ageYears', 'coherence', 'z'});
    model = fitlm(children, 'z ~ group + ageYears');
    modelInteraction = fitlm(children, 'z ~ group * ageYears');
    ci = coefCI(model);
    effect = model.Coefficients{'group_CP', 'Estimate'};
    effectCI = ci(strcmp(model.CoefficientNames, 'group_CP'), :);
    pGroup = model.Coefficients{'group_CP', 'pValue'};
    rows = modelInteraction.Coefficients.Properties.RowNames;
    pInteraction = modelInteraction.Coefficients.pValue(contains(rows, ':'));

    windowCenters = (10:0.5:16).';
    fig = figure('Color', 'w', 'Position', [100 100 1250 560]);
    tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');
    ax = nexttile(tl, [1 2]);  hold(ax, 'on');
    groups = ["Control", "CP"];  colors = {controlColor, cpColor};
    for g = 1:2
        sel = children.group == groups(g);
        [m, lo, hi] = window_mean_ci(children.z(sel), children.ageYears(sel), windowCenters, 2, 3);
        ok = ~isnan(lo);
        x = windowCenters(ok).';
        fill(ax, [x fliplr(x)], tanh([lo(ok).' fliplr(hi(ok).')]), colors{g}, 'FaceAlpha', 0.18, ...
            'EdgeColor', 'none', 'HandleVisibility', 'off');
        plot(ax, windowCenters, tanh(m), '-', 'Color', colors{g}, 'LineWidth', 2.2, ...
            'DisplayName', groups(g) + " mean (4-yr window, 95% CI resampling children)");
        scatter(ax, children.ageYears(sel), children.coherence(sel), 45, colors{g}, 'filled', ...
            'MarkerEdgeColor', 'w', 'DisplayName', groups(g) + " children");
    end
    grid(ax, 'on');  box(ax, 'off');  xlabel(ax, 'Age (years)');  ylabel(ax, 'Alpha (8-13 Hz) F3-F4 coherence');
    title(ax, sprintf('Alpha coherence vs age (group x age interaction p = %.2f)', pInteraction));
    legend(ax, 'Location', 'northwest');

    ax = nexttile(tl);  hold(ax, 'on');
    slope = model.Coefficients{'ageYears', 'Estimate'};
    adjusted = tanh(children.z - slope * (children.ageYears - mean(children.ageYears)));
    rng(1);
    for g = 1:2
        v = adjusted(children.group == groups(g));
        scatter(ax, g + (rand(numel(v), 1) - 0.5) * 0.3, v, 55, colors{g}, 'filled', 'MarkerEdgeColor', 'k');
        plot(ax, g + [-0.25 0.25], tanh(mean(atanh(v))) * [1 1], 'k-', 'LineWidth', 2.5);
    end
    xticks(ax, [1 2]);  xticklabels(ax, cellstr(groups));  xlim(ax, [0.4 2.6]);
    grid(ax, 'on');  box(ax, 'off');
    ylabel(ax, sprintf('Alpha coherence adjusted to age %.1f yr', mean(children.ageYears)));
    title(ax, {sprintf('CP - Control = %.2f z [%.2f, %.2f]', effect, effectCI), ...
        sprintf('p = %.3f, one dot per child (n = %d)', pGroup, height(children))});
    exportgraphics(fig, fullfile(outDir, 'alpha_coherence_vs_age.png'), 'Resolution', 170);
    close(fig);

    writetable(children, fullfile(outDir, 'alpha_coherence_per_child.csv'));
    out = struct('outDir', outDir, 'effect_z', effect, 'effectCI_z', effectCI, 'pGroup', pGroup, ...
        'pInteraction', pInteraction, 'nControl', nControl, 'nCP', nCP);
end

function [M, counts] = window_median(curves, ages, centers, halfWidth)
    M = nan(numel(centers), size(curves, 2));
    counts = zeros(numel(centers), 1);
    for c = 1:numel(centers)
        in = abs(ages - centers(c)) <= halfWidth;
        counts(c) = sum(in);
        if counts(c) > 0
            M(c, :) = median(curves(in, :), 1, 'omitnan');
        end
    end
end

function [m, lo, hi] = window_mean_ci(z, ages, centers, halfWidth, minN)
    [m, lo, hi] = deal(nan(numel(centers), 1));
    for c = 1:numel(centers)
        v = z(abs(ages - centers(c)) <= halfWidth);
        if isempty(v), continue; end
        m(c) = mean(v);
        if numel(v) >= minN
            b = subject_bootstrap_ci(v, v, struct('statFn', @mean));
            lo(c) = b.ciA(1);
            hi(c) = b.ciA(2);
        end
    end
end

function draw_map(ax, centers, f, map, clim, counts)
    imagesc(ax, centers, f, map);
    set(ax, 'YDir', 'normal');
    colormap(ax, jet);  caxis(ax, clim);
    cb = colorbar(ax);  cb.Label.String = 'Median F3-F4 coherence';
    xlabel(ax, 'Age center (years)');  ylabel(ax, 'Frequency (Hz)');
    for c = 1:numel(centers)
        text(ax, centers(c), f(end) - 1, sprintf('n=%d', counts(c)), 'HorizontalAlignment', 'center', ...
            'Color', 'w', 'FontWeight', 'bold');
    end
end
