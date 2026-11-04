function outFile = run_specparam_topoplots()
%RUN_SPECPARAM_TOPOPLOTS Specparam (FOOOF) alpha height and 1/f background across the scalp.
%   Two figures in the layout of run_group_topoplots.m (Control, CP, Hedges' g with the
%   spatial cluster test):
%   - specparam_alpha_height_topoplots.png: alpha height above the background for the three
%     fit ranges (2-30 Hz main, 1-30 and 2-40 Hz), on one colour scale; a sensitivity test
%   - specparam_background_topoplots.png: offset and exponent of the main fit
%   Needs specparam_fits.csv (fit_specparam.py); see README.md. Adds its rows to
%   group_map_statistics.csv.
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    cohort = get_cohort();
    T = load_map_values(cohort);
    assert(ismember('alphaHeight_main', T.Properties.VariableNames), ...
        'specparam_fits.csv not found: run export_spectra_for_specparam and fit_specparam.py first.');
    n = sprintf('%d Control and %d CP children; CP - Control as Hedges'' g', ...
        sum(cohort.groupLabel == "Control"), sum(cohort.groupLabel == "CP"));
    S1 = draw_group_effect_rows(T, ["alphaHeight_main" "alphaHeight_low" "alphaHeight_wide"], ...
        ["Alpha height, fit 2-30 Hz (main)" "Alpha height, fit 1-30 Hz" "Alpha height, fit 2-40 Hz"], ...
        ["dB above background" "dB above background" "dB above background"], ...
        "Sensitivity: specparam alpha height for three fit ranges, " + n, ...
        fullfile(outDir, 'specparam_alpha_height_topoplots.png'), "shared");
    S2 = draw_group_effect_rows(T, ["offset_main" "exponent_main"], ["Offset (fit 2-30 Hz)" "Exponent (fit 2-30 Hz)"], ...
        ["dB at 1 Hz" "exponent"], "Specparam 1/f background, " + n, ...
        fullfile(outDir, 'specparam_background_topoplots.png'));
    outFile = fullfile(outDir, 'group_map_statistics.csv');
    save_statistics([S1; S2], outFile);
end
