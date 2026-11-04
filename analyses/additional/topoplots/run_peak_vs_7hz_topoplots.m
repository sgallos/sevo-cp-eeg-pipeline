function outFile = run_peak_vs_7hz_topoplots()
%RUN_PEAK_VS_7HZ_TOPOPLOTS Scalp maps of the alpha peak vs 7 Hz, beside delta and theta power.
%   Same layout as run_group_topoplots.m. Peak vs 7 Hz is dB power at the child's own alpha
%   peak minus dB power at 7 Hz (peak_vs_7hz.m). Adds its rows to group_map_statistics.csv.
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    cohort = get_cohort();
    T = load_channel_peak_power(cohort);
    B = load_channel_band_power(cohort);
    T = outerjoin(T, B(:, {'subjectID', 'channel', 'delta', 'theta'}), ...
        'Keys', {'subjectID', 'channel'}, 'MergeKeys', true, 'Type', 'left');
    dB = "dB re 1 \muV^2/Hz";
    S = draw_group_effect_rows(T, ["peakVs7" "delta" "theta"], ...
        ["Alpha peak vs 7 Hz" "Delta, 1-4 Hz" "Theta, 4-8 Hz"], ["dB (peak - 7 Hz)" dB dB], ...
        sprintf('Alpha peak vs 7 Hz with delta and theta, %d Control and %d CP children; CP - Control as Hedges'' g', ...
        sum(cohort.groupLabel == "Control"), sum(cohort.groupLabel == "CP")), ...
        fullfile(outDir, 'peak_vs_7hz_group_topoplots.png'));
    outFile = fullfile(outDir, 'group_map_statistics.csv');
    save_statistics(S(S.measure == "peakVs7", :), outFile);
end
