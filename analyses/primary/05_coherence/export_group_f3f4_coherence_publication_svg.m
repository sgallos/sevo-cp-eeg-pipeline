function outputFile = export_group_f3f4_coherence_publication_svg(varargin)
%EXPORT_GROUP_F3F4_COHERENCE_PUBLICATION_SVG Export edited coherence SVG.
%
% Regenerates:
%   requested_svg_only/07_group_median_f3f4_coherence_curves.svg
%
% This publication version keeps all individual subject traces visible under
% the group median curves and IQR bands, using the same blue/red palette as
% the power figures.

settings = struct();
paths = project_paths();
settings.resultsFile = fullfile(paths.outputsDir, 'coherence_group_level', ...
    'group_f3f4_coherence_results.mat');
settings.publicationRoot = paths.figuresDir;
settings.outputFileName = '07_group_median_f3f4_coherence_curves.svg';
settings = apply_name_value_overrides(settings, varargin{:});

outDir = fullfile(settings.publicationRoot, 'requested_svg_only');
if ~exist(outDir, 'dir'), mkdir(outDir); end

S = load(settings.resultsFile);
freq = S.freq(:);
metadataRef = S.metadataRef;

gc = group_colors();   % shared/group_colors.m: Control blue, CP red
controlLineColor = gc.controlLine;
controlFillColor = gc.controlFill;
cpLineColor = gc.cpLine;
cpFillColor = gc.cpFill;

controlTraceColor = blend_with_white(controlLineColor, 0.70);
cpTraceColor = blend_with_white(cpLineColor, 0.70);

fig = figure('Color', 'w', 'Position', [100 100 1050 520]);
ax = axes(fig);
hold(ax, 'on');

for i = 1:size(S.controlSpectra, 1)
    plot(ax, freq, S.controlSpectra(i, :).', '-', ...
        'Color', controlTraceColor, 'LineWidth', 0.65, ...
        'HandleVisibility', 'off');
end
for i = 1:size(S.cpSpectra, 1)
    plot(ax, freq, S.cpSpectra(i, :).', '-', ...
        'Color', cpTraceColor, 'LineWidth', 0.65, ...
        'HandleVisibility', 'off');
end

hCpIQR = fill(ax, [freq; flipud(freq)], ...
    [S.cpIQR(1, :).'; flipud(S.cpIQR(2, :).')], ...
    cpFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.24);
hControlIQR = fill(ax, [freq; flipud(freq)], ...
    [S.controlIQR(1, :).'; flipud(S.controlIQR(2, :).')], ...
    controlFillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.24);
hCP = plot(ax, freq, S.cpMedian(:), '-', ...
    'Color', cpLineColor, 'LineWidth', 1.8);
hControl = plot(ax, freq, S.controlMedian(:), '-', ...
    'Color', controlLineColor, 'LineWidth', 1.8);

style_axes(ax, metadataRef.fpass, [0 1]);
xlabel(ax, 'Frequency (Hz)');
ylabel(ax, 'F3-F4 coherence');
title(ax, 'F3-F4 Coherence: Individual Subjects and Group Medians', ...
    'FontSize', 14, 'FontWeight', 'bold');
legend(ax, [hCpIQR, hCP, hControlIQR, hControl], ...
    {'CP IQR', 'CP median', 'Control IQR', 'Control median'}, ...
    'Location', 'best');

outputFile = fullfile(outDir, settings.outputFileName);
set(fig, 'Renderer', 'painters');
print(fig, outputFile, '-dsvg');
close(fig);

fprintf('Saved coherence publication SVG:\n  %s\n', outputFile);
end

function colorOut = blend_with_white(colorIn, whiteWeight)
colorOut = whiteWeight * [1 1 1] + (1 - whiteWeight) * colorIn;
end

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
grid(ax, 'on');
end

function settings = apply_name_value_overrides(settings, varargin)
if isempty(varargin)
    return;
end
if mod(numel(varargin), 2) ~= 0
    error('Overrides must be supplied as name-value pairs.');
end

validNames = string(fieldnames(settings));
for i = 1:2:numel(varargin)
    name = string(varargin{i});
    if ~any(validNames == name)
        error('Unknown export option: %s', name);
    end
    settings.(name) = varargin{i + 1};
end
end
