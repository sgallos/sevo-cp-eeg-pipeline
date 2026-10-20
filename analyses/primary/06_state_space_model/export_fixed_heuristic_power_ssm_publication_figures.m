function outputFiles = export_fixed_heuristic_power_ssm_publication_figures(varargin)
%EXPORT_FIXED_HEURISTIC_POWER_SSM_PUBLICATION_FIGURES Export publication SSM figures.
%
% Regenerates requested SVG-only figures 05 and 06 for delta, theta, and
% alpha from the saved scalar-r SSM FixedHeuristicQ fits. Also refreshes the
% matching PNG files in the publication-ready power_ssm_24_subjects folder.
%
% Outputs:
%   requested_svg_only/05_power_ssm_fixed_heuristic_<band>_group_difference.svg
%   requested_svg_only/06_power_ssm_fixed_heuristic_<band>_control_vs_cp.svg
%   power_ssm_24_subjects/figures/power_ssm_24_subjects_fixed_heuristic_<band>_*.png

settings = struct();
paths = project_paths();
settings.publicationRoot = paths.figuresDir;
settings.resultsDir = state_space_outputs_dir();
settings.versionName = "FixedHeuristicQ";
settings.bands = ["delta", "theta", "alpha"];
settings.writePng = true;
settings.writeSvg = true;
% Default: the fits run_all.m makes (outputPrefix "power_ssm_publication"),
% the same files regenerate_publication_figures.m used for Figures 05-06.
settings.allVersionsFilePattern = 'power_ssm_publication_%s_all_versions.mat';
settings.pngPrefix = "power_ssm_24_subjects";
settings.exportDifference = true;   % Figure 05
settings.exportControlCp = true;    % Figure 06
settings = apply_name_value_overrides(settings, varargin{:});

svgOutDir = fullfile(settings.publicationRoot, 'requested_svg_only');
pngOutDir = fullfile(settings.publicationRoot, 'power_ssm_24_subjects', 'figures');
if settings.writeSvg && ~exist(svgOutDir, 'dir'), mkdir(svgOutDir); end
if settings.writePng && ~exist(pngOutDir, 'dir'), mkdir(pngOutDir); end

outputFiles = strings(0, 1);

for b = 1:numel(settings.bands)
    bandName = string(settings.bands(b));
    matFile = resolve_all_versions_file(settings, bandName);
    S = load(matFile, 'versionResults');
    result = get_version_result(S.versionResults, settings.versionName, matFile);
    traj = sortrows(result.trajectory, 'ageYears');

    if settings.exportDifference
        outputFiles = [outputFiles; export_difference_figure(result, traj, bandName, svgOutDir, pngOutDir, settings)]; %#ok<AGROW>
    end
    if settings.exportControlCp
        outputFiles = [outputFiles; export_control_cp_figure(result, traj, bandName, svgOutDir, pngOutDir, settings)]; %#ok<AGROW>
    end
end

fprintf('Exported FixedHeuristicQ publication figures:\n');
fprintf('  %s\n', outputFiles);
end

function matFile = resolve_all_versions_file(settings, bandName)
fileName = sprintf(settings.allVersionsFilePattern, bandName);
candidate = fullfile(settings.resultsDir, 'mat', fileName);
if isfile(candidate)
    matFile = candidate;
    return;
end

candidate = fullfile(settings.resultsDir, fileName);
if isfile(candidate)
    matFile = candidate;
    return;
end

error('Could not find all-versions MAT file for %s in %s. Run stage 06 first.', bandName, settings.resultsDir);
end

function result = get_version_result(versionResults, versionName, matFile)
idx = find([versionResults.versionName] == string(versionName), 1);
if isempty(idx)
    error('Version %s was not found in %s.', versionName, matFile);
end
result = versionResults(idx);
end

function outputFiles = export_difference_figure(result, traj, bandName, svgOutDir, pngOutDir, settings)
fig = figure('Color', 'w', 'Position', [100 100 900 540]);
ax = axes(fig);
hold(ax, 'on');

plot_band(ax, traj.ageYears, traj.deltaMean_dB, ...
    traj.deltaCILow_dB, traj.deltaCIHigh_dB, ...
    [0.70 0.80 0.90], [0.39 0.44 0.50], 2.2);
yline(ax, 0, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.1);
ylim(ax, [-12 3]);
xlabel(ax, 'Age (years)');
ylabel(ax, sprintf('CP - Control %s power (dB)', title_case(bandName)));
title(ax, {sprintf('%s-band CP-Control group difference', title_case(bandName)), ...
    sprintf('%s: q_{f0}=%.3g, q_{group}=%.3g, r=%.3g dB^2', ...
    result.versionName, result.qF0, result.qGroupDifference, result.r)}, ...
    'FontWeight', 'normal');
style_axis(ax);

outputFiles = strings(0, 1);
if settings.writeSvg
    svgFile = fullfile(svgOutDir, sprintf( ...
        '05_power_ssm_fixed_heuristic_%s_group_difference.svg', bandName));
    save_svg(fig, svgFile);
    outputFiles(end + 1, 1) = string(svgFile);
end
if settings.writePng
    pngFile = fullfile(pngOutDir, sprintf( ...
        '%s_fixed_heuristic_%s_group_difference.png', settings.pngPrefix, bandName));
    save_png(fig, pngFile);
    outputFiles(end + 1, 1) = string(pngFile);
end
close_if_valid(fig);
end

function outputFiles = export_control_cp_figure(result, traj, bandName, svgOutDir, pngOutDir, settings)
isControl = traj.groupIndicator == 0;
isCP = traj.groupIndicator == 1;

gc = group_colors();   % shared/group_colors.m: Control blue, CP red
controlLineColor = gc.controlLine;
controlFillColor = gc.controlFill;
cpLineColor = gc.cpLine;
cpFillColor = gc.cpFill;

fig = figure('Color', 'w', 'Position', [100 100 920 560]);
ax = axes(fig);
hold(ax, 'on');

hControlBand = plot_band(ax, traj.ageYears, traj.baselineMean_dB, ...
    traj.baselineCILow_dB, traj.baselineCIHigh_dB, ...
    controlFillColor, controlLineColor, 2.2);
hCPBand = plot_band(ax, traj.ageYears, traj.cpMean_dB, ...
    traj.cpCILow_dB, traj.cpCIHigh_dB, ...
    cpFillColor, cpLineColor, 2.2);
hControlPts = scatter(ax, traj.ageYears(isControl), traj.alpha_dB(isControl), ...
    58, controlLineColor, 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.8);
hCPPts = scatter(ax, traj.ageYears(isCP), traj.alpha_dB(isCP), ...
    58, cpLineColor, 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 0.8);

xlabel(ax, 'Age (years)');
ylabel(ax, sprintf('%s power (dB)', title_case(bandName)));
title(ax, {sprintf('%s-band Control and CP state-space trajectories', title_case(bandName)), ...
    sprintf('%s: q_{f0}=%.3g, q_{group}=%.3g, r=%.3g dB^2', ...
    result.versionName, result.qF0, result.qGroupDifference, result.r)}, ...
    'FontWeight', 'normal');
legend(ax, [hControlBand.line, hControlBand.patch, hControlPts, ...
    hCPBand.line, hCPBand.patch, hCPPts], ...
    {'Control trajectory', 'Control 95% credible interval', 'Control subjects', ...
    'CP trajectory', 'CP 95% credible interval', 'CP subjects'}, ...
    'Location', 'best');
style_axis(ax);

outputFiles = strings(0, 1);
if settings.writeSvg
    svgFile = fullfile(svgOutDir, sprintf( ...
        '06_power_ssm_fixed_heuristic_%s_control_vs_cp.svg', bandName));
    save_svg(fig, svgFile);
    outputFiles(end + 1, 1) = string(svgFile);
end
if settings.writePng
    pngFile = fullfile(pngOutDir, sprintf( ...
        '%s_fixed_heuristic_%s_control_vs_cp.png', settings.pngPrefix, bandName));
    save_png(fig, pngFile);
    outputFiles(end + 1, 1) = string(pngFile);
end
close_if_valid(fig);
end

function handles = plot_band(ax, ages, meanVals, lowVals, highVals, fillColor, lineColor, lineWidth)
ages = ages(:);
meanVals = meanVals(:);
lowVals = lowVals(:);
highVals = highVals(:);
handles.patch = patch(ax, [ages; flipud(ages)], [lowVals; flipud(highVals)], ...
    fillColor, 'EdgeColor', 'none', 'FaceAlpha', 0.32);
handles.line = plot(ax, ages, meanVals, '-', 'Color', lineColor, 'LineWidth', lineWidth);
end

function style_axis(ax)
grid(ax, 'on');
box(ax, 'off');
ax.FontName = 'Helvetica';
ax.FontSize = 11;
ax.TickDir = 'out';
end

function save_svg(figHandle, outFile)
if ~isgraphics(figHandle, 'figure')
    warning('powerSsmExport:invalidFigure', ...
        'Skipping SVG export because figure handle is invalid: %s', outFile);
    return;
end
set(figHandle, 'Renderer', 'painters');
try
    print(figHandle, outFile, '-dsvg');
catch ME
    warning('powerSsmExport:svgExportFailed', ...
        'Skipping SVG export after print failed for %s: %s', outFile, ME.message);
end
end

function save_png(figHandle, outFile)
if ~isgraphics(figHandle, 'figure')
    warning('powerSsmExport:invalidFigure', ...
        'Skipping PNG export because figure handle is invalid: %s', outFile);
    return;
end
try
    exportgraphics(figHandle, outFile, 'Resolution', 200);
catch ME
    warning('powerSsmExport:pngExportFailed', ...
        'Skipping PNG export after exportgraphics failed for %s: %s', outFile, ME.message);
end
end

function close_if_valid(figHandle)
if isgraphics(figHandle, 'figure')
    close(figHandle);
end
end

function out = title_case(value)
value = char(string(value));
if isempty(value)
    out = value;
else
    out = [upper(value(1)), lower(value(2:end))];
end
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
