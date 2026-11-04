function outFile = run_group_topoplots()
%RUN_GROUP_TOPOPLOTS Scalp maps of alpha, delta and theta power, one row per band.
%   Columns: Control and CP group medians (dB re 1 uV^2/Hz, one colour scale per band),
%   then CP - Control as Hedges' g with the spatial cluster test. Band edges as in the
%   published F3 analyses (state_space_bands.m); the state-space model itself is not used. Saves the figure and group_map_statistics.csv; see README.md.
    edges = state_space_bands();
    [~, order] = ismember(["alpha" "delta" "theta"], string({edges.name}));
    edges = edges(order);

    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    cohort = get_cohort();
    T = load_channel_band_power(cohort);
    labels = arrayfun(@(e) sprintf('%s%s, %g-%g Hz', upper(e.name(1)), e.name(2:end), e.lowHz, e.highHz), ...
        edges, 'UniformOutput', false);
    S = draw_group_effect_rows(T, string({edges.name}), string(labels), repmat("dB re 1 \muV^2/Hz", 1, numel(edges)), ...
        sprintf('Band power, group medians, %d Control and %d CP children; CP - Control as Hedges'' g', ...
        sum(cohort.groupLabel == "Control"), sum(cohort.groupLabel == "CP")), ...
        fullfile(outDir, 'band_power_group_topoplots.png'));
    outFile = fullfile(outDir, 'group_map_statistics.csv');
    save_statistics(S, outFile);
end
