function out = plot_age_varying_f3_time_averaged_spectrogram(opts)
% Descriptive age-varying F3 spectra using time-averaged multitaper spectrograms.
% Each subject contributes one F3 spectrum obtained by:
%   1) mtspecgramc with movingwin [2 1]
%   2) converting to dB
%   3) averaging over time
%
% Optional opts.outDir (default: outputs/age_varying_spectrogram).
% Subjects: get_cohort() (shared inclusion rules). Returns the primary
% Control/CP figure handles, plotFileBase and outDir.

%% Step 1: Setup
if nargin < 1, opts = struct(); end
paths = project_paths();
criteria = cohort_criteria();

if exist('mtspecgramc', 'file') ~= 2
    error('mtspecgramc not found. Add Chronux to the MATLAB path before running this script.');
end

anesthesia = 'sevo';
electrodeLabel = 'F3';
ageMin = criteria.ageMinYears;
ageMax = criteria.ageMaxYears;
displayFreqRange = [1 30];
ageStep = 1;
primaryHalfWidth = 1.25;
sensitivityHalfWidth = 1.25;
minSubjectsPerWindow = 1;
lowConfidenceThreshold = 0;
useManualSpectrogramClim = true;
manualSpectrogramClim = [-20 5];
useManualDifferenceClim = false;
manualDifferenceClim = [-5 5];

specParams = struct();
specParams.tapers = [2 3];
specParams.fpass = [1 40];
movingwin = [2 1];

outDir = fullfile(paths.outputsDir, 'age_varying_spectrogram');
if isfield(opts, 'outDir') && ~isempty(opts.outDir)
    outDir = opts.outDir;
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

plotFileBase = sprintf('age_varying_f3_timeavg_spec_%0.1f_to_%0.1f_%s', ageMin, ageMax, anesthesia);

fprintf('Electrode: %s\n', electrodeLabel);
fprintf('Age range: [%.1f %.1f]\n', ageMin, ageMax);
fprintf('Display frequency range: [%.1f %.1f] Hz\n', displayFreqRange(1), displayFreqRange(2));
fprintf('Spectrogram settings: tapers [%g %g], fpass [%g %g], movingwin [%g %g]\n', ...
    specParams.tapers(1), specParams.tapers(2), specParams.fpass(1), specParams.fpass(2), movingwin(1), movingwin(2));
if useManualSpectrogramClim
    fprintf('Using manual spectrogram dB scale: [%.2f %.2f]\n', manualSpectrogramClim(1), manualSpectrogramClim(2));
else
    fprintf('Using data-driven spectrogram dB scale.\n');
end
if useManualDifferenceClim
    fprintf('Using manual difference dB scale: [%.2f %.2f]\n', manualDifferenceClim(1), manualDifferenceClim(2));
else
    fprintf('Using data-driven difference dB scale.\n');
end

%% Step 2: Subjects from the shared cohort definition
% get_cohort() applies the age, anesthesia, F3 and duration rules to the data
% folder. (The original script read the metadata and checked manual electrode
% review files; none of those reviews removed F3 for a cohort subject.)
cohort = get_cohort();
subjectTable = table(cohort.subjectID, cohort.groupLabel, cohort.ageYears, cohort.dataFile, ...
    'VariableNames', {'SubjectID', 'Group', 'AgeYears', 'DataFile'});
subjectTable.ReviewFile = strings(height(subjectTable), 1);
subjectTable.HasReviewFile = false(height(subjectTable), 1);
subjectTable = sortrows(subjectTable, {'Group', 'AgeYears', 'SubjectID'});

%% Step 4: Build per-subject time-averaged F3 spectra from spectrograms
results = table();
results.SubjectID = strings(0, 1);
results.Group = strings(0, 1);
results.AgeYears = zeros(0, 1);
results.Electrode = strings(0, 1);
results.Fs = zeros(0, 1);
results.SourceFile = strings(0, 1);
results.ReviewFileFound = false(0, 1);
results.F3RemovedInReview = false(0, 1);
results.NumTimeBins = zeros(0, 1);

subjectSpectrumDB = [];
refFreq = [];
missingElectrode = strings(0, 1);
freqMismatch = strings(0, 1);
removedInReview = strings(0, 1);
missingReviewFile = strings(0, 1);
shortEpochs = strings(0, 1);

for i = 1:height(subjectTable)
    subjectID = char(subjectTable.SubjectID(i));
    dataPath = char(subjectTable.DataFile(i));
    D = load(dataPath);

    if ~isfield(D, 'data') || ~isfield(D, 'HDR')
        warning('Skipping %s: missing data/HDR in %s', subjectID, dataPath);
        continue;
    end

    rawData = D.data;
    if size(rawData, 1) < size(rawData, 2)
        data = rawData';
    else
        data = rawData;
    end
    if size(data, 1) < size(data, 2)
        warning('Skipping %s: data orientation unresolved.', subjectID);
        continue;
    end

    labels = string(D.HDR.label(:));
    electrodeIdx = find(strcmpi(labels, electrodeLabel), 1, 'first');
    if isempty(electrodeIdx)
        missingElectrode(end + 1, 1) = string(subjectID); %#ok<AGROW>
        continue;
    end

    reviewFound = subjectTable.HasReviewFile(i);
    f3RemovedFlag = false;
    if reviewFound
        R = load(char(subjectTable.ReviewFile(i)), 'removedLabels');
        if isfield(R, 'removedLabels') && any(strcmpi(string(R.removedLabels(:)), electrodeLabel))
            removedInReview(end + 1, 1) = string(subjectID); %#ok<AGROW>
            continue;
        end
    else
        missingReviewFile(end + 1, 1) = string(subjectID); %#ok<AGROW>
    end

    Fs = double(D.HDR.frequency(1));
    T = size(data, 1) / Fs;
    if T < movingwin(1)
        shortEpochs(end + 1, 1) = string(subjectID); %#ok<AGROW>
        continue;
    end

    specParamsSubject = specParams;
    specParamsSubject.Fs = Fs;
    [S, t_spec, f] = mtspecgramc(data(:, electrodeIdx), movingwin, specParamsSubject);
    if isempty(S) || isempty(f)
        warning('Skipping %s: empty spectrogram output.', subjectID);
        continue;
    end

    freq = f(:);
    if isempty(refFreq)
        refFreq = freq;
    elseif numel(freq) ~= numel(refFreq) || any(abs(freq - refFreq) > 1e-9)
        freqMismatch(end + 1, 1) = string(subjectID); %#ok<AGROW>
        continue;
    end

    S_dB = 10 * log10(max(S, eps));
    meanSpecDB = mean(S_dB, 1, 'omitnan')';

    subjectSpectrumDB(:, end + 1) = meanSpecDB; %#ok<AGROW>
    row = table(string(subjectID), subjectTable.Group(i), subjectTable.AgeYears(i), ...
        string(electrodeLabel), Fs, string(dataPath), reviewFound, f3RemovedFlag, numel(t_spec), ...
        'VariableNames', {'SubjectID', 'Group', 'AgeYears', 'Electrode', 'Fs', 'SourceFile', ...
        'ReviewFileFound', 'F3RemovedInReview', 'NumTimeBins'});
    results = [results; row]; %#ok<AGROW>
end

if ~isempty(missingElectrode)
    fprintf('\nMissing electrode %s in raw data for:\n', electrodeLabel);
    disp(missingElectrode);
end
if ~isempty(removedInReview)
    fprintf('\nExcluded because %s was marked removed in manual review:\n', electrodeLabel);
    disp(removedInReview);
end
if ~isempty(shortEpochs)
    fprintf('\nExcluded because epoch was shorter than moving window:\n');
    disp(shortEpochs);
end
if ~isempty(freqMismatch)
    error('Frequency vector mismatch detected in: %s', strjoin(cellstr(freqMismatch), ', '));
end
if isempty(refFreq) || isempty(results)
    error('No valid F3 time-averaged spectrogram spectra were loaded.');
end

[results, sortIdx] = sortrows(results, {'Group', 'AgeYears', 'SubjectID'});
subjectSpectrumDB = subjectSpectrumDB(:, sortIdx);

fprintf('\nFinal subjects used for age-varying time-averaged F3 spectra: %d\n', height(results));
disp(results(:, {'SubjectID', 'Group', 'AgeYears', 'NumTimeBins'}));

%% Step 5: Lock display frequency mask and automatic age centers
freqMask = refFreq >= displayFreqRange(1) & refFreq <= displayFreqRange(2);
if ~any(freqMask)
    error('No frequency bins fall within the display range [%.1f %.1f] Hz.', ...
        displayFreqRange(1), displayFreqRange(2));
end

freqDisplay = refFreq(freqMask);
spectraDBDisplay = subjectSpectrumDB(freqMask, :);

observedMinAge = min(results.AgeYears);
observedMaxAge = max(results.AgeYears);
ageCenterMin = floor(observedMinAge / ageStep) * ageStep;
ageCenterMax = ceil(observedMaxAge / ageStep) * ageStep;
ageCenters = (ageCenterMin:ageStep:ageCenterMax).';

%% Step 6: Build primary and sensitivity age-varying matrices
[controlAgeSpec, cpAgeSpec, controlCounts, cpCounts, controlLowConfidenceMask, cpLowConfidenceMask, windowSummaryPrimary] = ...
    build_age_spectrograms(results, spectraDBDisplay, ageCenters, primaryHalfWidth, minSubjectsPerWindow, lowConfidenceThreshold);

[controlAgeSpecSensitivity, cpAgeSpecSensitivity, controlCountsSensitivity, cpCountsSensitivity, controlLowConfidenceMaskSensitivity, cpLowConfidenceMaskSensitivity, windowSummarySensitivity] = ...
    build_age_spectrograms(results, spectraDBDisplay, ageCenters, sensitivityHalfWidth, minSubjectsPerWindow, lowConfidenceThreshold);

primaryDifferenceSpec = cpAgeSpec - controlAgeSpec;
sensitivityDifferenceSpec = cpAgeSpecSensitivity - controlAgeSpecSensitivity;
primarySupportedMask = (controlCounts >= minSubjectsPerWindow) | (cpCounts >= minSubjectsPerWindow);
sensitivitySupportedMask = (controlCountsSensitivity >= minSubjectsPerWindow) | (cpCountsSensitivity >= minSubjectsPerWindow);

if useManualSpectrogramClim
    primaryClim = manualSpectrogramClim;
else
    primaryClim = compute_global_clim(controlAgeSpec, cpAgeSpec);
end
sensitivityClim = primaryClim;
if useManualDifferenceClim
    differenceClim = manualDifferenceClim;
else
    differenceClim = compute_difference_clim(primaryDifferenceSpec, sensitivityDifferenceSpec);
end

%% Step 7: Plot one figure at a time
figPrimaryControl = figure('Color', 'w', 'Position', [80 80 900 560]);
axPrimaryControl = axes(figPrimaryControl);
plot_age_spec_panel(axPrimaryControl, ageCenters, freqDisplay, controlAgeSpec, primaryClim, ...
    sprintf('Control: F3 time-averaged spectrogram spectrum (%s, half-width = %.2f years)', upper(anesthesia), primaryHalfWidth));
cbPrimaryControl = colorbar(axPrimaryControl);
cbPrimaryControl.Label.String = 'Median F3 Power (dB)';

figPrimaryCP = figure('Color', 'w', 'Position', [120 120 900 560]);
axPrimaryCP = axes(figPrimaryCP);
plot_age_spec_panel(axPrimaryCP, ageCenters, freqDisplay, cpAgeSpec, primaryClim, ...
    sprintf('CP: F3 time-averaged spectrogram spectrum (%s, half-width = %.2f years)', upper(anesthesia), primaryHalfWidth));
cbPrimaryCP = colorbar(axPrimaryCP);
cbPrimaryCP.Label.String = 'Median F3 Power (dB)';

figCounts = figure('Color', 'w', 'Position', [140 140 1200 520]);
tlCounts = tiledlayout(figCounts, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
axCounts1 = nexttile(tlCounts, 1);
plot_count_panel(axCounts1, ageCenters, controlCounts, controlLowConfidenceMask, 'Control support by age center', [0.90 0.45 0.10], minSubjectsPerWindow, lowConfidenceThreshold);
axCounts2 = nexttile(tlCounts, 2);
plot_count_panel(axCounts2, ageCenters, cpCounts, cpLowConfidenceMask, 'CP support by age center', [0.20 0.45 0.85], minSubjectsPerWindow, lowConfidenceThreshold);
xlabel(axCounts2, 'Age center (years)');

% The CP - Control difference map is not drawn (decision 2026-10-20); the
% difference matrices are still saved in the results file.

figSensitivityControl = figure('Color', 'w', 'Position', [180 180 900 560]);
axSensitivityControl = axes(figSensitivityControl);
plot_age_spec_panel(axSensitivityControl, ageCenters, freqDisplay, controlAgeSpecSensitivity, sensitivityClim, ...
    sprintf('Control: F3 time-averaged spectrogram spectrum (%s, half-width = %.2f years)', upper(anesthesia), sensitivityHalfWidth));
cbSensitivityControl = colorbar(axSensitivityControl);
cbSensitivityControl.Label.String = 'Median F3 Power (dB)';

figSensitivityCP = figure('Color', 'w', 'Position', [220 220 900 560]);
axSensitivityCP = axes(figSensitivityCP);
plot_age_spec_panel(axSensitivityCP, ageCenters, freqDisplay, cpAgeSpecSensitivity, sensitivityClim, ...
    sprintf('CP: F3 time-averaged spectrogram spectrum (%s, half-width = %.2f years)', upper(anesthesia), sensitivityHalfWidth));
cbSensitivityCP = colorbar(axSensitivityCP);
cbSensitivityCP.Label.String = 'Median F3 Power (dB)';

%% Step 8: Save outputs
resultsFile = fullfile(outDir, sprintf('%s_results.mat', plotFileBase));
subjectCsv = fullfile(outDir, sprintf('%s_subjects_used.csv', plotFileBase));
windowCsvPrimary = fullfile(outDir, sprintf('%s_window_summary_primary.csv', plotFileBase));
windowCsvSensitivity = fullfile(outDir, sprintf('%s_window_summary_sensitivity.csv', plotFileBase));

writetable(results, subjectCsv);
writetable(windowSummaryPrimary, windowCsvPrimary);
writetable(windowSummarySensitivity, windowCsvSensitivity);

save(resultsFile, ...
    'results', 'refFreq', 'freqDisplay', 'freqMask', 'ageCenters', ...
    'subjectSpectrumDB', 'controlAgeSpec', 'cpAgeSpec', 'primaryDifferenceSpec', ...
    'controlCounts', 'cpCounts', 'controlLowConfidenceMask', 'cpLowConfidenceMask', ...
    'windowSummaryPrimary', 'primaryHalfWidth', ...
    'controlAgeSpecSensitivity', 'cpAgeSpecSensitivity', 'sensitivityDifferenceSpec', ...
    'controlCountsSensitivity', 'cpCountsSensitivity', ...
    'controlLowConfidenceMaskSensitivity', 'cpLowConfidenceMaskSensitivity', ...
    'windowSummarySensitivity', 'sensitivityHalfWidth', ...
    'minSubjectsPerWindow', 'lowConfidenceThreshold', 'displayFreqRange', 'ageStep', ...
    'primaryClim', 'differenceClim', 'primarySupportedMask', 'sensitivitySupportedMask', ...
    'useManualSpectrogramClim', 'manualSpectrogramClim', ...
    'useManualDifferenceClim', 'manualDifferenceClim', ...
    'anesthesia', 'electrodeLabel', 'ageMin', 'ageMax', 'specParams', 'movingwin');

save_figure_if_valid(figPrimaryControl, fullfile(outDir, sprintf('%s_primary_control.png', plotFileBase)));
save_figure_if_valid(figPrimaryCP, fullfile(outDir, sprintf('%s_primary_cp.png', plotFileBase)));
save_figure_if_valid(figCounts, fullfile(outDir, sprintf('%s_counts.png', plotFileBase)));
save_figure_if_valid(figSensitivityControl, fullfile(outDir, sprintf('%s_sensitivity_control.png', plotFileBase)));
save_figure_if_valid(figSensitivityCP, fullfile(outDir, sprintf('%s_sensitivity_cp.png', plotFileBase)));

fprintf('\nSaved outputs to %s\n', outDir);

out = struct('figPrimaryControl', figPrimaryControl, 'figPrimaryCP', figPrimaryCP, ...
    'plotFileBase', plotFileBase, 'outDir', outDir);
end

%% Local functions
function T = build_age_table(sortedTable, groupLabel)
    T = table();
    T.SubjectID = string(sortedTable.Properties.RowNames);
    T.Group = repmat(string(groupLabel), height(sortedTable), 1);
    T.AgeYears = sortedTable.('AGE (YEARS)');
end

function tf = duplicated(vals)
    [~, firstIdx] = unique(vals, 'stable');
    tf = true(size(vals));
    tf(firstIdx) = false;
end

function save_figure_if_valid(figHandle, outFile)
    if isgraphics(figHandle, 'figure')
        saveas(figHandle, outFile);
    else
        warning('ageVaryingSpectrogram:invalidFigure', ...
            'Skipping save because figure handle is invalid: %s', outFile);
    end
end

function [controlSpec, cpSpec, controlCounts, cpCounts, controlLowConf, cpLowConf, summaryTable] = ...
    build_age_spectrograms(results, spectraMatrix, ageCenters, halfWidth, minSubjects, lowConfThresh)

    nFreq = size(spectraMatrix, 1);
    nAge = numel(ageCenters);
    controlSpec = nan(nFreq, nAge);
    cpSpec = nan(nFreq, nAge);
    controlCounts = zeros(nAge, 1);
    cpCounts = zeros(nAge, 1);
    controlLowConf = false(nAge, 1);
    cpLowConf = false(nAge, 1);

    summaryTable = table();
    summaryTable.AgeCenter = zeros(0, 1);
    summaryTable.WindowLow = zeros(0, 1);
    summaryTable.WindowHigh = zeros(0, 1);
    summaryTable.Group = strings(0, 1);
    summaryTable.NSubjects = zeros(0, 1);
    summaryTable.SubjectIDsIncluded = strings(0, 1);
    summaryTable.IsSupported = false(0, 1);
    summaryTable.IsLowConfidence = false(0, 1);

    controlMask = strcmp(results.Group, 'Control');
    cpMask = strcmp(results.Group, 'CP');

    for a = 1:nAge
        center = ageCenters(a);
        windowLow = center - halfWidth;
        windowHigh = center + halfWidth;

        inWindowControl = controlMask & results.AgeYears >= windowLow & results.AgeYears <= windowHigh;
        inWindowCP = cpMask & results.AgeYears >= windowLow & results.AgeYears <= windowHigh;

        controlCounts(a) = sum(inWindowControl);
        cpCounts(a) = sum(inWindowCP);
        controlLowConf(a) = controlCounts(a) < lowConfThresh;
        cpLowConf(a) = cpCounts(a) < lowConfThresh;

        if controlCounts(a) >= minSubjects
            controlSpec(:, a) = median(spectraMatrix(:, inWindowControl), 2, 'omitnan');
        end
        if cpCounts(a) >= minSubjects
            cpSpec(:, a) = median(spectraMatrix(:, inWindowCP), 2, 'omitnan');
        end

        summaryTable = [summaryTable; ...
            make_summary_row(center, windowLow, windowHigh, 'Control', controlCounts(a), results.SubjectID(inWindowControl), controlCounts(a) >= minSubjects, controlLowConf(a)); ...
            make_summary_row(center, windowLow, windowHigh, 'CP', cpCounts(a), results.SubjectID(inWindowCP), cpCounts(a) >= minSubjects, cpLowConf(a))]; %#ok<AGROW>
    end
end

function row = make_summary_row(center, windowLow, windowHigh, groupLabel, nSubjects, subjectIDs, isSupported, isLowConfidence)
    if isempty(subjectIDs)
        subjectList = "";
    else
        subjectList = strjoin(cellstr(subjectIDs(:)), ', ');
    end
    row = table(center, windowLow, windowHigh, string(groupLabel), nSubjects, string(subjectList), logical(isSupported), logical(isLowConfidence), ...
        'VariableNames', {'AgeCenter', 'WindowLow', 'WindowHigh', 'Group', 'NSubjects', 'SubjectIDsIncluded', 'IsSupported', 'IsLowConfidence'});
end

function clim = compute_global_clim(controlSpec, cpSpec)
    vals = [controlSpec(:); cpSpec(:)];
    vals = vals(isfinite(vals));
    if isempty(vals)
        clim = [0 1];
        return;
    end
    clim = prctile(vals, [5 95]);
    if numel(clim) ~= 2 || ~isfinite(clim(1)) || ~isfinite(clim(2)) || clim(1) >= clim(2)
        clim = [min(vals) max(vals)];
    end
    if clim(1) >= clim(2)
        pad = max(1, abs(clim(1)) * 0.05 + 1);
        clim = [clim(1) - pad, clim(2) + pad];
    end
end

function clim = compute_difference_clim(primaryDiff, sensitivityDiff)
    vals = [primaryDiff(:); sensitivityDiff(:)];
    vals = vals(isfinite(vals));
    if isempty(vals)
        clim = [-1 1];
        return;
    end
    lim = prctile(abs(vals), 95);
    if ~isfinite(lim) || lim <= 0
        lim = max(abs(vals));
    end
    if ~isfinite(lim) || lim <= 0
        lim = 1;
    end
    clim = [-lim lim];
end

function plot_age_spec_panel(ax, ageCenters, freqVals, specMatrix, clim, panelTitle)
    imagesc(ax, ageCenters, freqVals, specMatrix);
    axis(ax, 'xy');
    set(ax, 'Color', [1 1 1], 'FontName', 'Helvetica', 'FontSize', 11, 'LineWidth', 1, 'TickDir', 'out', 'Box', 'off');
    xlim(ax, [min(ageCenters) max(ageCenters)]);
    ylim(ax, [min(freqVals) max(freqVals)]);
    caxis(ax, clim);
    colormap(ax, jet(256));
    xlabel(ax, 'Age center (years)');
    ylabel(ax, 'Frequency (Hz)');
    title(ax, panelTitle, 'FontSize', 13, 'FontWeight', 'bold');
end

function plot_count_panel(ax, ageCenters, counts, lowConfidenceMask, panelTitle, lineColor, minSubjects, lowConfThresh)
    hold(ax, 'on');
    yline(ax, minSubjects, '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.25, 'Label', sprintf('min n = %d', minSubjects), 'LabelHorizontalAlignment', 'left');
    yline(ax, lowConfThresh, ':', 'Color', [0.55 0.55 0.55], 'LineWidth', 1.0, 'Label', sprintf('low-conf threshold = %d', lowConfThresh), 'LabelHorizontalAlignment', 'left');
    hMain = plot(ax, ageCenters, counts, '-o', 'Color', lineColor, 'LineWidth', 2, 'MarkerFaceColor', lineColor, 'MarkerEdgeColor', 'k', 'MarkerSize', 7);
    lowMask = lowConfidenceMask & counts >= minSubjects;
    if any(lowMask)
        scatter(ax, ageCenters(lowMask), counts(lowMask), 90, 'o', 'MarkerEdgeColor', [0.75 0.15 0.15], 'LineWidth', 1.5);
    end
    if any(counts < minSubjects)
        scatter(ax, ageCenters(counts < minSubjects), counts(counts < minSubjects), 80, 'x', 'MarkerEdgeColor', [0.65 0.10 0.10], 'LineWidth', 1.75);
    end
    xlim(ax, [min(ageCenters) max(ageCenters)]);
    ylim(ax, [0 max([counts(:); lowConfThresh + 1; minSubjects + 1]) + 1]);
    set(ax, 'Color', [1 1 1], 'FontName', 'Helvetica', 'FontSize', 11, 'LineWidth', 1, 'TickDir', 'out', 'Box', 'off');
    ylabel(ax, 'Subjects / window');
    title(ax, panelTitle, 'FontSize', 12, 'FontWeight', 'bold');
    legend(ax, hMain, {'Count'}, 'Location', 'northwest');
end
