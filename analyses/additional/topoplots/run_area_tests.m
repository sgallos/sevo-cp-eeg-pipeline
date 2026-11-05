function outFile = run_area_tests(rows, fileName)
%RUN_AREA_TESTS Frontal and occipital CP - Control tests on the group medians.
%   For alpha, theta, delta and alpha peak vs 7 Hz: each child's value in an area is the
%   median of its usable electrodes there (area_values.m); the groups are compared by the
%   difference of their medians, with a permutation p and a 95% CI that resamples children
%   (median_permutation_test.m). Draws Control and CP group medians and their difference,
%   with the frontal electrodes circled and the occipital ones squared, and adds the rows to
%   area_median_tests.csv. RUN_AREA_TESTS() draws alpha, theta and alpha peak vs 7 Hz
%   (area_median_maps.png); RUN_AREA_TESTS("delta", "delta_area_median_maps.png") draws delta.
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    cohort = get_cohort();
    T = load_map_values(cohort);
    opts = topoplot_channel_rules();
    areas = frontal_occipital_areas();
    if nargin < 1, rows = ["alpha" "theta" "peakVs7"]; end
    if nargin < 2, fileName = 'area_median_maps.png'; end
    rows = string(rows);
    names = struct('alpha', "Alpha, 8-13 Hz", 'theta', "Theta, 4-8 Hz", 'delta', "Delta, 1-4 Hz", 'peakVs7', "Alpha peak vs 7 Hz");
    labels = arrayfun(@(r) names.(r), rows);
    units = repmat("dB re 1 \muV^2/Hz", size(rows));
    units(rows == "peakVs7") = "dB (peak - 7 Hz)";

    results = table();
    fig = figure('Color', 'w', 'Position', [50 50 1300 380 * numel(rows)], 'Visible', 'off');
    tl = tiledlayout(fig, numel(rows), 3, 'TileSpacing', 'compact');
    maps = gobjects(0);  cmaps = {};
    for i = 1:numel(rows)
        M = group_channel_map(T, char(rows(i)), opts);
        chanlocs = channel_locations(M.channel);
        note = strings(1, numel(areas));
        for a = 1:numel(areas)
            A = area_values(T, rows(i), areas(a));
            r = median_permutation_test(A.value(A.groupLabel == "CP"), A.value(A.groupLabel == "Control"));
            results = [results; table(rows(i), areas(a).name, r.nA, r.nB, r.medianA, r.medianB, ...
                r.difference, r.ci(1), r.ci(2), r.p, 'VariableNames', {'measure', 'area', 'nCP', ...
                'nControl', 'medianCP', 'medianControl', 'difference', 'ciLow', 'ciHigh', 'p'})]; %#ok<AGROW>
            marker = ["circles" "squares"];
            note(a) = sprintf('%s (%s): %+.1f dB, 95%% CI %+.1f to %+.1f, p = %.3f', areas(a).name, ...
                marker(a), r.difference, r.ci, r.p);
        end
        limits = [min([M.Control; M.CP]), max([M.Control; M.CP])];
        maps(end + 1) = draw_map(nexttile(tl), M.Control, chanlocs, limits, "Control: " + labels(i), units(i)); %#ok<AGROW>
        maps(end + 1) = draw_map(nexttile(tl), M.CP, chanlocs, limits, "CP: " + labels(i), units(i)); %#ok<AGROW>
        ax = draw_map(nexttile(tl), M.difference, chanlocs, [-5 5], ["CP - Control (medians): " + labels(i), note], ...
            'CP - Control (dB)');
        mark_electrodes(ax, ismember(M.channel, areas(1).channels), 'o');
        mark_electrodes(ax, ismember(M.channel, areas(2).channels), 's');
        maps(end + 1) = ax; %#ok<AGROW>
        cmaps = [cmaps, {jet(256), jet(256), blue_white_red()}]; %#ok<AGROW>
    end
    for k = 1:numel(maps), colormap(maps(k), cmaps{k}); end   % last: topoplot resets the colormap
    title(tl, {sprintf('Group medians, %d Control and %d CP children', sum(cohort.groupLabel == "Control"), ...
        sum(cohort.groupLabel == "CP")), 'Area tests: each child''s median over its electrodes in the area; difference of group medians,', ...
        'permutation p (10,000 shuffles), 95% CI from resampling children'}, 'FontWeight', 'bold', 'FontSize', 11);
    exportgraphics(fig, fullfile(outDir, fileName), 'Resolution', 200);
    close(fig);
    outFile = fullfile(outDir, 'area_median_tests.csv');
    save_statistics(results, outFile);
end

function ax = draw_map(ax, values, chanlocs, limits, name, unit)
    axes(ax);  %#ok<LAXES>
    topoplot(values, chanlocs, 'maplimits', limits, 'electrodes', 'on', 'style', 'map', 'numcontour', 0);
    mask_unmeasured_area(ax);
    cb = colorbar(ax);  cb.Label.String = unit;
    title(ax, name, 'FontWeight', 'normal', 'FontSize', 10);
end

function mark_electrodes(ax, which, marker)
    e = findobj(ax, 'Type', 'line', 'Marker', '.');   % topoplot draws electrodes in channel order
    hold(ax, 'on');
    z = max(e(1).ZData(:)) + 1;
    plot3(ax, e(1).XData(which), e(1).YData(which), z * ones(1, sum(which)), marker, ...
        'Color', 'k', 'MarkerSize', 7, 'LineWidth', 1.2);
end

function cmap = blue_white_red()
    half = linspace(0, 1, 128)';
    cmap = [[half; ones(128, 1)], [half; flipud(half)], [ones(128, 1); flipud(half)]];
end
