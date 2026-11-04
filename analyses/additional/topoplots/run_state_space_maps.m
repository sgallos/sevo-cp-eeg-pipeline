function outFile = run_state_space_maps(ages)
%RUN_STATE_SPACE_MAPS Alpha maps at chosen ages from the state-space model fitted at each electrode.
%   RUN_STATE_SPACE_MAPS(11:15). At every drawn electrode, state_space_fit.m fits the
%   children with a usable value there; the posterior means are read off at each age
%   (linear interpolation between children's ages, no extrapolation beyond them).
%   Columns: Control, CP, CP - Control; electrodes whose 95% credible band for the gap
%   excludes 0 are ringed. Each ring is that electrode's own band, with no correction
%   across electrodes. Saves state_space_alpha_maps.csv.
    if nargin < 1, ages = 11:15; end
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    cohort = get_cohort();
    T = load_map_values(cohort);
    M = group_channel_map(T, 'alpha', topoplot_channel_rules());
    channels = M.channel;  nC = numel(channels);  nA = numel(ages);
    [control, cp, gap, low, high] = deal(nan(nC, nA));
    for c = 1:nC
        U = T(T.isUsable & T.channel == channels(c) & ~isnan(T.alpha), :);
        [~, where] = ismember(U.subjectID, string(cohort.subjectID));
        tr = state_space_fit(U.subjectID, U.groupLabel, cohort.ageYears(where), U.alpha);
        inside = ages >= min(tr.ageYears) & ages <= max(tr.ageYears);
        at = @(v) interp1(tr.ageYears, v, ages(inside));
        control(c, inside) = at(tr.baselineMean_dB);  cp(c, inside) = at(tr.cpMean_dB);
        gap(c, inside) = at(tr.deltaMean_dB);
        low(c, inside) = at(tr.deltaCILow_dB);  high(c, inside) = at(tr.deltaCIHigh_dB);
    end
    excludes = high < 0 | low > 0;

    chanlocs = channel_locations(channels);
    limits = [min([control(:); cp(:)]), max([control(:); cp(:)])];
    fig = figure('Color', 'w', 'Position', [50 50 1250 330 * nA], 'Visible', 'off');
    tl = tiledlayout(fig, nA, 3, 'TileSpacing', 'compact');
    maps = gobjects(0);  cmaps = {};
    for a = 1:nA
        values = {control(:, a), cp(:, a), gap(:, a)};
        names = {sprintf('Control, age %d', ages(a)), sprintf('CP, age %d', ages(a)), ...
            sprintf('CP - Control, age %d: band excludes 0 at %d electrodes (ringed)', ages(a), sum(excludes(:, a)))};
        mapLimits = {limits, limits, [-6 6]};
        for k = 1:3
            ax = nexttile(tl);  axes(ax);  %#ok<LAXES>
            topoplot(values{k}, chanlocs, 'maplimits', mapLimits{k}, 'electrodes', 'on', 'style', 'map', 'numcontour', 0);
            mask_unmeasured_area(ax);
            cb = colorbar(ax);
            if k < 3, cb.Label.String = 'Alpha (dB re 1 \muV^2/Hz)'; else, cb.Label.String = 'CP - Control (dB)'; end
            if k == 3 && any(excludes(:, a))
                e = findobj(ax, 'Type', 'line', 'Marker', '.');   % electrodes in channel order
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
    title(tl, {'Alpha by age from the stage 06 state-space model, fitted at each electrode', ...
        'Posterior means; ringed = that electrode''s 95% credible band for the gap excludes 0 (no correction across electrodes)'}, ...
        'FontWeight', 'bold', 'FontSize', 11);
    exportgraphics(fig, fullfile(outDir, 'state_space_alpha_maps.png'), 'Resolution', 170);
    close(fig);

    [c, a] = ndgrid(1:nC, 1:nA);
    S = table(channels(c(:)), ages(a(:))', control(:), cp(:), gap(:), low(:), high(:), excludes(:), ...
        'VariableNames', {'channel', 'age', 'control', 'cp', 'gap', 'gapLow', 'gapHigh', 'excludesZero'});
    outFile = fullfile(outDir, 'state_space_alpha_maps.csv');
    writetable(S, outFile);
end

function cmap = blue_white_red()
    half = linspace(0, 1, 128)';
    cmap = [[half; ones(128, 1)], [half; flipud(half)], [ones(128, 1); flipud(half)]];
end
