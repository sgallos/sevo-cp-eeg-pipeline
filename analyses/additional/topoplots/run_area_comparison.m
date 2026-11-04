function outFile = run_area_comparison()
%RUN_AREA_COMPARISON CP vs Control in six scalp areas, beside F3 from stage 01.
%   Each dot is one child. The first column of each row is F3 from the primary analysis,
%   so the areas can be checked against it. P-values are rank-sum tests, Holm-corrected
%   over the areas and bands. See README.md.
    minElectrodes = 2;
    cfg = mfdb_config();
    rng(cfg.randomSeed);                         % the dots' sideways jitter
    edges = state_space_bands();
    areas = scalp_areas();
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');

    cohort = get_cohort();
    A = area_band_power(load_channel_band_power(cohort), minElectrodes);
    F3 = primary_f3_power(cohort, edges, cfg);

    labels = ["F3 (primary)", string({areas.name})];
    colours = struct('CP', [0.80 0.25 0.20], 'Control', [0.20 0.40 0.70]);
    nBands = numel(edges);
    fig = figure('Color', 'w', 'Position', [50 50 1250 300 * nBands], 'Visible', 'off');
    tl = tiledlayout(fig, nBands, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
    results = table();
    for b = 1:nBands
        name = char(edges(b).name);
        ax = nexttile(tl);  hold(ax, 'on');
        for k = 1:numel(labels)
            if k == 1, here = F3; else, here = A(A.area == labels(k), :); end
            cp = here.(name)(here.groupLabel == "CP");
            control = here.(name)(here.groupLabel == "Control");
            draw_group(ax, k - 0.17, cp, colours.CP);
            draw_group(ax, k + 0.17, control, colours.Control);
            row = table(string(name), labels(k), numel(cp), numel(control), mean(cp) - mean(control), ...
                median(cp) - median(control), ranksum(cp, control), ...
                'VariableNames', {'band', 'area', 'nCP', 'nControl', 'meanDifference', 'medianDifference', 'p'});
            results = [results; row]; %#ok<AGROW>
        end
        xline(ax, 1.5, ':', 'Color', [0.6 0.6 0.6]);
        xticks(ax, 1:numel(labels));  xticklabels(ax, labels);  xlim(ax, [0.4 numel(labels) + 0.6]);
        ylabel(ax, 'dB re 1 \muV^2/Hz');
        title(ax, sprintf('%s%s, %g-%g Hz', upper(name(1)), name(2:end), edges(b).lowHz, edges(b).highHz));
        box(ax, 'off');
        for k = 1:numel(labels)
            row = results(results.band == string(name) & results.area == labels(k), :);
            text(ax, k, ax.YLim(2), sprintf('%+.1f dB', row.meanDifference), 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'top', 'FontSize', 10);
        end
        if b == 1
            legend(ax, [plot(ax, nan, nan, 'o', 'MarkerFaceColor', colours.CP, 'MarkerEdgeColor', 'none'), ...
                plot(ax, nan, nan, 'o', 'MarkerFaceColor', colours.Control, 'MarkerEdgeColor', 'none')], ...
                {'CP', 'Control'}, 'Location', 'southeast', 'Box', 'off');
        end
    end
    isArea = results.area ~= labels(1);
    results.pHolm = nan(height(results), 1);
    results.pHolm(isArea) = holm(results.p(isArea));
    outFile = fullfile(outDir, 'area_comparison.csv');
    writetable(results, outFile);
    exportgraphics(fig, fullfile(outDir, 'area_comparison.png'), 'Resolution', 200);
    close(fig);
end

function draw_group(ax, x, values, colour)
    scatter(ax, x + 0.09 * (rand(size(values)) - 0.5), values, 22, colour, 'filled', 'MarkerFaceAlpha', 0.55);
    plot(ax, x + [-0.12 0.12], [1 1] * median(values), 'Color', colour, 'LineWidth', 2.5);
end

function F3 = primary_f3_power(cohort, edges, cfg)
    F3 = table(string(cohort.subjectID), string(cohort.groupLabel), 'VariableNames', {'subjectID', 'groupLabel'});
    for b = 1:numel(edges), F3.(char(edges(b).name)) = nan(height(F3), 1); end
    for s = 1:height(F3)
        d = dir(fullfile(cfg.outputDir, char(F3.subjectID(s)), '*_mfdb.mat'));
        R = load(fullfile(d(1).folder, d(1).name), 'freq', 'S_subject_original_dB');
        for b = 1:numel(edges)
            inBand = R.freq >= edges(b).lowHz & R.freq <= edges(b).highHz;
            F3.(char(edges(b).name))(s) = mean(R.S_subject_original_dB(inBand));
        end
    end
end

function adjusted = holm(p)
    [sorted, order] = sort(p);
    steps = cummax(min(1, sorted .* (numel(p):-1:1)'));
    adjusted = nan(size(p));
    adjusted(order) = steps;
end
