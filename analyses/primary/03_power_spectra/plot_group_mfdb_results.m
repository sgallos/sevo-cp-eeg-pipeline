function figs = plot_group_mfdb_results(groupOutDir)
%PLOT_GROUP_MFDB_RESULTS Plot group-level MFDB results from run_group_mfdb_bootstrap.m.
%   figs = PLOT_GROUP_MFDB_RESULTS() reads and writes outputs/mfdb_group_level.
%   figs = PLOT_GROUP_MFDB_RESULTS(groupOutDir) uses another folder.
%   Returns the four figure handles (fig1..fig4) and the folder (outDir).

%% Step 1: Setup
if nargin < 1 || isempty(groupOutDir)
    cfg = mfdb_config();
    groupOutDir = fullfile(cfg.scriptRoot, 'outputs', 'mfdb_group_level');
end
groupResultsFile = fullfile(groupOutDir, 'group_mfdb_bootstrap_results.mat');

if ~isfile(groupResultsFile)
    error('Group results file not found: %s', groupResultsFile);
end

fprintf('Loading group MFDB results from %s\n', groupResultsFile);

%% Step 2: Load saved group-level outputs
S = load(groupResultsFile);

freq = S.freq(:);
cpSubjectIDs = string(S.cpSubjectIDs(:));
controlSubjectIDs = string(S.controlSubjectIDs(:));
groupMedian_CP_original_dB = S.groupMedian_CP_original_dB(:);
groupMedian_Control_original_dB = S.groupMedian_Control_original_dB(:);
groupMedian_CP_CI_low_dB = S.groupMedian_CP_CI_low_dB(:);
groupMedian_CP_CI_high_dB = S.groupMedian_CP_CI_high_dB(:);
groupMedian_Control_CI_low_dB = S.groupMedian_Control_CI_low_dB(:);
groupMedian_Control_CI_high_dB = S.groupMedian_Control_CI_high_dB(:);
groupDiff_original_dB = S.groupDiff_original_dB(:);
groupDiff_boot_median_dB = S.groupDiff_boot_median_dB(:);
groupDiff_boot_CI_low_dB = S.groupDiff_boot_CI_low_dB(:);
groupDiff_boot_CI_high_dB = S.groupDiff_boot_CI_high_dB(:);
sigMask = S.sigMask(:);
metadata = S.metadata;
sigMaskMin1Hz = contiguous_width_mask(freq, sigMask, 1.0);

fprintf('CP subjects: %d\n', numel(cpSubjectIDs));
fprintf('Control subjects: %d\n', numel(controlSubjectIDs));
fprintf('Frequency bins: %d\n', numel(freq));
fprintf('Pointwise significant bins: %d\n', sum(sigMask));
fprintf('Significant bins after >= 1 Hz contiguous filter: %d\n', sum(sigMaskMin1Hz));

%% Step 3: Plot original group spectra
fig1 = figure('Color', 'w', 'Position', [100 100 1050 520]);
ax1 = axes(fig1);
hold(ax1, 'on');

gc = group_colors();   % shared/group_colors.m: Control blue, CP red
controlLineColor = gc.controlLine;
controlFillColor = gc.controlFill;
cpLineColor = gc.cpLine;
cpFillColor = gc.cpFill;

hCPCI = fill(ax1, [freq; flipud(freq)], ...
    [groupMedian_CP_CI_low_dB; flipud(groupMedian_CP_CI_high_dB)], ...
    cpFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.35);
hControlCI = fill(ax1, [freq; flipud(freq)], ...
    [groupMedian_Control_CI_low_dB; flipud(groupMedian_Control_CI_high_dB)], ...
    controlFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.35);
hCP = plot(ax1, freq, groupMedian_CP_original_dB, 'LineWidth', 1, 'Color', cpLineColor);
hControl = plot(ax1, freq, groupMedian_Control_original_dB, 'LineWidth', 1, 'Color', controlLineColor);

style_axes(ax1, metadata.fpass);
xlabel(ax1, 'Frequency (Hz)');
ylabel(ax1, 'Median MFDB Power (dB)');
title(ax1, sprintf('Group Median MFDB Spectra with 95%% CI at %s', upper(char(metadata.electrodeLabel))), ...
    'FontSize', 14, 'FontWeight', 'bold');
method_note(ax1, sprintf('95%% CI: group MFDB bootstrap (each draw takes one bootstrap spectrum per child and recomputes the medians).'));
legend(ax1, [hCPCI, hCP, hControlCI, hControl], ...
    {'CP 95% confidence interval', 'CP median', ...
     'Control 95% confidence interval', 'Control median'}, ...
    'Location', 'best');

%% Step 4: Plot group difference with 95% CI
fig2 = figure('Color', 'w', 'Position', [100 100 1050 520]);
ax2 = axes(fig2);
hold(ax2, 'on');

hCI = fill(ax2, [freq; flipud(freq)], ...
    [groupDiff_boot_CI_low_dB; flipud(groupDiff_boot_CI_high_dB)], ...
    [0.70 0.70 0.70], 'EdgeColor', 'none', 'FaceAlpha', 0.45);
hDiff = plot(ax2, freq, groupDiff_boot_median_dB, 'k-', 'LineWidth', 2);
hZero = yline(ax2, 0, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);

style_axes(ax2, metadata.fpass);
xlabel(ax2, 'Frequency (Hz)');
ylabel(ax2, 'CP - Control (dB)');
title(ax2, sprintf('Group MFDB Difference with 95%% CI at %s', upper(char(metadata.electrodeLabel))), ...
    'FontSize', 14, 'FontWeight', 'bold');
method_note(ax2, sprintf('95%% CI: group MFDB bootstrap (each draw takes one bootstrap spectrum per child and recomputes the medians).'));
legend(ax2, [hCI, hDiff, hZero], ...
    {'95% confidence interval', 'Bootstrap median difference', 'Zero line'}, ...
    'Location', 'best');

%% Step 5: Plot significance mask
fig3 = figure('Color', 'w', 'Position', [100 100 1050 260]);
ax3 = axes(fig3);
hold(ax3, 'on');

sigFreq = freq(sigMask);
if ~isempty(sigFreq)
    hSig = stem(ax3, sigFreq, ones(size(sigFreq)), 'filled', ...
        'Color', [0.75 0.1 0.1], 'MarkerFaceColor', [0.75 0.1 0.1], ...
        'LineWidth', 1.2);
else
    text(ax3, mean(metadata.fpass), 0.5, 'No pointwise significant bins', ...
        'HorizontalAlignment', 'center', 'FontSize', 12);
end

style_axes(ax3, metadata.fpass);
ax3.YLim = [0 1.2];
ax3.YTick = [0 1];
ax3.YTickLabel = {'No', 'Yes'};
xlabel(ax3, 'Frequency (Hz)');
ylabel(ax3, 'Significant');
title(ax3, 'Pointwise Significance Mask (95% CI Excludes Zero)', ...
    'FontSize', 14, 'FontWeight', 'bold');
method_note(ax3, 'Test: group MFDB bootstrap. A frequency is significant when the 95% CI of CP - Control excludes 0.');
if ~isempty(sigFreq)
    legend(ax3, hSig, {'Pointwise significant bins'}, 'Location', 'best');
end

%% Step 6: Plot combined difference + significance strip
fig4 = figure('Color', 'w', 'Position', [100 100 1050 620]);
tlo = tiledlayout(fig4, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

ax4a = nexttile(tlo, 1);
hold(ax4a, 'on');
hCI2 = fill(ax4a, [freq; flipud(freq)], ...
    [groupDiff_boot_CI_low_dB; flipud(groupDiff_boot_CI_high_dB)], ...
    [0.70 0.70 0.70], 'EdgeColor', 'none', 'FaceAlpha', 0.45);
hDiff2 = plot(ax4a, freq, groupDiff_boot_median_dB, 'k-', 'LineWidth', 2);
hZero2 = yline(ax4a, 0, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
style_axes(ax4a, metadata.fpass);
ylabel(ax4a, 'CP - Control (dB)');
title(ax4a, sprintf('Group MFDB Difference and Significance at %s', upper(char(metadata.electrodeLabel))), ...
    'FontSize', 14, 'FontWeight', 'bold');
method_note(ax4a, ['Test: group MFDB bootstrap. Bottom row: frequencies where the 95% CI of CP - Control ' ...
    'excludes 0, kept only in runs at least 1 Hz wide.']);
legend(ax4a, [hCI2, hDiff2, hZero2], ...
    {'95% confidence interval', 'Bootstrap median difference', 'Zero line'}, ...
    'Location', 'best');

ax4b = nexttile(tlo, 2);
hold(ax4b, 'on');
if any(sigMaskMin1Hz)
    hSig2 = scatter(ax4b, freq(sigMaskMin1Hz), ones(sum(sigMaskMin1Hz), 1), 18, ...
        'MarkerFaceColor', [0.75 0.1 0.1], 'MarkerEdgeColor', 'none');
else
    text(ax4b, mean(metadata.fpass), 1, 'No >= 1 Hz significant segments', ...
        'HorizontalAlignment', 'center', 'FontSize', 12);
end
style_axes(ax4b, metadata.fpass);
ax4b.YLim = [0.5 1.5];
ax4b.YTick = 1;
ax4b.YTickLabel = {'>= 1 Hz'};
xlabel(ax4b, 'Frequency (Hz)');
ylabel(ax4b, '');
if any(sigMaskMin1Hz)
    legend(ax4b, hSig2, {'Significant bins in >= 1 Hz continuous segments'}, 'Location', 'best');
end

%% Step 7: Save figures
drawnow;
save_figure_if_valid(fig1, fullfile(groupOutDir, '01_group_median_mfdb_spectra.png'));
save_figure_if_valid(fig2, fullfile(groupOutDir, '02_group_mfdb_difference_with_ci.png'));
save_figure_if_valid(fig3, fullfile(groupOutDir, '03_group_mfdb_significance_mask.png'));
save_figure_if_valid(fig4, fullfile(groupOutDir, '04_group_mfdb_difference_and_significance.png'));

fprintf('Saved plots to %s\n', groupOutDir);

figs = struct('fig1', fig1, 'fig2', fig2, 'fig3', fig3, 'fig4', fig4, 'outDir', groupOutDir);
end

%% Local functions
function style_axes(ax, fpass)
    ax.FontName = 'Helvetica';
    ax.FontSize = 12;
    ax.LineWidth = 1;
    ax.TickDir = 'out';
    ax.Box = 'off';
    ax.XLim = [fpass(1) fpass(2)];
    grid(ax, 'on');
end

function save_figure_if_valid(figHandle, outFile)
    if ~isgraphics(figHandle, 'figure')
        warning('plot_group_mfdb_results:InvalidFigureHandle', ...
            'Skipping save because figure handle is invalid: %s', outFile);
        return;
    end

    try
        exportgraphics(figHandle, outFile, 'Resolution', 200);
    catch ME
        warning('plot_group_mfdb_results:ExportGraphicsFailed', ...
            'exportgraphics failed for %s: %s', outFile, ME.message);
        if isgraphics(figHandle, 'figure')
            try
                saveas(figHandle, outFile);
            catch ME2
                warning('plot_group_mfdb_results:SaveAsFailed', ...
                    'saveas failed for %s: %s', outFile, ME2.message);
            end
        else
            warning('plot_group_mfdb_results:InvalidFigureAfterExportFailure', ...
                'Skipping saveas because figure handle became invalid: %s', outFile);
        end
    end
end

function filteredMask = contiguous_width_mask(freq, mask, minWidthHz)
    freq = freq(:);
    mask = logical(mask(:));
    filteredMask = false(size(mask));

    if isempty(freq) || isempty(mask) || numel(freq) ~= numel(mask) || ~any(mask)
        return;
    end

    if numel(freq) > 1
        df = median(diff(freq));
    else
        df = minWidthHz;
    end

    dMask = diff([false; mask; false]);
    runStarts = find(dMask == 1);
    runEnds = find(dMask == -1) - 1;

    for i = 1:numel(runStarts)
        runIdx = runStarts(i):runEnds(i);
        runWidthHz = freq(runIdx(end)) - freq(runIdx(1)) + df;
        if runWidthHz >= minWidthHz
            filteredMask(runIdx) = true;
        end
    end
end

function method_note(ax, txt)
%METHOD_NOTE Small grey line under the title naming the statistical method.
    subtitle(ax, txt, 'FontSize', 9, 'Color', [0.35 0.35 0.35]);
end
