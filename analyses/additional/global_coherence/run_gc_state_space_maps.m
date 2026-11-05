function outFile = run_gc_state_space_maps(ages, band)
%RUN_GC_STATE_SPACE_MAPS Spatial coherence maps at chosen ages from the stage 06 state-space model.
%   RUN_GC_STATE_SPACE_MAPS(11:15, 'alpha'). The method of topoplots/run_state_space_maps.m,
%   applied to |u_1|^2: at each electrode, state_space_fit.m (stage 06's published setting)
%   fits the children who have it; posterior means are read off at each age (linear
%   interpolation, no extrapolation). Columns Control, CP, CP - Control; ringed electrodes
%   have a 95% credible band for the gap that excludes 0, with no correction across
%   electrodes. Each row title also gives the model's global coherence at that age, from the
%   same model fitted to each child's band GC. Saves gc_state_space_<band>_maps.csv.
    if nargin < 1, ages = 11:15; end
    if nargin < 2, band = 'alpha'; end
    outDir = fullfile(project_paths().outputsDir, 'additional', 'global_coherence');
    cohort = get_cohort();
    [W, G] = load_child_gc(cohort);
    channels = unique(W.channel, 'stable');  nC = numel(channels);  nA = numel(ages);
    [control, cp, gap, low, high] = deal(nan(nC, nA));
    for c = 1:nC
        U = W(W.channel == channels(c), :);
        [~, where] = ismember(U.subjectID, string(cohort.subjectID));
        [control(c, :), cp(c, :), gap(c, :), low(c, :), high(c, :)] = ...
            at_ages(state_space_fit(U.subjectID, U.groupLabel, cohort.ageYears(where), U.(band)), ages);
    end
    excludes = high < 0 | low > 0;
    [gcControl, gcCP, gcGap, gcLow, gcHigh] = at_ages(state_space_fit(G.subjectID, G.groupLabel, G.ageYears, G.("gc_" + band)), ages);

    chanlocs = channel_locations(channels);
    limits = [min([control(:); cp(:)]), max([control(:); cp(:)])];
    gapLimit = max(abs(gap(:)));
    fig = figure('Color', 'w', 'Position', [50 50 1250 330 * nA], 'Visible', 'off');
    tl = tiledlayout(fig, nA, 3, 'TileSpacing', 'compact');
    maps = gobjects(0);  cmaps = {};
    for a = 1:nA
        values = {control(:, a), cp(:, a), gap(:, a)};
        names = {sprintf('Control, age %d (GC %.3f)', ages(a), gcControl(a)), sprintf('CP, age %d (GC %.3f)', ages(a), gcCP(a)), ...
            {sprintf('CP - Control, age %d: band excludes 0 at %d electrodes (ringed)', ages(a), sum(excludes(:, a))), ...
            sprintf('GC gap %.3f, 95%% band %.3f to %.3f', gcGap(a), gcLow(a), gcHigh(a))}};
        mapLimits = {limits, limits, [-gapLimit gapLimit]};
        for k = 1:3
            ax = nexttile(tl);  axes(ax);  %#ok<LAXES>
            topoplot(values{k}, chanlocs, 'maplimits', mapLimits{k}, 'electrodes', 'on', 'style', 'map', 'numcontour', 0);
            mask_unmeasured_area(ax);
            cb = colorbar(ax);
            if k < 3, cb.Label.String = '|u_1|^2'; else, cb.Label.String = 'CP - Control (|u_1|^2)'; end
            if k == 3 && any(excludes(:, a))
                e = findobj(ax, 'Type', 'line', 'Marker', '.');
                hold(ax, 'on');  z = max(e(1).ZData(:)) + 1;
                plot3(ax, e(1).XData(excludes(:, a)), e(1).YData(excludes(:, a)), z * ones(1, sum(excludes(:, a))), ...
                    'o', 'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.4);
            end
            title(ax, names{k}, 'FontWeight', 'normal', 'FontSize', 10);
            maps(end + 1) = ax; %#ok<AGROW>
        end
        cmaps = [cmaps, {jet(256), jet(256), blue_white_red()}]; %#ok<AGROW>
    end
    for k = 1:numel(maps), colormap(maps(k), cmaps{k}); end
    title(tl, {sprintf('%s spatial coherence |u_1|^2 by age from the stage 06 state-space model, fitted at each electrode', ...
        [upper(band(1)) band(2:end)]), ...
        'Posterior means; ringed = that electrode''s 95% credible band for the gap excludes 0 (no correction across electrodes)'}, ...
        'FontWeight', 'bold', 'FontSize', 11);
    exportgraphics(fig, fullfile(outDir, sprintf('gc_state_space_%s_maps.png', band)), 'Resolution', 170);
    close(fig);

    [c, a] = ndgrid(1:nC, 1:nA);
    S = table(channels(c(:)), ages(a(:))', control(:), cp(:), gap(:), low(:), high(:), excludes(:), ...
        'VariableNames', {'channel', 'age', 'control', 'cp', 'gap', 'gapLow', 'gapHigh', 'excludesZero'});
    outFile = fullfile(outDir, sprintf('gc_state_space_%s_maps.csv', band));
    writetable(S, outFile);
    writetable(table(ages(:), gcControl(:), gcCP(:), gcGap(:), gcLow(:), gcHigh(:), 'VariableNames', ...
        {'age', 'control', 'cp', 'gap', 'gapLow', 'gapHigh'}), fullfile(outDir, sprintf('gc_state_space_%s_global.csv', band)));
end

function [control, cp, gap, low, high] = at_ages(tr, ages)
    [control, cp, gap, low, high] = deal(nan(1, numel(ages)));
    inside = ages >= min(tr.ageYears) & ages <= max(tr.ageYears);
    at = @(v) interp1(tr.ageYears, v, ages(inside));
    control(inside) = at(tr.baselineMean_dB);  cp(inside) = at(tr.cpMean_dB);
    gap(inside) = at(tr.deltaMean_dB);  low(inside) = at(tr.deltaCILow_dB);  high(inside) = at(tr.deltaCIHigh_dB);
end

function cmap = blue_white_red()
    half = linspace(0, 1, 128)';
    cmap = [[half; ones(128, 1)], [half; flipud(half)], [ones(128, 1); flipud(half)]];
end
