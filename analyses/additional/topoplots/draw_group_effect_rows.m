function S = draw_group_effect_rows(T, rows, labels, units, figTitle, outFile, scale)
%DRAW_GROUP_EFFECT_ROWS One row per measure: Control and CP group medians, then CP - Control
%   as Hedges' g with the spatial cluster test. Control and CP share each row's colour scale;
%   g is always drawn from -1.5 to 1.5, so the same colour means the same effect size in
%   every row. Electrodes in a cluster with p < 0.05 are ringed. Returns one table row per
%   electrode and measure (S) and writes the figure to outFile. scale "shared" gives all rows
%   one Control/CP colour scale (for the same measure computed several ways).
    if nargin < 7, scale = "row"; end
    opts = topoplot_channel_rules();
    shared = [];
    if scale == "shared"
        for i = 1:numel(rows), M = group_channel_map(T, char(rows(i)), opts); shared = [shared; M.Control; M.CP]; end %#ok<AGROW>
    end
    fig = figure('Color', 'w', 'Position', [50 50 1250 380 * numel(rows)], 'Visible', 'off');
    tl = tiledlayout(fig, numel(rows), 3, 'TileSpacing', 'compact');
    maps = gobjects(0);  cmaps = {};  S = table();
    for i = 1:numel(rows)
        [M, clusters] = group_effect_map(T, char(rows(i)), opts);
        chanlocs = channel_locations(M.channel);
        limits = [min([M.Control; M.CP]), max([M.Control; M.CP])];
        if ~isempty(shared), limits = [min(shared), max(shared)]; end
        maps(end + 1) = draw_map(nexttile(tl), M.Control, chanlocs, limits, "Control: " + labels(i), units(i), []); %#ok<AGROW>
        maps(end + 1) = draw_map(nexttile(tl), M.CP, chanlocs, limits, "CP: " + labels(i), units(i), []); %#ok<AGROW>
        maps(end + 1) = draw_map(nexttile(tl), M.g, chanlocs, [-1.5 1.5], ...
            ["CP - Control: " + labels(i), "blue = lower in CP, in between-child SDs", cluster_note(clusters)], ...
            'Hedges'' g (effect size)', M.inCluster); %#ok<AGROW>
        cmaps = [cmaps, {jet(256), jet(256), blue_white_red()}]; %#ok<AGROW>
        M.measure = repmat(rows(i), height(M), 1);
        best = NaN;  if ~isempty(clusters), best = clusters.p(1); end
        M.bestClusterP = repmat(best, height(M), 1);
        S = [S; M(:, {'measure', 'channel', 'Control', 'CP', 'difference', 'nControl', 'nCP', 'g', 't', 'inCluster', 'bestClusterP'})]; %#ok<AGROW>
    end
    for k = 1:numel(maps), colormap(maps(k), cmaps{k}); end   % last: topoplot resets the colormap
    title(tl, figTitle, 'FontWeight', 'bold');
    exportgraphics(fig, outFile, 'Resolution', 200);
    close(fig);
end

function note = cluster_note(clusters)
    if isempty(clusters)
        note = "no electrode above the cluster threshold";
    elseif clusters.p(1) < 0.05
        note = sprintf("cluster p = %.3f (ringed)", clusters.p(1));
    elseif clusters.nElectrodes(1) == 1
        note = sprintf("largest cluster: 1 electrode, p = %.2f", clusters.p(1));
    else
        note = sprintf("largest cluster: %d electrodes, p = %.2f", clusters.nElectrodes(1), clusters.p(1));
    end
end

function ax = draw_map(ax, values, chanlocs, limits, name, unit, ringed)
    axes(ax);  %#ok<LAXES>
    topoplot(values, chanlocs, 'maplimits', limits, 'electrodes', 'on', 'style', 'map', 'numcontour', 0);
    mask_unmeasured_area(ax);
    if any(ringed)   % after masking; topoplot draws the electrodes in channel order
        e = findobj(ax, 'Type', 'line', 'Marker', '.');
        hold(ax, 'on');
        z = max(e(1).ZData(:)) + 1;
        plot3(ax, e(1).XData(ringed), e(1).YData(ringed), z * ones(1, sum(ringed)), 'o', ...
            'Color', 'k', 'MarkerSize', 8, 'LineWidth', 1.4);
    end
    cb = colorbar(ax);  cb.Label.String = unit;
    title(ax, name, 'FontWeight', 'normal');
end

function cmap = blue_white_red()
    half = linspace(0, 1, 128)';
    cmap = [[half; ones(128, 1)], [half; flipud(half)], [ones(128, 1); flipud(half)]];
end
