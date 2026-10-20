function validationMatFile = validate_group_coherence_inputs(opts)
%VALIDATE_GROUP_COHERENCE_INPUTS Validate subject-level F3-F4 coherence/Fourier outputs before group analysis.
%   Optional opts fields (used by tests/):
%     subjectRoot      - folder of subject-level coherence files
%     validationOutDir - where to write the registry and validation results

%% Step 1: Setup
if nargin < 1, opts = struct(); end
paths = project_paths();
subjectRoot = get_opt(opts, 'subjectRoot', fullfile(paths.outputsDir, 'coherence_subject_level'));
validationOutDir = get_opt(opts, 'validationOutDir', fullfile(paths.outputsDir, 'coherence_validation'));
if ~exist(validationOutDir, 'dir')
    mkdir(validationOutDir);
end

registryFile = fullfile(validationOutDir, 'coherence_subject_registry.csv');
validationMatFile = fullfile(validationOutDir, 'coherence_validation_results.mat');

fprintf('Scanning subject-level coherence outputs in %s\n', subjectRoot);

%% Step 2: Build subject registry from saved files
files = dir(fullfile(subjectRoot, '*', '*_F3F4_coherence.mat'));
if isempty(files)
    error('No subject-level coherence files found under %s', subjectRoot);
end

registry = table();
registry.subjectID = strings(0, 1);
registry.groupLabel = strings(0, 1);
registry.filePath = strings(0, 1);
registry.ageYears = zeros(0, 1);
registry.Fs = zeros(0, 1);
registry.T = zeros(0, 1);
registry.N = zeros(0, 1);
registry.epochDurationSec = zeros(0, 1);
registry.f3Index = zeros(0, 1);
registry.f4Index = zeros(0, 1);
registry.f3QualityPass = false(0, 1);
registry.f4QualityPass = false(0, 1);
registry.segLen = zeros(0, 1);
registry.nWindows = zeros(0, 1);
registry.nTrials = zeros(0, 1);
registry.nTapers = zeros(0, 1);
registry.movingwinSec = zeros(0, 2);
registry.tapers = zeros(0, 2);
registry.fpassLow = zeros(0, 1);
registry.fpassHigh = zeros(0, 1);
registry.alphaLow = zeros(0, 1);
registry.alphaHigh = zeros(0, 1);
registry.nTimeBins = zeros(0, 1);
registry.nFreqBins = zeros(0, 1);
registry.freqStart = zeros(0, 1);
registry.freqEnd = zeros(0, 1);
registry.flattenedSamples = zeros(0, 1);
registry.excluded = false(0, 1);
registry.exclusionReason = strings(0, 1);

for i = 1:numel(files)
    matPath = fullfile(files(i).folder, files(i).name);
    S = load(matPath, 'subjectID', 'groupLabel', 'ageYears', 'freq', 'timeBins', 'J_F3_flat', 'metadata');

    if ~isfield(S, 'metadata')
        warning('Skipping %s because metadata is missing.', matPath);
        continue;
    end

    md = S.metadata;
    ageYears = double(S.ageYears);
    if ~isfinite(ageYears)
        ageYears = lookup_age_from_sevo_metadata(S.subjectID);
    end

    row = table( ...
        string(S.subjectID), ...
        string(S.groupLabel), ...
        string(matPath), ...
        ageYears, ...
        double(md.Fs), ...
        double(md.T), ...
        double(md.N), ...
        double(md.epochDurationSec), ...
        double(md.f3Index), ...
        double(md.f4Index), ...
        logical(md.f3QualityPass), ...
        logical(md.f4QualityPass), ...
        double(md.segLen), ...
        double(md.nWindows), ...
        double(md.nTrials), ...
        double(md.nTapers), ...
        reshape(double(md.movingwin), 1, []), ...
        reshape(double(md.tapers), 1, []), ...
        double(md.fpass(1)), ...
        double(md.fpass(2)), ...
        double(md.alphaBand(1)), ...
        double(md.alphaBand(2)), ...
        double(numel(S.timeBins)), ...
        double(numel(S.freq)), ...
        double(S.freq(1)), ...
        double(S.freq(end)), ...
        double(size(S.J_F3_flat, 2)), ...
        false, ...
        string(""), ...
        'VariableNames', {'subjectID','groupLabel','filePath','ageYears','Fs','T','N', ...
        'epochDurationSec','f3Index','f4Index','f3QualityPass','f4QualityPass', ...
        'segLen','nWindows','nTrials','nTapers','movingwinSec','tapers', ...
        'fpassLow','fpassHigh','alphaLow','alphaHigh','nTimeBins','nFreqBins', ...
        'freqStart','freqEnd','flattenedSamples','excluded','exclusionReason'});

    registry = [registry; row]; %#ok<AGROW>
end

registry = sortrows(registry, {'groupLabel', 'ageYears', 'subjectID'});
disp(registry(:, {'subjectID', 'groupLabel', 'ageYears', 'filePath'}));

%% Step 3: Validate consistency across includable subjects
validation = struct();
validation.ok = true;
validation.messages = strings(0, 1);

includedMask = registry.f3QualityPass & registry.f4QualityPass & registry.f3Index > 0 & registry.f4Index > 0;
registry.excluded(~includedMask) = true;
registry.exclusionReason(~includedMask) = "Missing F3/F4 or QC flag false";

if ~any(includedMask)
    error('No included subjects remain after applying F3/F4 presence and QC rules.');
end

includedRegistry = registry(includedMask, :);
refFile = char(includedRegistry.filePath(1));
ref = load(refFile, 'freq', 'timeBins', 'J_F3_flat', 'J_F4_flat', 'metadata');
refFreq = ref.freq(:);
refTimeBins = ref.timeBins(:);
refMd = ref.metadata;
refFlatSamples = size(ref.J_F3_flat, 2);

for i = 1:height(includedRegistry)
    matPath = char(includedRegistry.filePath(i));
    S = load(matPath, 'freq', 'timeBins', 'J_F3_flat', 'J_F4_flat', 'metadata');
    md = S.metadata;
    freq = S.freq(:);
    timeBins = S.timeBins(:);

    [validation, ok1] = check_scalar_match(validation, md.Fs, refMd.Fs, sprintf('%s Fs mismatch', includedRegistry.subjectID(i)));
    [validation, ok2] = check_scalar_match(validation, md.T, refMd.T, sprintf('%s T mismatch', includedRegistry.subjectID(i)));
    [validation, ok3] = check_scalar_match(validation, md.N, refMd.N, sprintf('%s N mismatch', includedRegistry.subjectID(i)));
    [validation, ok4] = check_scalar_match(validation, md.epochDurationSec, refMd.epochDurationSec, sprintf('%s epoch duration mismatch', includedRegistry.subjectID(i)));
    [validation, ok5] = check_scalar_match(validation, md.segLen, refMd.segLen, sprintf('%s segLen mismatch', includedRegistry.subjectID(i)));
    [validation, ok6] = check_scalar_match(validation, md.nWindows, refMd.nWindows, sprintf('%s nWindows mismatch', includedRegistry.subjectID(i)));
    [validation, ok7] = check_scalar_match(validation, md.nTrials, refMd.nTrials, sprintf('%s nTrials mismatch', includedRegistry.subjectID(i)));
    [validation, ok8] = check_scalar_match(validation, md.nTapers, refMd.nTapers, sprintf('%s nTapers mismatch', includedRegistry.subjectID(i)));
    [validation, ok9] = check_vector_match(validation, md.movingwin(:), refMd.movingwin(:), sprintf('%s movingwin mismatch', includedRegistry.subjectID(i)));
    [validation, ok10] = check_vector_match(validation, md.tapers(:), refMd.tapers(:), sprintf('%s tapers mismatch', includedRegistry.subjectID(i)));
    [validation, ok11] = check_vector_match(validation, md.fpass(:), refMd.fpass(:), sprintf('%s fpass mismatch', includedRegistry.subjectID(i)));
    [validation, ok12] = check_vector_match(validation, md.alphaBand(:), refMd.alphaBand(:), sprintf('%s alphaBand mismatch', includedRegistry.subjectID(i)));
    [validation, ok13] = check_vector_match(validation, freq, refFreq, sprintf('%s freq vector mismatch', includedRegistry.subjectID(i)));
    [validation, ok14] = check_vector_match(validation, timeBins, refTimeBins, sprintf('%s timeBins mismatch', includedRegistry.subjectID(i)));
    [validation, ok15] = check_scalar_match(validation, size(S.J_F3_flat, 2), refFlatSamples, sprintf('%s flattened J sample count mismatch', includedRegistry.subjectID(i)));
    [validation, ok16] = check_scalar_match(validation, size(S.J_F4_flat, 2), refFlatSamples, sprintf('%s flattened J sample count mismatch (F4)', includedRegistry.subjectID(i)));

    isSubjectOk = ok1 && ok2 && ok3 && ok4 && ok5 && ok6 && ok7 && ok8 && ok9 && ok10 && ok11 && ok12 && ok13 && ok14 && ok15 && ok16;
    if ~isSubjectOk
        rowMask = strcmp(registry.subjectID, includedRegistry.subjectID(i));
        registry.excluded(rowMask) = true;
        registry.exclusionReason(rowMask) = "Validation mismatch";
    end
end

includedAfterValidation = registry(~registry.excluded, :);

if isempty(validation.messages)
    validation.messages = "All included subjects passed coherence validation.";
end

fprintf('\nValidation summary:\n');
disp(validation.messages);

fprintf('\nIncluded after validation:\n');
disp(includedAfterValidation(:, {'subjectID', 'groupLabel', 'ageYears'}));

fprintf('\nExcluded after validation:\n');
disp(registry(registry.excluded, {'subjectID', 'groupLabel', 'ageYears', 'exclusionReason'}));

%% Step 4: Save validation outputs
writetable(registry, registryFile);
save(validationMatFile, ...
    'registry', 'includedAfterValidation', 'validation', ...
    'refFreq', 'refTimeBins', 'refMd', 'refFlatSamples', '-v7.3');

fprintf('\nSaved registry to %s\n', registryFile);
fprintf('Saved validation results to %s\n', validationMatFile);

end

%% Local functions
function [validation, ok] = check_scalar_match(validation, value, refValue, message)
    tol = 1e-10;
    ok = isfinite(value) && isfinite(refValue) && abs(double(value) - double(refValue)) <= tol;
    if ~ok
        validation.ok = false;
        validation.messages(end + 1, 1) = string(message); %#ok<AGROW>
    end
end

function [validation, ok] = check_vector_match(validation, value, refValue, message)
    tol = 1e-10;
    ok = isequal(size(value), size(refValue)) && all(isfinite(value)) && all(isfinite(refValue)) && ...
        all(abs(double(value(:)) - double(refValue(:))) <= tol);
    if ~ok
        validation.ok = false;
        validation.messages(end + 1, 1) = string(message); %#ok<AGROW>
    end
end

function ageYears = lookup_age_from_sevo_metadata(subjectID)
    ageYears = NaN;
    try
        meta = load_subject_metadata(struct('anesthesia', 'sevo'));

        controlIDs = string(meta.controls.sortedTable.Properties.RowNames);
        patientIDs = string(meta.patients.sortedTable.Properties.RowNames);

        idx = find(strcmpi(controlIDs, string(subjectID)), 1, 'first');
        if ~isempty(idx)
            ageYears = meta.controls.sortedTable.('AGE (YEARS)')(idx);
            return;
        end

        idx = find(strcmpi(patientIDs, string(subjectID)), 1, 'first');
        if ~isempty(idx)
            ageYears = meta.patients.sortedTable.('AGE (YEARS)')(idx);
        end
    catch ME
        warning('validate_group_coherence_inputs:AgeLookupFailed', ...
            'Could not repair age for %s from Sevo metadata: %s', subjectID, ME.message);
    end
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
