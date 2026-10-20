function out = run_subject_level_coherence()
%RUN_SUBJECT_LEVEL_COHERENCE Fig 07, complementary population-level inference.
%   The published Bokil test (stage 05) treats each 2 s window x taper as a
%   trial, conditional on the observed children. This asks whether the
%   differences generalize to new children, using each child's coherence
%   curve from stage 05 (no new EEG processing):
%   - alpha coherence (8-13 Hz), one number per child: Welch t, rank-sum,
%     permutation p, and effect size with a children-resampled CI;
%   - which frequency ranges differ: cluster permutation test over children
%     on Fisher-z coherence (atanh), controlling false positives across 0.5-40 Hz.
%   Writes to outputs/additional/subject_level_inference/coherence/.

    paths = project_paths();
    outDir = fullfile(paths.outputsDir, 'additional', 'subject_level_inference', 'coherence');
    if ~isfolder(outDir), mkdir(outDir); end

    R = load(fullfile(paths.outputsDir, 'coherence_group_level', 'group_f3f4_coherence_results.mat'), ...
        'freq', 'controlSpectra', 'cpSpectra', 'alphaComparison', 'inference', 'subjectTable');
    freq = R.freq(:).';
    cp = R.cpSpectra;
    ctrl = R.controlSpectra;

    % Alpha coherence: one value per child
    a = R.alphaComparison;
    [~, pWelch] = ttest2(a.cpValues, a.controlValues, 'Vartype', 'unequal');
    pPerm = permutation_p(a.cpValues(:), a.controlValues(:), 10000);
    alphaBoot = subject_bootstrap_ci(a.cpValues(:), a.controlValues(:), struct('statFn', @median));
    alpha = table(numel(a.cpValues), numel(a.controlValues), median(a.cpValues), median(a.controlValues), ...
        alphaBoot.difference, alphaBoot.ciDifference(1), alphaBoot.ciDifference(2), ...
        hedges_g(a.cpValues(:), a.controlValues(:)), a.ttestP, pWelch, a.ranksumP, pPerm, ...
        'VariableNames', {'nCP', 'nControl', 'medianCP', 'medianControl', 'medianDifference', ...
        'ciLow', 'ciHigh', 'hedgesG', 'pTtestPooled', 'pWelch', 'pRankSum', 'pPermutation'});

    % Spectrum: children-resampled CI and cluster test on Fisher z
    curveBoot = subject_bootstrap_ci(cp, ctrl, struct('statFn', @median));
    clusters = cluster_permutation_test(cp, ctrl, freq, struct('transform', @atanh));

    writetable(alpha, fullfile(outDir, 'alpha_coherence_per_child_test.csv'));
    writetable(clusters.clusters, fullfile(outDir, 'clusters.csv'));
    save(fullfile(outDir, 'subject_level_coherence.mat'), 'freq', 'alpha', 'curveBoot', 'clusters');

    fig = plot_results(freq, curveBoot, clusters, R.inference, a, alpha);
    exportgraphics(fig, fullfile(outDir, 'coherence_subject_level.png'), 'Resolution', 200);

    fprintf('\nF3-F4 coherence, children as the unit (n = %d CP, %d Control)\n', alpha.nCP, alpha.nControl);
    disp(alpha);
    disp(clusters.clusters(clusters.clusters.p < 0.05, :));
    out = struct('outDir', outDir, 'alpha', alpha, 'clusters', clusters.clusters, 'fig', fig);
end

function p = permutation_p(a, b, nPerm)
    rng(mfdb_config().randomSeed);
    all = [a; b];
    isA = [true(numel(a), 1); false(numel(b), 1)];
    observed = abs(median(a) - median(b));
    hits = 0;
    for k = 1:nPerm
        s = isA(randperm(numel(isA)));
        hits = hits + (abs(median(all(s)) - median(all(~s))) >= observed);
    end
    p = (hits + 1) / (nPerm + 1);
end

function g = hedges_g(a, b)
    na = numel(a); nb = numel(b);
    pooledSD = sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2));
    g = (mean(a) - mean(b)) / pooledSD * (1 - 3 / (4 * (na + nb) - 9));
end

function fig = plot_results(freq, boot, clusters, published, a, alpha)
    ctrlColor = [0.90 0.45 0.10];
    cpColor = [0.20 0.45 0.85];
    fig = figure('Color', 'w', 'Position', [100 100 1150 520]);
    tl = tiledlayout(fig, 1, 3, 'TileSpacing', 'compact');

    ax1 = nexttile(tl, [1 2]); hold(ax1, 'on');
    band(ax1, freq, boot.ciB, ctrlColor);
    band(ax1, freq, boot.ciA, cpColor);
    plot(ax1, freq, boot.estimateB, '-', 'Color', ctrlColor, 'LineWidth', 2, 'DisplayName', 'Control median');
    plot(ax1, freq, boot.estimateA, '-', 'Color', cpColor, 'LineWidth', 2, 'DisplayName', 'CP median');
    yl = [0.3 0.85];
    ylim(ax1, yl);
    % Published Bokil bands (pooled windows) as a thin strip at the top,
    % child-level clusters as a strip just below it.
    draw_strip(ax1, freq, logical(published.sigMask_contiguous(:).'), yl(2) - 0.02, [0.8 0.3 0.3], 'Published Bokil test (conditional)');
    sig = clusters.clusters(clusters.clusters.p < 0.05, :);
    sigMask = false(size(freq));
    for k = 1:height(sig)
        sigMask = sigMask | (freq >= sig.xLow(k) & freq <= sig.xHigh(k));
    end
    draw_strip(ax1, freq, sigMask, yl(2) - 0.045, [0.2 0.65 0.2], 'Population-level clusters, p < 0.05');
    xlim(ax1, [freq(1) freq(end)]); grid(ax1, 'on'); box(ax1, 'off');
    xlabel(ax1, 'Frequency (Hz)'); ylabel(ax1, 'F3-F4 coherence');
    title(ax1, 'Median coherence, 95% CI resampling children');
    legend(ax1, 'Location', 'east');

    ax2 = nexttile(tl); hold(ax2, 'on');
    swarm(ax2, 1, a.controlValues, ctrlColor);
    swarm(ax2, 2, a.cpValues, cpColor);
    xticks(ax2, [1 2]); xticklabels(ax2, {'Control', 'CP'}); xlim(ax2, [0.4 2.6]);
    ylabel(ax2, 'Alpha coherence (8-13 Hz), one dot per child');
    title(ax2, sprintf('g = %.2f, permutation p = %.3f', alpha.hedgesG, alpha.pPermutation));
    grid(ax2, 'on'); box(ax2, 'off');
end

function band(ax, x, ci, c)
    fill(ax, [x fliplr(x)], [ci(1, :) fliplr(ci(2, :))], c, 'FaceAlpha', 0.2, 'EdgeColor', 'none', ...
        'HandleVisibility', 'off');
end

function draw_strip(ax, freq, mask, y, c, label)
    yy = nan(size(freq));
    yy(mask) = y;
    plot(ax, freq, yy, '-', 'Color', c, 'LineWidth', 6, 'DisplayName', label);
end

function swarm(ax, x, v, c)
    jitter = linspace(-0.15, 0.15, numel(v));
    scatter(ax, x + jitter(randperm(numel(v))), v, 50, c, 'filled', 'MarkerEdgeColor', 'k', 'HandleVisibility', 'off');
    plot(ax, x + [-0.25 0.25], median(v) * [1 1], 'k-', 'LineWidth', 2, 'HandleVisibility', 'off');
end
