function out = run_subject_level_age_trajectories()
%RUN_SUBJECT_LEVEL_AGE_TRAJECTORIES Figs 3-4 with each child as the unit of analysis.
%   Same alpha power per child as stage 04 (8-13 Hz, from the stage 01 F3
%   spectrum), and the same age windows. Changes:
%   - CIs resample CHILDREN within each window, and are only drawn when a
%     window has at least minPerGroup children in that group;
%   - one regression over all children, alpha ~ group + age (+ group x age),
%     which uses everyone at once instead of slicing into small bins.
%   Writes to outputs/additional/subject_level_inference/age_trajectories/.

    minPerGroup = 3;          % fewer children than this: no CI, no test
    bandRange = [8 13];       % as in stage 04 (Figs 3-4)
    halfWidth = 2;            % Fig 3 sliding windows: half-width and step (years)
    step = 0.5;

    paths = project_paths();
    cfg = mfdb_config();
    criteria = cohort_criteria();
    cohort = get_cohort();
    outDir = fullfile(paths.outputsDir, 'additional', 'subject_level_inference', 'age_trajectories');
    if ~isfolder(outDir), mkdir(outDir); end

    % Alpha power per child, computed exactly as in stage 04
    n = height(cohort);
    alphaDB = zeros(n, 1);
    for i = 1:n
        id = char(cohort.subjectID(i));
        S = load(fullfile(cfg.outputDir, id, [id '_F3_mfdb.mat']), 'freq', 'S_subject_original_linear');
        mask = S.freq >= bandRange(1) & S.freq <= bandRange(2);
        alphaDB(i) = 10 * log10(max(trapz(S.freq(mask), S.S_subject_original_linear(mask)), eps));
    end
    children = table(cohort.subjectID, categorical(cohort.groupLabel, ["Control", "CP"]), ...
        cohort.ageYears, alphaDB, 'VariableNames', {'subjectID', 'group', 'ageYears', 'alpha_dB'});

    % Sliding windows (Fig 3): each group's mean with a children-resampled CI
    centers = (criteria.ageMinYears:step:criteria.ageMaxYears).';
    windows = table(centers, 'VariableNames', {'ageCenter'});
    for g = ["Control", "CP"]
        [m, lo, hi, k] = window_summary(children, g, centers, halfWidth, minPerGroup);
        windows.(g + "_n") = k;
        windows.(g + "_mean_dB") = m;
        windows.(g + "_ciLow_dB") = lo;
        windows.(g + "_ciHigh_dB") = hi;
    end

    % One-year bins (Fig 4): difference only where both groups have enough children
    binCenters = (criteria.ageMinYears + 0.5 : 1 : criteria.ageMaxYears - 0.5).';
    bins = table(binCenters, 'VariableNames', {'ageCenter'});
    for b = 1:numel(binCenters)
        inBin = abs(children.ageYears - binCenters(b)) <= 0.5;
        cp = children.alpha_dB(inBin & children.group == "CP");
        ctrl = children.alpha_dB(inBin & children.group == "Control");
        bins.nCP(b) = numel(cp);
        bins.nControl(b) = numel(ctrl);
        bins.difference_dB(b) = mean(cp) - mean(ctrl);
        bins.ciLow_dB(b) = NaN;
        bins.ciHigh_dB(b) = NaN;
        if numel(cp) >= minPerGroup && numel(ctrl) >= minPerGroup
            boot = subject_bootstrap_ci(cp, ctrl, struct('statFn', @mean));
            bins.ciLow_dB(b) = boot.ciDifference(1);
            bins.ciHigh_dB(b) = boot.ciDifference(2);
        end
    end

    % One model for all children
    mainModel = fitlm(children, 'alpha_dB ~ group + ageYears');
    interactionModel = fitlm(children, 'alpha_dB ~ group * ageYears');
    groupRow = mainModel.Coefficients('group_CP', :);
    groupCI = coefCI(mainModel);
    groupCI = groupCI(strcmp(mainModel.CoefficientNames, 'group_CP'), :);
    interactionP = interactionModel.Coefficients{'group_CP:ageYears', 'pValue'};

    summary = table(groupRow.Estimate, groupCI(1), groupCI(2), groupRow.pValue, ...
        mainModel.Coefficients{'ageYears', 'Estimate'}, mainModel.Coefficients{'ageYears', 'pValue'}, ...
        interactionP, mainModel.Rsquared.Ordinary, ...
        'VariableNames', {'groupEffect_dB', 'ciLow_dB', 'ciHigh_dB', 'pGroup', ...
        'ageSlope_dBperYear', 'pAge', 'pGroupByAge', 'R2'});

    writetable(children, fullfile(outDir, 'alpha_per_child.csv'));
    writetable(windows, fullfile(outDir, 'sliding_windows.csv'));
    writetable(bins, fullfile(outDir, 'one_year_bins.csv'));
    writetable(summary, fullfile(outDir, 'regression_summary.csv'));
    save(fullfile(outDir, 'subject_level_age_trajectories.mat'), 'children', 'windows', 'bins', ...
        'summary', 'mainModel', 'interactionModel', 'minPerGroup');

    fig = plot_results(children, windows, bins, mainModel, summary);
    exportgraphics(fig, fullfile(outDir, 'alpha_vs_age_subject_level.png'), 'Resolution', 200);

    fprintf('\nAlpha (8-13 Hz) vs age, children as the unit (n = %d)\n', n);
    disp(summary);
    disp(bins);
    out = struct('outDir', outDir, 'summary', summary, 'bins', bins, 'windows', windows, 'fig', fig);
end

function [m, lo, hi, k] = window_summary(children, groupName, centers, halfWidth, minN)
    nW = numel(centers);
    [m, lo, hi] = deal(nan(nW, 1));
    k = zeros(nW, 1);
    for w = 1:nW
        sel = children.group == groupName & abs(children.ageYears - centers(w)) <= halfWidth;
        vals = children.alpha_dB(sel);
        k(w) = numel(vals);
        if k(w) == 0, continue; end
        m(w) = mean(vals);
        if k(w) >= minN
            boot = subject_bootstrap_ci(vals, vals, struct('statFn', @mean));
            lo(w) = boot.ciA(1);
            hi(w) = boot.ciA(2);
        end
    end
end

function fig = plot_results(children, windows, bins, model, summary)
    ctrlColor = [0.90 0.45 0.10];
    cpColor = [0.20 0.45 0.85];
    fig = figure('Color', 'w', 'Position', [100 100 1100 820]);
    tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact');

    ax1 = nexttile(tl); hold(ax1, 'on');
    names = ["Control", "CP"];  colors = {ctrlColor, cpColor};
    for g = 1:2
        c = colors{g};
        ok = ~isnan(windows.(names(g) + "_ciLow_dB"));
        x = windows.ageCenter(ok).';
        fill(ax1, [x fliplr(x)], [windows.(names(g) + "_ciLow_dB")(ok).' fliplr(windows.(names(g) + "_ciHigh_dB")(ok).')], ...
            c, 'FaceAlpha', 0.18, 'EdgeColor', 'none', 'HandleVisibility', 'off');
        plot(ax1, windows.ageCenter, windows.(names(g) + "_mean_dB"), '-', 'Color', c, 'LineWidth', 2, ...
            'DisplayName', names(g) + " mean (4-yr sliding window, 95% CI resampling children)");
        sel = children.group == names(g);
        scatter(ax1, children.ageYears(sel), children.alpha_dB(sel), 36, c, 'filled', ...
            'MarkerEdgeColor', 'k', 'DisplayName', names(g) + " children");
    end
    grid(ax1, 'on'); box(ax1, 'off');
    ylabel(ax1, 'Alpha power at F3 (dB)');
    title(ax1, sprintf('Alpha power vs age. CP - Control = %.1f dB [%.1f, %.1f], p = %.3g (age-adjusted, n = %d)', ...
        summary.groupEffect_dB, summary.ciLow_dB, summary.ciHigh_dB, summary.pGroup, model.NumObservations));
    legend(ax1, 'Location', 'northeast');

    ax2 = nexttile(tl); hold(ax2, 'on');
    yline(ax2, 0, '--', 'Color', [0.4 0.4 0.4], 'HandleVisibility', 'off');
    yline(ax2, summary.groupEffect_dB, '-', 'Color', [0.3 0.3 0.3], 'LineWidth', 1, ...
        'DisplayName', 'Age-adjusted group difference (all children)');
    hasCI = ~isnan(bins.ciLow_dB);
    errorbar(ax2, bins.ageCenter(hasCI), bins.difference_dB(hasCI), ...
        bins.difference_dB(hasCI) - bins.ciLow_dB(hasCI), bins.ciHigh_dB(hasCI) - bins.difference_dB(hasCI), ...
        'o', 'Color', 'k', 'MarkerFaceColor', 'k', 'LineWidth', 1.2, 'DisplayName', 'Bin difference, 95% CI (children resampled)');
    plot(ax2, bins.ageCenter(~hasCI), bins.difference_dB(~hasCI), 'o', 'Color', [0.5 0.5 0.5], ...
        'DisplayName', 'Bin difference, too few children for a CI');
    for b = 1:height(bins)
        text(ax2, bins.ageCenter(b), bins.difference_dB(b), sprintf('  %d vs %d', bins.nCP(b), bins.nControl(b)), ...
            'FontSize', 9, 'Color', [0.35 0.35 0.35]);
    end
    grid(ax2, 'on'); box(ax2, 'off');
    xlabel(ax2, 'Age (years)'); ylabel(ax2, 'CP - Control alpha (dB)');
    title(ax2, sprintf('One-year bins (labels: n CP vs n Control). Group x age interaction p = %.2f', summary.pGroupByAge));
    legend(ax2, 'Location', 'southoutside', 'NumColumns', 2);
    linkaxes([ax1 ax2], 'x');
end
