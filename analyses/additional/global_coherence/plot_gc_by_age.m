function outFile = plot_gc_by_age(band, groupLabel)
%PLOT_GC_BY_AGE Spatial coherence |u_1|^2, one map per child, youngest to oldest.
%   PLOT_GC_BY_AGE('alpha', 'Control'). The layout of topoplots/plot_band_by_age.m. Each title
%   gives age, number of electrodes and the child's global coherence in the band. One colour
%   scale for both groups (2nd to 98th percentile), so the two figures compare.
    nColumns = 4;
    outDir = fullfile(project_paths().outputsDir, 'additional', 'global_coherence');
    cohort = get_cohort();
    [W, G] = load_child_gc(cohort);
    edges = state_space_bands();
    edge = edges(string({edges.name}) == string(band));
    limits = prctile(W.(band), [2 98]);
    G = sortrows(G(G.groupLabel == string(groupLabel), :), 'ageYears');

    n = height(G);  nRows = ceil(n / nColumns);
    fig = figure('Color', 'w', 'Position', [50 50 300 * nColumns, 300 * nRows], 'Visible', 'off');
    tl = tiledlayout(fig, nRows, nColumns, 'TileSpacing', 'compact', 'Padding', 'compact');
    maps = gobjects(n, 1);
    for i = 1:n
        here = W(W.subjectID == G.subjectID(i), :);
        maps(i) = nexttile(tl);  axes(maps(i));  %#ok<LAXES>
        topoplot(here.(band), channel_locations(here.channel), 'maplimits', limits, ...
            'electrodes', 'on', 'style', 'map', 'numcontour', 0);
        mask_unmeasured_area(maps(i));
        title(maps(i), sprintf('%.1f y, %d electrodes, GC %.2f', G.ageYears(i), G.nElectrodes(i), G.("gc_" + band)(i)), ...
            'FontWeight', 'normal', 'FontSize', 11);
    end
    for i = 1:n, colormap(maps(i), jet(256)); end
    cb = colorbar(maps(end));  cb.Layout.Tile = 'east';
    cb.Label.String = sprintf('Spatial coherence |u_1|^2, %g-%g Hz', edge.lowHz, edge.highHz);
    title(tl, sprintf('%s children: %s spatial coherence and global coherence (GC) by age, youngest to oldest', ...
        groupLabel, band), 'FontWeight', 'bold');
    outFile = fullfile(outDir, sprintf('gc_%s_by_age_%s.png', band, lower(groupLabel)));
    exportgraphics(fig, outFile, 'Resolution', 200);
    close(fig);
end
