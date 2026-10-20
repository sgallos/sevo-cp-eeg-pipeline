function out = run_subject_level_power_spectra()
%RUN_SUBJECT_LEVEL_POWER_SPECTRA Figs 1-2 with each child as the unit of analysis.
%   Uses each child's stage 01 F3 spectrum (no new EEG processing) and asks:
%   - CI on the CP - Control median difference, resampling CHILDREN;
%   - which frequency ranges differ, with a cluster permutation test that
%     controls false positives across all 1-40 Hz at once;
%   - per-band differences (delta, theta, alpha, beta, gamma) with effect sizes.
%   Writes to outputs/additional/subject_level_inference/power_spectra/.

    paths = project_paths();
    cfg = mfdb_config();
    cohort = get_cohort();
    outDir = fullfile(paths.outputsDir, 'additional', 'subject_level_inference', 'power_spectra');
    if ~isfolder(outDir), mkdir(outDir); end

    % One row per child: spectrum in dB (for curves) and linear (for band power)
    n = height(cohort);
    for i = n:-1:1
        id = char(cohort.subjectID(i));
        S = load(fullfile(cfg.outputDir, id, [id '_F3_mfdb.mat']), ...
            'freq', 'S_subject_original_dB', 'S_subject_original_linear');
        spectraDB(i, :) = S.S_subject_original_dB;
        spectraLinear(i, :) = S.S_subject_original_linear;
    end
    freq = S.freq(:).';
    isCP = cohort.groupLabel == "CP";

    % 1. CI on the median difference, resampling children
    boot = subject_bootstrap_ci(spectraDB(isCP, :), spectraDB(~isCP, :), struct('statFn', @median));

    % 2. Which frequency ranges differ (cluster permutation test)
    clusters = cluster_permutation_test(spectraDB(isCP, :), spectraDB(~isCP, :), freq);

    % 3. Band power per child, then group comparison per band
    bands = table(["delta"; "theta"; "alpha (8-12)"; "alpha (8-13)"; "beta"; "gamma (30-40)"], ...
        [1; 4; 8; 8; 13; 30], [4; 8; 12; 13; 30; 40], 'VariableNames', {'band', 'lowHz', 'highHz'});
    bandResults = compare_bands(spectraLinear, freq, isCP, bands);

    % The published group CI (measurement noise only), for comparison
    published = load(fullfile(paths.outputsDir, 'mfdb_group_level', 'group_mfdb_bootstrap_results.mat'), ...
        'groupDiff_boot_CI_low_dB', 'groupDiff_boot_CI_high_dB', 'sigMask');

    save(fullfile(outDir, 'subject_level_power_spectra.mat'), 'freq', 'boot', 'clusters', ...
        'bandResults', 'published', 'cohort');
    writetable(clusters.clusters, fullfile(outDir, 'clusters.csv'));
    writetable(bandResults, fullfile(outDir, 'band_comparison.csv'));

    fig = plot_results(freq, boot, clusters, published);
    exportgraphics(fig, fullfile(outDir, 'power_difference_subject_level.png'), 'Resolution', 200);

    fprintf('\nCP - Control power, children as the unit (n = %d CP, %d Control)\n', sum(isCP), sum(~isCP));
    fprintf('Published CI significant bins: %d / %d\n', sum(published.sigMask), numel(freq));
    disp(clusters.clusters(clusters.clusters.p < 0.05, :));
    disp(bandResults);

    out = struct('outDir', outDir, 'clusters', clusters.clusters, 'bands', bandResults, 'fig', fig);
end

function T = compare_bands(spectraLinear, freq, isCP, bands)
    T = bands;
    for k = 1:height(bands)
        mask = freq >= bands.lowHz(k) & freq <= bands.highHz(k);
        powerDB = 10 * log10(trapz(freq(mask), spectraLinear(:, mask), 2));
        cp = powerDB(isCP);
        ctrl = powerDB(~isCP);
        boot = subject_bootstrap_ci(cp, ctrl, struct('statFn', @mean));
        [~, pWelch] = ttest2(cp, ctrl, 'Vartype', 'unequal');
        T.meanCP_dB(k) = mean(cp);
        T.meanControl_dB(k) = mean(ctrl);
        T.difference_dB(k) = mean(cp) - mean(ctrl);
        T.ciLow_dB(k) = boot.ciDifference(1);
        T.ciHigh_dB(k) = boot.ciDifference(2);
        T.hedgesG(k) = hedges_g(cp, ctrl);
        T.pWelch(k) = pWelch;
        T.pRankSum(k) = ranksum(cp, ctrl);
    end
end

function g = hedges_g(a, b)
    na = numel(a); nb = numel(b);
    pooledSD = sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2));
    g = (mean(a) - mean(b)) / pooledSD * (1 - 3 / (4 * (na + nb) - 9));
end

function fig = plot_results(freq, boot, clusters, published)
    fig = figure('Color', 'w', 'Position', [100 100 1100 560]);
    ax = axes(fig); hold(ax, 'on');
    fill(ax, [freq fliplr(freq)], [boot.ciDifference(1, :) fliplr(boot.ciDifference(2, :))], ...
        [0.85 0.33 0.10], 'FaceAlpha', 0.25, 'EdgeColor', 'none');
    fill(ax, [freq fliplr(freq)], [published.groupDiff_boot_CI_low_dB(:).' fliplr(published.groupDiff_boot_CI_high_dB(:).')], ...
        [0 0.45 0.74], 'FaceAlpha', 0.45, 'EdgeColor', 'none');
    plot(ax, freq, boot.difference, 'k', 'LineWidth', 1.2);
    yline(ax, 0, '--', 'Color', [0.4 0.4 0.4]);
    legendText = {'95% CI, children resampled', '95% CI, published (measurement noise only)', ...
        'CP - Control median difference', ''};
    sig = clusters.clusters(clusters.clusters.p < 0.05, :);
    for k = 1:height(sig)
        xregion(ax, sig.xLow(k), sig.xHigh(k), 'FaceColor', [0.2 0.7 0.2], 'FaceAlpha', 0.15);
        legendText{end + 1} = sprintf('Cluster %.1f-%.1f Hz, p = %.3f', sig.xLow(k), sig.xHigh(k), sig.p(k)); %#ok<AGROW>
    end
    xlim(ax, [freq(1) freq(end)]); grid(ax, 'on'); box(ax, 'off');
    xlabel(ax, 'Frequency (Hz)'); ylabel(ax, 'CP - Control (dB)');
    title(ax, 'F3 power: CP - Control, with children as the unit of analysis');
    legend(ax, legendText, 'Location', 'southoutside', 'NumColumns', 2);
end
