function outFile = run_group_topoplots()
%RUN_GROUP_TOPOPLOTS Scalp maps of alpha power: CP, Control and CP - Control.
%   Top row: alpha power (8-13 Hz), dB re 1 uV^2/Hz. Bottom row: alpha relative to
%   theta (4-8 Hz), a dB difference within each channel. Channels with too few
%   Laplacian neighbours or all zeros are left out; see README.md.
    bands = struct('alpha', [8 13], 'theta', [4 8]);
    opts = struct('minChildren', 8, 'excludeChannels', {{'CP1'}});   % CP1's montage entry is wrong

    cfg = mfdb_config();
    paths = project_paths();
    outDir = fullfile(paths.outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    cohort = get_cohort();
    T = compute_channel_band_power(cohort, bands, cfg);
    T.alpha_vs_theta = T.alpha - T.theta;
    outFile = fullfile(outDir, 'channel_band_power.csv');
    writetable(T, outFile);

    rows = {'alpha', 'Alpha power (dB re 1 \muV^2/Hz)', 'Alpha'; ...
            'alpha_vs_theta', 'Alpha relative to theta (dB)', 'Alpha - theta'};
    fig = figure('Color', 'w', 'Position', [50 50 1200 760], 'Visible', 'off');
    tl = tiledlayout(fig, 2, 3, 'TileSpacing', 'compact');
    maps = gobjects(0);  cmaps = {};
    for r = 1:2
        M = group_channel_map(T, rows{r, 1}, opts);
        chanlocs = channel_locations(M.channel);
        limits = [min([M.CP; M.Control]), max([M.CP; M.Control])];
        maps(end + 1) = draw_map(nexttile(tl), M.CP, chanlocs, limits, sprintf('CP: %s', rows{r, 3}), rows{r, 2});
        maps(end + 1) = draw_map(nexttile(tl), M.Control, chanlocs, limits, sprintf('Control: %s', rows{r, 3}), rows{r, 2});
        big = max(abs(M.difference));
        maps(end + 1) = draw_map(nexttile(tl), M.difference, chanlocs, [-big big], ...
            sprintf('CP - Control: %s', rows{r, 3}), 'Difference (dB)');
        cmaps = [cmaps, {parula(256), parula(256), blue_white_red()}]; %#ok<AGROW>
        fprintf('%s: %d channels; F3 CP - Control %.2f dB\n', rows{r, 1}, height(M), M.difference(M.channel == "F3"));
    end
    for k = 1:numel(maps), colormap(maps(k), cmaps{k}); end   % last: topoplot resets the colormap
    title(tl, sprintf('Group medians, %d CP and %d Control children', sum(cohort.groupLabel == "CP"), ...
        sum(cohort.groupLabel == "Control")), 'FontWeight', 'bold');
    exportgraphics(fig, fullfile(outDir, 'alpha_group_topoplots.png'), 'Resolution', 200);
    close(fig);
end

function ax = draw_map(ax, values, chanlocs, limits, name, unit)
    axes(ax);  %#ok<LAXES>
    topoplot(values, chanlocs, 'maplimits', limits, 'electrodes', 'on', 'style', 'map', 'numcontour', 0);
    cb = colorbar(ax);  cb.Label.String = unit;
    title(ax, name);
end

function cmap = blue_white_red()
    half = linspace(0, 1, 128)';
    cmap = [[half; ones(128, 1)], [half; flipud(half)], [ones(128, 1); flipud(half)]];
end
