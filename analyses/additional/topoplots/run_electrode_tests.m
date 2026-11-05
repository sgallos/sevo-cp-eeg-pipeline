function outFile = run_electrode_tests(rows)
%RUN_ELECTRODE_TESTS CP vs Control at every drawn electrode, one test per electrode.
%   RUN_ELECTRODE_TESTS() tests alpha, theta and alpha peak vs 7 Hz; RUN_ELECTRODE_TESTS("delta")
%   tests delta. One figure per measure, electrode_tests_<measure>.png.
%   At each electrode, the children with a usable value there are compared by the
%   difference of group medians, with a permutation p and a 95% CI that resamples children
%   (median_permutation_test.m, the test of the area comparison). The p-values of a measure
%   are then adjusted over its electrodes for the false discovery rate
%   (benjamini_hochberg.m). Each figure: the difference map, with electrodes
%   at p < 0.05 circled and those at q < 0.05 filled, beside every electrode's difference
%   and 95% CI, front of the head at the top. Adds the rows to electrode_median_tests.csv.
    if nargin < 1, rows = ["alpha" "theta" "peakVs7"]; end
    rows = string(rows);
    names = struct('alpha', "Alpha, 8-13 Hz", 'theta', "Theta, 4-8 Hz", 'delta', "Delta, 1-4 Hz", 'peakVs7', "Alpha peak vs 7 Hz");
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    cohort = get_cohort();
    T = load_map_values(cohort);
    opts = topoplot_channel_rules();

    results = table();
    for i = 1:numel(rows)
        fig = figure('Color', 'w', 'Position', [50 50 1400 950], 'Visible', 'off');
        tl = tiledlayout(fig, 1, 2, 'TileSpacing', 'compact');
        M = group_channel_map(T, char(rows(i)), opts);
        chanlocs = channel_locations(M.channel);
        n = height(M);
        [d, low, high, p, nCP, nControl] = deal(nan(n, 1));
        for c = 1:n
            here = T(T.isUsable & T.channel == M.channel(c) & ~isnan(T.(rows(i))), :);
            r = median_permutation_test(here.(rows(i))(here.groupLabel == "CP"), here.(rows(i))(here.groupLabel == "Control"));
            d(c) = r.difference;  low(c) = r.ci(1);  high(c) = r.ci(2);  p(c) = r.p;
            nCP(c) = r.nA;  nControl(c) = r.nB;
        end
        q = benjamini_hochberg(p);
        results = [results; table(repmat(rows(i), n, 1), M.channel, nCP, nControl, M.CP, M.Control, d, low, high, p, q, ...
            'VariableNames', {'measure', 'channel', 'nCP', 'nControl', 'medianCP', 'medianControl', ...
            'difference', 'ciLow', 'ciHigh', 'p', 'q'})]; %#ok<AGROW>
        unit = 'dB';

        ax = nexttile(tl);  axes(ax);  %#ok<LAXES>
        topoplot(d, chanlocs, 'maplimits', [-5 5], 'electrodes', 'on', 'style', 'map', 'numcontour', 0);
        mask_unmeasured_area(ax);
        e = findobj(ax, 'Type', 'line', 'Marker', '.');   % topoplot draws electrodes in channel order
        hold(ax, 'on');  z = max(e(1).ZData(:)) + 1;
        plot3(ax, e(1).XData(p < 0.05), e(1).YData(p < 0.05), z * ones(1, sum(p < 0.05)), 'o', ...
            'Color', 'k', 'MarkerSize', 9, 'LineWidth', 1.4);
        plot3(ax, e(1).XData(q < 0.05), e(1).YData(q < 0.05), z * ones(1, sum(q < 0.05)), 'o', ...
            'Color', 'k', 'MarkerFaceColor', 'k', 'MarkerSize', 9);
        cb = colorbar(ax);  cb.Label.String = 'CP - Control, medians (dB)';
        title(ax, {sprintf('CP - Control: %s', names.(rows(i))), ...
            sprintf('p < 0.05 at %d of %d electrodes (circled); q < 0.05 at %d (filled)', sum(p < 0.05), n, sum(q < 0.05))}, ...
            'FontWeight', 'normal');
        half = linspace(0, 1, 128)';
        colormap(ax, [[half; ones(128, 1)], [half; flipud(half)], [ones(128, 1); flipud(half)]]);

        ax = nexttile(tl);  hold(ax, 'on');
        [~, order] = sort([chanlocs.X], 'descend');      % front of the head first
        y = 1:n;
        for k = 1:n
            c = order(k);
            colour = [0.6 0.6 0.6];
            if p(c) < 0.05, colour = [0.15 0.15 0.15]; end
            plot(ax, [low(c) high(c)], [y(k) y(k)], '-', 'Color', colour, 'LineWidth', 1.2);
            if q(c) < 0.05
                plot(ax, d(c), y(k), 'o', 'Color', 'k', 'MarkerFaceColor', 'k', 'MarkerSize', 6);
            else
                plot(ax, d(c), y(k), 'o', 'Color', colour, 'MarkerFaceColor', 'w', 'MarkerSize', 6);
            end
        end
        xline(ax, 0, '--', 'Color', [0.4 0.4 0.4]);
        set(ax, 'YDir', 'reverse', 'YTick', y, 'YTickLabel', M.channel(order), 'FontSize', 10);
        ylim(ax, [0 n + 1]);  grid(ax, 'on');
        xlabel(ax, sprintf('CP - Control, difference of medians (%s), 95%% CI', unit));
        title(ax, 'Each electrode, front of the head at the top', 'FontWeight', 'normal');
        title(tl, {sprintf('Electrode by electrode: %s, %d Control and %d CP children', names.(rows(i)), ...
            sum(cohort.groupLabel == "Control"), sum(cohort.groupLabel == "CP")), ...
            'Difference of group medians; permutation p (10,000 shuffles), 95% CI resampling children, q = false discovery rate over the electrodes'}, ...
            'FontWeight', 'bold', 'FontSize', 11);
        exportgraphics(fig, fullfile(outDir, "electrode_tests_" + rows(i) + ".png"), 'Resolution', 170);
        close(fig);
    end
    outFile = fullfile(outDir, 'electrode_median_tests.csv');
    save_statistics(results, outFile);
end
