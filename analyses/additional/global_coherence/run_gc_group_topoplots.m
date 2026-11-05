function outFile = run_gc_group_topoplots()
%RUN_GC_GROUP_TOPOPLOTS Spatial coherence maps, Control, CP and CP - Control, for alpha, delta, theta.
%   The layout of the band power maps (topoplots/run_group_topoplots.m): group medians of
%   |u_1|^2 with one colour scale per band, then CP - Control as Hedges' g with the spatial
%   cluster test (draw_group_effect_rows.m). The title gives each band's global coherence
%   (group medians, Hedges' g and a rank-sum p). Writes gc_group_topoplots.png,
%   gc_group_map_statistics.csv and gc_band_statistics.csv.
    outDir = fullfile(project_paths().outputsDir, 'additional', 'global_coherence');
    cohort = get_cohort();
    [W, G] = load_child_gc(cohort);
    edges = state_space_bands();
    bands = ["alpha" "delta" "theta"];
    [~, order] = ismember(bands, string({edges.name}));  edges = edges(order);
    labels = arrayfun(@(e) sprintf('%s, %g-%g Hz', upper(e.name), e.lowHz, e.highHz), edges, 'UniformOutput', false);

    stats = band_statistics(G, bands);
    writetable(stats, fullfile(outDir, 'gc_band_statistics.csv'));
    lines = arrayfun(@(i) sprintf('%s GC: Control %.3f, CP %.3f, g = %.2f, p = %.2f', upper(stats.band(i)), ...
        stats.controlMedian(i), stats.cpMedian(i), stats.g(i), stats.rankSumP(i)), 1:height(stats), 'UniformOutput', false);
    figTitle = {sprintf(['Spatial coherence |u_1|^2 (Cornelissen 2018), group medians, %d Control and %d CP children; ' ...
        'CP - Control as Hedges'' g'], sum(cohort.groupLabel == "Control"), sum(cohort.groupLabel == "CP")), ...
        ['Global coherence (group medians): ' strjoin(lines, ';   ')]};
    S = draw_group_effect_rows(W, bands, string(labels), repmat("|u_1|^2 (share of the mode)", 1, numel(bands)), ...
        figTitle, fullfile(outDir, 'gc_group_topoplots.png'));
    outFile = fullfile(outDir, 'gc_group_map_statistics.csv');
    writetable(S, outFile);
end

function stats = band_statistics(G, bands)
    stats = table();
    for b = bands
        cp = G.("gc_" + b)(G.groupLabel == "CP");  control = G.("gc_" + b)(G.groupLabel == "Control");
        nCP = numel(cp);  nC = numel(control);
        pooled = sqrt(((nCP - 1) * var(cp) + (nC - 1) * var(control)) / (nCP + nC - 2));
        g = (mean(cp) - mean(control)) / pooled * (1 - 3 / (4 * (nCP + nC) - 9));
        stats = [stats; table(b, median(control), median(cp), g, ranksum(cp, control), nC, nCP, ...
            'VariableNames', {'band', 'controlMedian', 'cpMedian', 'g', 'rankSumP', 'nControl', 'nCP'})]; %#ok<AGROW>
    end
end
