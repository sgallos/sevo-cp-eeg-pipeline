function figs = plot_group_f3f4_coherence_results(groupOutDir)
%PLOT_GROUP_F3F4_COHERENCE_RESULTS Plot group F3-F4 coherence results including Bokil/Chronux significance masks.
%   Optional groupOutDir (default: outputs/coherence_group_level). Returns figure handles.

%% Step 1: Setup
if nargin < 1 || isempty(groupOutDir)
    paths = project_paths();
    groupOutDir = fullfile(paths.outputsDir, 'coherence_group_level');
end
resultsFile = fullfile(groupOutDir, 'group_f3f4_coherence_results.mat');

if ~isfile(resultsFile)
    error('Group coherence results not found: %s', resultsFile);
end

fprintf('Loading group coherence results from %s\n', resultsFile);

%% Step 2: Load saved outputs
S = load(resultsFile);

subjectTable = S.subjectTable;
freq = S.freq(:);
controlSpectra = S.controlSpectra;
cpSpectra = S.cpSpectra;
controlMedian = S.controlMedian(:);
cpMedian = S.cpMedian(:);
controlIQR = S.controlIQR;
cpIQR = S.cpIQR;
alphaComparison = S.alphaComparison;
inference = S.inference;
metadataRef = S.metadataRef;

fprintf('Controls: %d\n', size(controlSpectra, 1));
fprintf('CP subjects: %d\n', size(cpSpectra, 1));
fprintf('Frequency bins: %d\n', numel(freq));
fprintf('Primary contiguous significant bins: %d\n', sum(inference.sigMask_contiguous));

%% Step 3: Plot descriptive group median coherence curves
gc = group_colors();   % shared/group_colors.m: Control blue, CP red
ctrlLineColor = gc.controlLine;
cpLineColor = gc.cpLine;
ctrlFillColor = gc.controlLight;
cpFillColor = gc.cpLight;
ctrlSubjectColor = [gc.controlLine 0.18];
cpSubjectColor = [gc.cpLine 0.18];
alphaBandColor = [0.90 0.90 0.90];
primarySigColor = [0.80 0.20 0.20];
exploratorySigColor = [0.95 0.72 0.45];

fig1 = figure('Color', 'w', 'Position', [100 100 1120 560]);
ax1 = axes(fig1);
hold(ax1, 'on');

patch(ax1, [metadataRef.alphaBand(1) metadataRef.alphaBand(2) metadataRef.alphaBand(2) metadataRef.alphaBand(1)], ...
    [0 0 1 1], alphaBandColor, 'EdgeColor', 'none', 'FaceAlpha', 0.35, 'HandleVisibility', 'off');

for i = 1:size(controlSpectra, 1)
    plot(ax1, freq, controlSpectra(i, :), '-', 'Color', ctrlSubjectColor, 'LineWidth', 0.8, 'HandleVisibility', 'off');
end
for i = 1:size(cpSpectra, 1)
    plot(ax1, freq, cpSpectra(i, :), '-', 'Color', cpSubjectColor, 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

hCtrlIQR = fill(ax1, [freq; flipud(freq)], [controlIQR(1, :).'; flipud(controlIQR(2, :).')], ...
    ctrlFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.28);
hCpIQR = fill(ax1, [freq; flipud(freq)], [cpIQR(1, :).'; flipud(cpIQR(2, :).')], ...
    cpFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.28);
hCtrl = plot(ax1, freq, controlMedian, '-', 'Color', ctrlLineColor, 'LineWidth', 2.8);
hCp = plot(ax1, freq, cpMedian, '-', 'Color', cpLineColor, 'LineWidth', 2.8);

style_axes(ax1, metadataRef.fpass, [0 1]);
xlabel(ax1, 'Frequency (Hz)');
ylabel(ax1, 'Median F3-F4 coherence');
title(ax1, 'Group Median F3-F4 Coherence Curves', 'FontSize', 14, 'FontWeight', 'bold');
legend(ax1, [hCtrl, hCp, hCtrlIQR, hCpIQR], ...
    {'Control median', 'CP median', 'Control IQR', 'CP IQR'}, 'Location', 'best');

annotationText = sprintf(['Subject-level coherence computed from 2 s non-overlapping windows\n' ...
    'tapers = [%g %g], fpass = [%.1f %.1f] Hz, Fs = %.1f Hz\n' ...
    'Bokil/Chronux two-group test: primary p < %.3g, contiguous width >= %.1f Hz (%d bins)\n' ...
    'Wilcoxon rank-sum test, alpha coherence: p = %.4f'], ...
    metadataRef.tapers(1), metadataRef.tapers(2), metadataRef.fpass(1), metadataRef.fpass(2), metadataRef.Fs, ...
    inference.primaryP, inference.contiguousWidthHz, inference.minContiguousBins, alphaComparison.ranksumP);
text(ax1, 0.02, 0.98, annotationText, 'Units', 'normalized', ...
    'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'FontName', 'Helvetica', 'FontSize', 9, 'BackgroundColor', [1 1 1]);

%% Step 4: Fig 9, one panel: group curves with the Bokil test result as bars along the top
fig2 = figure('Color', 'w', 'Position', [100 100 1300 620]);
ax2 = axes(fig2);
hold(ax2, 'on');
nControl = size(controlSpectra, 1);
nCP = size(cpSpectra, 1);
hAlpha = patch(ax2, [metadataRef.alphaBand(1) metadataRef.alphaBand(2) metadataRef.alphaBand(2) metadataRef.alphaBand(1)], ...
    [0 0 1 1], alphaBandColor, 'EdgeColor', 'none', 'FaceAlpha', 0.35);
for i = 1:nControl
    hCtrlChild = plot(ax2, freq, controlSpectra(i, :), '-', 'Color', ctrlSubjectColor, 'LineWidth', 0.8);
end
for i = 1:nCP
    hCpChild = plot(ax2, freq, cpSpectra(i, :), '-', 'Color', cpSubjectColor, 'LineWidth', 0.8);
end
hCtrlIQR2 = fill(ax2, [freq; flipud(freq)], [controlIQR(1, :).'; flipud(controlIQR(2, :).')], ...
    ctrlFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.28);
hCpIQR2 = fill(ax2, [freq; flipud(freq)], [cpIQR(1, :).'; flipud(cpIQR(2, :).')], ...
    cpFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.28);
hCtrl2 = plot(ax2, freq, controlMedian, '-', 'Color', ctrlLineColor, 'LineWidth', 2.8);
hCp2 = plot(ax2, freq, cpMedian, '-', 'Color', cpLineColor, 'LineWidth', 2.8);

% Significance bars above the curves: primary (top row) and exploratory (row below)
hPrimary = draw_sig_bars(ax2, freq, inference.sigMask_contiguous(:), [1.075 1.105], primarySigColor);
hExploratory = draw_sig_bars(ax2, freq, inference.sigMask_contiguous_exploratory(:), [1.035 1.065], exploratorySigColor);

style_axes(ax2, metadataRef.fpass, [0 1.12]);
ax2.YTick = 0:0.1:1;
xlabel(ax2, 'Frequency (Hz)');
ylabel(ax2, 'F3-F4 coherence');
title(ax2, sprintf('F3-F4 coherence, Control (n = %d) vs CP (n = %d)', nControl, nCP), 'FontSize', 14, 'FontWeight', 'bold');
subtitle(ax2, 'Bars at top: frequencies where the Bokil two-group coherence test (Chronux, jackknife variance) finds CP \neq Control', ...
    'FontSize', 10);
legend(ax2, [hCtrl2, hCp2, hCtrlIQR2, hCpIQR2, hCtrlChild, hCpChild, hAlpha, hPrimary, hExploratory], ...
    {'Control median', 'CP median', 'Control IQR (25th-75th percentile)', 'CP IQR (25th-75th percentile)', ...
     'Each Control child', 'Each CP child', ...
     sprintf('Alpha band (%g-%g Hz)', metadataRef.alphaBand(1), metadataRef.alphaBand(2)), ...
     sprintf('Bokil test p < %.3g, runs \\geq %.0f Hz (primary)', inference.primaryP, inference.contiguousWidthHz), ...
     sprintf('Bokil test p < %.3g, runs \\geq %.0f Hz (exploratory)', inference.exploratoryP, inference.contiguousWidthHz)}, ...
    'Location', 'eastoutside', 'FontSize', 10);

%% Step 5: Plot scalar alpha-coherence comparison
fig3 = figure('Color', 'w', 'Position', [100 100 900 520]);
ax3 = axes(fig3);
hold(ax3, 'on');

controlVals = alphaComparison.controlValues(:);
cpVals = alphaComparison.cpValues(:);
controlX = ones(size(controlVals));
cpX = 2 * ones(size(cpVals));
controlJitter = controlX + 0.06 * randn(size(controlVals));
cpJitter = cpX + 0.06 * randn(size(cpVals));

scatter(ax3, controlJitter, controlVals, 70, 'MarkerFaceColor', ctrlLineColor, 'MarkerEdgeColor', 'k', 'LineWidth', 0.75);
scatter(ax3, cpJitter, cpVals, 70, 'MarkerFaceColor', cpLineColor, 'MarkerEdgeColor', 'k', 'LineWidth', 0.75);
plot(ax3, [0.8 1.2], [median(controlVals,'omitnan') median(controlVals,'omitnan')], '-', 'Color', ctrlLineColor, 'LineWidth', 3);
plot(ax3, [1.8 2.2], [median(cpVals,'omitnan') median(cpVals,'omitnan')], '-', 'Color', cpLineColor, 'LineWidth', 3);

ax3.XLim = [0.5 2.5];
ax3.XTick = [1 2];
ax3.XTickLabel = {'Control', 'CP'};
style_axes(ax3, [0.5 2.5], []);
ylabel(ax3, 'Mean alpha coherence (8-13 Hz)');
title(ax3, sprintf('Alpha coherence (%g-%g Hz), one value per child', metadataRef.alphaBand(1), metadataRef.alphaBand(2)), 'FontSize', 14, 'FontWeight', 'bold');
text(ax3, 0.02, 0.98, sprintf('Wilcoxon rank-sum test p = %.4f\nTwo-sample t-test (pooled variance) p = %.4f', alphaComparison.ranksumP, alphaComparison.ttestP), ...
    'Units', 'normalized', 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top', ...
    'FontName', 'Helvetica', 'FontSize', 10, 'BackgroundColor', [1 1 1]);

%% Step 6: Save figures
saveas(fig1, fullfile(groupOutDir, '01_group_f3f4_coherence_curves.png'));
saveas(fig2, fullfile(groupOutDir, '02_group_f3f4_coherence_combined.png'));
saveas(fig3, fullfile(groupOutDir, '03_alpha_coherence_scalar_comparison.png'));

fprintf('Saved coherence plots to %s\n', groupOutDir);

figs = struct('fig1', fig1, 'fig2', fig2, 'fig3', fig3, 'outDir', groupOutDir);
end

%% Local functions
function style_axes(ax, xLimits, yLimits)
    ax.FontName = 'Helvetica';
    ax.FontSize = 12;
    ax.LineWidth = 1;
    ax.TickDir = 'out';
    ax.Box = 'off';
    ax.XLim = xLimits;
    if ~isempty(yLimits)
        ax.YLim = yLimits;
    end
    grid(ax, 'off');
end

function intervals = mask_to_intervals(xVals, mask)
    intervals = zeros(0, 2);
    if isempty(xVals) || isempty(mask) || ~any(mask)
        return;
    end

    xVals = xVals(:);
    mask = logical(mask(:));
    dMask = diff([false; mask; false]);
    startIdx = find(dMask == 1);
    endIdx = find(dMask == -1) - 1;

    for i = 1:numel(startIdx)
        intervals(end + 1, :) = [xVals(startIdx(i)), xVals(endIdx(i))]; %#ok<AGROW>
    end
end

function h = draw_sig_bars(ax, freq, mask, yRange, color)
%DRAW_SIG_BARS One horizontal bar per run of significant frequencies; returns a legend handle.
    h = patch(ax, nan(4, 1), nan(4, 1), color, 'EdgeColor', 'none');
    if ~any(mask), return; end
    intervals = mask_to_intervals(freq, mask);
    for k = 1:size(intervals, 1)
        patch(ax, [intervals(k, 1) intervals(k, 2) intervals(k, 2) intervals(k, 1)], ...
            [yRange(1) yRange(1) yRange(2) yRange(2)], color, 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
end
