function outFile = plot_topoplot_position_check()
%PLOT_TOPOPLOT_POSITION_CHECK Maps of known patterns, to see that maps come out the right way round.
%   Left: value = front-back position, so the front is high. Middle: value = left-right
%   position, so the left is high. Right: only F3 = 1, so one spot at the upper left.
%   The faint dip beside that spot is the interpolation overshooting.
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    cohort = get_cohort();
    labels = strings(0, 1);                  % the child with the most channels
    for s = 1:height(cohort)
        D = load(cohort.dataFile(s), 'HDR');
        if numel(D.HDR.label) > numel(labels), labels = string(D.HDR.label(:)); end
    end
    locs = channel_locations(labels);

    patterns = {[locs.X]', 'Value = front-back position: front should be high'; ...
                [locs.Y]', 'Value = left-right position: LEFT should be high'; ...
                double(strcmpi(labels, 'F3')), 'Only F3 = 1: upper-left spot'};
    fig = figure('Color', 'w', 'Position', [50 50 1200 420], 'Visible', 'off');
    tl = tiledlayout(fig, 1, 3);
    for k = 1:3
        ax = nexttile(tl);
        axes(ax);  %#ok<LAXES>
        topoplot(patterns{k, 1}, locs, 'electrodes', 'labels', 'style', 'map', 'numcontour', 0);
        colorbar(ax);
        title(ax, patterns{k, 2}, 'FontSize', 10);
    end
    outFile = fullfile(outDir, 'topoplot_position_check.png');
    exportgraphics(fig, outFile, 'Resolution', 150);
    close(fig);
end
