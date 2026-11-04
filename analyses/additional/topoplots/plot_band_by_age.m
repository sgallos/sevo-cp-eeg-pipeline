function outFile = plot_band_by_age(band, groupLabel)
%PLOT_BAND_BY_AGE One map per child, youngest to oldest, on one colour scale.
%   PLOT_BAND_BY_AGE('alpha', 'Control'); band is 'alpha', 'theta', 'delta' or 'peakVs7'
%   (alpha peak vs 7 Hz) and groupLabel 'Control' or 'CP'. Maps read left to right, then
%   down, and use the electrodes of the
%   group maps; a child needs at least minElectrodes of them (topoplot_channel_rules.m).
%   The colour scale covers the 2nd to 98th percentile of that band in both groups, so the
%   two groups' figures compare and one extreme channel does not set it. Titles give age
%   and electrode count only, so the figure can be shown publicly.
    nColumns = 4;
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    cohort = get_cohort();
    T = load_map_values(cohort);
    if string(band) == "peakVs7"
        label = 'Alpha peak vs 7 Hz (dB)';  name = 'alpha peak vs 7 Hz';
    else
        edges = state_space_bands();
        edge = edges(string({edges.name}) == string(band));
        label = sprintf('%s%s power, %g-%g Hz (dB re 1 \\muV^2/Hz)', upper(band(1)), band(2:end), edge.lowHz, edge.highHz);
        name = sprintf('%s power', band);
    end
    opts = topoplot_channel_rules();
    channels = group_channel_map(T, char(band), opts).channel;
    T = T(T.isUsable & ismember(T.channel, channels) & ~isnan(T.(band)), :);
    [children, ~, which] = unique(T.subjectID);
    children = children(accumarray(which, 1) >= opts.minElectrodes);
    T = T(ismember(T.subjectID, children), :);
    cohort = cohort(cohort.groupLabel == string(groupLabel) & ismember(string(cohort.subjectID), children), :);
    cohort = sortrows(cohort, 'ageYears');
    limits = prctile(T.(band), [2 98]);                 % both groups, so their figures compare
    T = T(T.groupLabel == string(groupLabel), :);

    nChildren = height(cohort);
    nRows = ceil(nChildren / nColumns);
    fig = figure('Color', 'w', 'Position', [50 50 300 * nColumns, 300 * nRows], 'Visible', 'off');
    tl = tiledlayout(fig, nRows, nColumns, 'TileSpacing', 'compact', 'Padding', 'compact');
    maps = gobjects(nChildren, 1);
    for s = 1:nChildren
        here = T(T.subjectID == string(cohort.subjectID(s)), :);
        maps(s) = nexttile(tl);
        axes(maps(s));  %#ok<LAXES>
        topoplot(here.(band), channel_locations(here.channel), 'maplimits', limits, ...
            'electrodes', 'on', 'style', 'map', 'numcontour', 0);
        mask_unmeasured_area(maps(s));
        title(maps(s), sprintf('%.1f y, %d electrodes', cohort.ageYears(s), height(here)), ...
            'FontWeight', 'normal', 'FontSize', 11);
    end
    for s = 1:nChildren, colormap(maps(s), jet(256)); end   % last: topoplot resets the colormap
    cb = colorbar(maps(end));
    cb.Layout.Tile = 'east';
    cb.Label.String = label;
    title(tl, sprintf('%s children: %s by age, youngest to oldest', groupLabel, name), 'FontWeight', 'bold');
    outFile = fullfile(outDir, sprintf('%s_by_age_%s.png', band, lower(groupLabel)));
    exportgraphics(fig, outFile, 'Resolution', 200);
    close(fig);
end
