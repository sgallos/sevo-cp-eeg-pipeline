function out = run_ssm_smoothness_grid(bandName)
%RUN_SSM_SMOOTHNESS_GRID How straight or wobbly can the state-space curves be?
%   out = RUN_SSM_SMOOTHNESS_GRID("alpha") fits the stage 06 state-space model
%   (same equations, same data) across a grid of smoothness settings and asks
%   which the data support and whether the CP - Control gap depends on it.
%
%   1. Grid: baseline smoothness q_f0 and gap smoothness q_delta, each at
%      qInit x {1e-6 ... 1e4} (extremes plus a fine grid near the default).
%      In every cell the observation noise r is re-fitted (maximum likelihood),
%      so the surface is a true profile likelihood over (q_f0, q_delta).
%   2. Extreme gap shapes: straight line, constant, and no gap at all.
%   3. Robustness of the published setting to the two settings never varied:
%      the starting (prior) uncertainty and the minimum age-gap floor.
%   Writes to outputs/additional/ssm_smoothness_grid/<band>/.

    multipliers = [1e-6 1e-4 1e-2 0.1 0.3 1 3 10 1e2 1e4];
    publishedIndex = find(multipliers == 1);
    supportedDrop = 3;   % cells within 3 log-lik units of the best: ~95% region for 2 parameters
    tiny = 1e-10;        % "zero" variance for extreme models (kept > 0 for numerical stability)

    paths = project_paths();
    band = state_space_bands();
    band = band([band.name] == string(bandName));
    outDir = fullfile(paths.outputsDir, 'additional', 'ssm_smoothness_grid', char(band.name));
    if ~isfolder(outDir), mkdir(outDir); end

    raw = readtable(fullfile(state_space_outputs_dir(), 'power_table_for_ssm_subepochs_collapsed.csv'), ...
        'TextType', 'string');
    T = table(string(raw.subjectID), string(raw.groupLabel), double(raw.ageYears), ...
        double(raw.(band.column)), zeros(height(raw), 1), ...
        'VariableNames', {'subjectID', 'groupLabel', 'ageYears', 'alpha_dB', 'mfdb_var'});
    qInit = (max(T.alpha_dB) - min(T.alpha_dB))^2 / (max(T.ageYears) - min(T.ageYears))^3;

    % ---- 1. Smoothness grid -------------------------------------------------
    n = numel(multipliers);
    grid = repmat(empty_cell(), n, n);
    for i = 1:n
        for j = 1:n
            grid(i, j) = fit_cell(T, qInit * multipliers(i), qInit * multipliers(j), struct());
        end
        fprintf('  %s grid row %d/%d\n', band.name, i, n);
    end
    logLik = reshape([grid.logLikelihood], n, n);
    [bestLogLik, k] = max(logLik(:));
    [bi, bj] = ind2sub([n n], k);
    supported = logLik >= bestLogLik - supportedDrop;

    gridTable = table();
    for i = 1:n
        for j = 1:n
            c = grid(i, j);
            gridTable = [gridTable; table(multipliers(i), multipliers(j), c.qF0, c.qDelta, c.r, ...
                c.logLikelihood, c.logLikelihood - bestLogLik, supported(i, j), c.meanGap, c.minGap, ...
                c.maxGap, c.gapChange, c.wobble, c.exclusionAgeLow, c.exclusionAgeHigh, ...
                'VariableNames', {'qF0_multiplier', 'qDelta_multiplier', 'qF0', 'qDelta', 'r', ...
                'logLik', 'deltaLogLik', 'supported', 'meanGap_dB', 'minGap_dB', 'maxGap_dB', ...
                'gapChange_dB', 'wobble_dB', 'gapBelowZeroFromAge', 'gapBelowZeroToAge'})]; %#ok<AGROW>
        end
    end

    % ---- 2. Extreme gap shapes (baseline smoothness at its best value) -------
    % Log Bayes factors depend on the prior on the gap, so repeat at prior SD 3, 10, 30 dB.
    qF0Best = qInit * multipliers(bi);
    shapeNames = ["Flexible gap (best grid cell)"; "Straight-line gap"; "Constant gap"; "No gap (CP = Control)"];
    priorSD = [3 10 30];
    shapeTable = table();
    for p = 1:numel(priorSD)
        v = priorSD(p)^2;
        specs = {
            qInit * multipliers(bj), struct('initialCovarianceScale', v)
            tiny,                    struct('initialCovarianceScale', v)
            tiny,                    struct('initialCovarianceDiag', [v v v tiny])
            tiny,                    struct('initialCovarianceDiag', [v v tiny tiny])};
        block = table();
        for s = 1:numel(shapeNames)
            c = fit_cell(T, qF0Best, specs{s, 1}, specs{s, 2});
            block = [block; table(shapeNames(s), priorSD(p), c.logLikelihood, c.r, c.meanGap, ...
                c.exclusionAgeLow, c.exclusionAgeHigh, ...
                'VariableNames', {'gapShape', 'priorSD_dB', 'logLik', 'r', 'meanGap_dB', ...
                'gapBelowZeroFromAge', 'gapBelowZeroToAge'})]; %#ok<AGROW>
        end
        block.logBayesFactorVsNoGap = block.logLik - block.logLik(end);
        shapeTable = [shapeTable; block]; %#ok<AGROW>
    end

    % ---- 3. Robustness of the published setting ------------------------------
    qPub = qInit * multipliers(publishedIndex);
    checks = {
        'Published (prior SD 10 dB, age-gap floor 0.05 yr)', struct()
        'Prior SD 3 dB',  struct('initialCovarianceScale', 9)
        'Prior SD 30 dB', struct('initialCovarianceScale', 900)
        'Age-gap floor 0.01 yr', struct('minAgeGapYears', 0.01)
        'Age-gap floor 0.2 yr',  struct('minAgeGapYears', 0.2)};
    robustTable = table();
    for s = 1:size(checks, 1)
        c = fit_cell(T, qPub, qPub, checks{s, 2});
        robustTable = [robustTable; table(string(checks{s, 1}), c.r, c.meanGap, c.minGap, c.maxGap, ...
            c.exclusionAgeLow, c.exclusionAgeHigh, ...
            'VariableNames', {'setting', 'r', 'meanGap_dB', 'minGap_dB', 'maxGap_dB', ...
            'gapBelowZeroFromAge', 'gapBelowZeroToAge'})]; %#ok<AGROW>
    end

    % ---- Summary --------------------------------------------------------------
    sup = gridTable(gridTable.supported, :);
    summary = table(string(band.name), qInit, multipliers(bi), multipliers(bj), bestLogLik, ...
        logLik(publishedIndex, publishedIndex) - bestLogLik, sum(supported(:)), ...
        min(sup.meanGap_dB), max(sup.meanGap_dB), all(isfinite(sup.gapBelowZeroFromAge)), ...
        shapeTable.logBayesFactorVsNoGap(shapeTable.gapShape == "Constant gap" & shapeTable.priorSD_dB == 10), ...
        'VariableNames', {'band', 'qInit', 'bestQF0_multiplier', 'bestQDelta_multiplier', 'bestLogLik', ...
        'publishedDeltaLogLik', 'nSupportedCells', 'supportedMeanGapMin_dB', 'supportedMeanGapMax_dB', ...
        'gapExcludesZeroInAllSupportedCells', 'constantGap_logBFvsNoGap'});

    writetable(gridTable, fullfile(outDir, 'grid.csv'));
    writetable(shapeTable, fullfile(outDir, 'gap_shapes.csv'));
    writetable(robustTable, fullfile(outDir, 'robustness.csv'));
    writetable(summary, fullfile(outDir, 'summary.csv'));
    save(fullfile(outDir, 'ssm_smoothness_grid.mat'), 'grid', 'gridTable', 'shapeTable', ...
        'robustTable', 'summary', 'multipliers', 'qInit');

    fig = plot_grid(band.name, multipliers, logLik - bestLogLik, supported, publishedIndex, [bi bj], grid);
    exportgraphics(fig, fullfile(outDir, 'smoothness_grid.png'), 'Resolution', 170);
    close(fig);

    out = struct('outDir', outDir, 'summary', summary, 'shapes', shapeTable, 'robustness', robustTable);
end

function c = fit_cell(T, qF0, qDelta, extra)
    % Fix both smoothness values and find the noise variance r that maximizes
    % the exact Kalman log-likelihood (a 1-D search over log r). This is the
    % profile likelihood, and it avoids EM's near-singular E-step when q is tiny.
    minGap = get_field(extra, 'minAgeGapYears', 0.05);
    priorArgs = {'initialCovarianceScale', get_field(extra, 'initialCovarianceScale', 100)};
    if isfield(extra, 'initialCovarianceDiag')
        priorArgs = [priorArgs, {'initialCovarianceDiag', extra.initialCovarianceDiag}];
    end
    model = @(r) SS_age_diff(T, 'observationVarianceMode', 'scalar_r', 'observationVarianceR', r, ...
        'processNoiseQF0', qF0, 'processNoiseQDelta', qDelta, 'minAgeGapYears', minGap, ...
        priorArgs{:}, 'verbose', false);
    negLogLik = @(logR) -model(exp(logR)).logLikelihood;
    logRBest = fminbnd(negLogLik, log(1e-4), log(1e4), optimset('TolX', 1e-6));
    rBest = exp(logRBest);
    fit = model(rBest);

    traj = sortrows(fit.trajectory, 'ageYears');
    below = traj.deltaCIHigh_dB < 0;
    c = empty_cell();
    c.qF0 = qF0;  c.qDelta = qDelta;  c.r = rBest;
    c.logLikelihood = fit.logLikelihood;
    c.ages = traj.ageYears;
    c.gap = traj.deltaMean_dB;
    c.gapLow = traj.deltaCILow_dB;
    c.gapHigh = traj.deltaCIHigh_dB;
    c.meanGap = mean(traj.deltaMean_dB);
    c.minGap = min(traj.deltaMean_dB);
    c.maxGap = max(traj.deltaMean_dB);
    c.gapChange = traj.deltaMean_dB(end) - traj.deltaMean_dB(1);
    c.wobble = sum(abs(diff(traj.deltaMean_dB)));   % total up-and-down movement of the gap curve
    if any(below)
        c.exclusionAgeLow = min(traj.ageYears(below));
        c.exclusionAgeHigh = max(traj.ageYears(below));
    end
end

function c = empty_cell()
    c = struct('qF0', NaN, 'qDelta', NaN, 'r', NaN, 'logLikelihood', NaN, 'ages', [], 'gap', [], ...
        'gapLow', [], 'gapHigh', [], 'meanGap', NaN, 'minGap', NaN, 'maxGap', NaN, 'gapChange', NaN, ...
        'wobble', NaN, 'exclusionAgeLow', NaN, 'exclusionAgeHigh', NaN);
end

function v = get_field(s, name, default)
    if isfield(s, name), v = s.(name); else, v = default; end
end

function fig = plot_grid(bandName, m, dLogLik, supported, pubIdx, bestIdx, cells)
    fig = figure('Color', 'w', 'Position', [100 100 1400 760]);
    tl = tiledlayout(fig, 2, 4, 'TileSpacing', 'compact');
    title(tl, sprintf('%s band: how straight or wobbly can the curves be?', bandName), 'FontWeight', 'bold');

    % Left: profile log-likelihood over the grid
    ax = nexttile(tl, 1, [2 2]);
    imagesc(ax, log10(m), log10(m), max(dLogLik, -20));
    set(ax, 'YDir', 'normal');
    colormap(ax, parula);  cb = colorbar(ax);  cb.Label.String = 'log-likelihood minus best (floored at -20)';
    hold(ax, 'on');
    contour(ax, log10(m), log10(m), double(supported), [0.5 0.5], 'w', 'LineWidth', 2);
    plot(ax, log10(m(pubIdx)), log10(m(pubIdx)), 'wp', 'MarkerSize', 16, 'MarkerFaceColor', 'k');
    plot(ax, log10(m(bestIdx(2))), log10(m(bestIdx(1))), 'wo', 'MarkerSize', 12, 'LineWidth', 2.5);
    title(ax, {'Profile likelihood (r re-fitted in every cell)', ...
        'white line: supported region (within 3); star: published; circle: best'});
    decades = log10(m(abs(log10(m) - round(log10(m))) < 1e-9));
    xticks(ax, decades);  yticks(ax, decades);
    xticklabels(ax, compose('10^{%d}', round(decades)));  yticklabels(ax, compose('10^{%d}', round(decades)));
    xlabel(ax, 'gap wobbliness q_\delta (x default)');  ylabel(ax, 'baseline wobbliness q_{f0} (x default)');

    % Right: gap curves from straightest to wobbliest (baseline at its best value)
    picks = [1 pubIdx 8 10];   % straightest, published default, wobblier, extreme
    names = {'straightest', 'published default', 'wobblier', 'extreme'};
    for p = 1:4
        ax = nexttile(tl);
        hold(ax, 'on');
        j = picks(p);
        c = cells(bestIdx(1), j);
        fill(ax, [c.ages; flipud(c.ages)], [c.gapLow; flipud(c.gapHigh)], [0.6 0.7 0.9], ...
            'FaceAlpha', 0.35, 'EdgeColor', 'none');
        plot(ax, c.ages, c.gap, 'k', 'LineWidth', 1.8);
        yline(ax, 0, '--', 'Color', [0.4 0.4 0.4]);
        grid(ax, 'on');  box(ax, 'off');
        title(ax, {sprintf('%s: q_\\delta = default x %g', names{p}, m(j)), ...
            sprintf('\\Delta log-lik %.1f', dLogLik(bestIdx(1), j))});
        xlabel(ax, 'Age (years)');  ylabel(ax, 'CP - Control (dB)');
    end
end
