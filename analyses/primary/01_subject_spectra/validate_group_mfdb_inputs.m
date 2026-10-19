%% validate_group_mfdb_inputs
% Validate subject-level MFDB outputs before group analysis.
% Run section-by-section.

%% Step 1: Setup
clear; clc;

cfg = mfdb_config();
subjectRoot = cfg.outputDir;
validationOutDir = fullfile(cfg.scriptRoot, 'outputs', 'mfdb_validation');
if ~exist(validationOutDir, 'dir')
    mkdir(validationOutDir);
end

registryFile = fullfile(validationOutDir, 'mfdb_subject_registry.csv');
validationMatFile = fullfile(validationOutDir, 'mfdb_validation_results.mat');

fprintf('Scanning subject MFDB outputs in %s\n', subjectRoot);

%% Step 2: Build subject registry from saved files
files = dir(fullfile(subjectRoot, '*', '*_mfdb.mat'));
if isempty(files)
    error('No subject-level MFDB files found under %s', subjectRoot);
end

registry = table();
registry.subjectID = strings(0, 1);
registry.groupLabel = strings(0, 1);
registry.filePath = strings(0, 1);
registry.f3QualityPass = false(0, 1);
registry.ageYears = zeros(0, 1);
registry.Fs = zeros(0, 1);
registry.T = zeros(0, 1);
registry.N = zeros(0, 1);
registry.TW = zeros(0, 1);
registry.K = zeros(0, 1);
registry.Bsubj = zeros(0, 1);
registry.Bgroup = zeros(0, 1);
registry.fpassLow = zeros(0, 1);
registry.fpassHigh = zeros(0, 1);
registry.nFreq = zeros(0, 1);
registry.freqStart = zeros(0, 1);
registry.freqEnd = zeros(0, 1);
registry.requestedElectrodeLabel = strings(0, 1);
registry.usedElectrodeLabel = strings(0, 1);
registry.usedFallbackElectrode = false(0, 1);
registry.excluded = false(0, 1);
registry.exclusionReason = strings(0, 1);

for i = 1:numel(files)
    matPath = fullfile(files(i).folder, files(i).name);
    S = load(matPath, 'subjectID', 'groupLabel', 'freq', 'S_subject_boot_dB', 'metadata');

    if ~isfield(S, 'metadata')
        warning('Skipping %s because metadata is missing.', matPath);
        continue;
    end

    md = S.metadata;
    requestedElectrodeLabel = get_metadata_field(md, 'requestedElectrodeLabel', "F3");
    usedElectrodeLabel = get_metadata_field(md, 'usedElectrodeLabel', requestedElectrodeLabel);
    usedFallbackElectrode = get_metadata_field(md, 'usedFallbackElectrode', false);
    ageYears = double(md.ageYears);
    if ~isfinite(ageYears)
        ageYears = lookup_age_from_sevo_metadata(S.subjectID);
    end

    row = table( ...
        string(S.subjectID), ...
        string(S.groupLabel), ...
        string(matPath), ...
        logical(md.f3QualityPass), ...
        ageYears, ...
        double(md.Fs), ...
        double(md.T), ...
        double(md.N), ...
        double(md.TW), ...
        double(md.K), ...
        double(md.Bsubj), ...
        double(md.Bgroup), ...
        double(md.fpass(1)), ...
        double(md.fpass(2)), ...
        double(numel(S.freq)), ...
        double(S.freq(1)), ...
        double(S.freq(end)), ...
        string(requestedElectrodeLabel), ...
        string(usedElectrodeLabel), ...
        logical(usedFallbackElectrode), ...
        false, ...
        string(""), ...
        'VariableNames', {'subjectID','groupLabel','filePath','f3QualityPass','ageYears', ...
        'Fs','T','N','TW','K','Bsubj','Bgroup','fpassLow','fpassHigh', ...
        'nFreq','freqStart','freqEnd','requestedElectrodeLabel','usedElectrodeLabel', ...
        'usedFallbackElectrode','excluded','exclusionReason'});

    registry = [registry; row]; %#ok<AGROW>
end

registry = sortrows(registry, {'groupLabel', 'ageYears', 'subjectID'});
disp(registry(:, {'subjectID', 'groupLabel', 'ageYears', 'filePath'}));

%% Step 3: Validate consistency across included subjects
validation = struct();
validation.ok = true;
validation.messages = strings(0, 1);

includedMask = registry.f3QualityPass;
registry.excluded(~includedMask) = true;
registry.exclusionReason(~includedMask) = "F3 quality flag false";

if ~any(includedMask)
    error('No included subjects remain after applying F3 quality flags.');
end

includedRegistry = registry(includedMask, :);

% Use the first included subject as the reference.
refFile = char(includedRegistry.filePath(1));
ref = load(refFile, 'freq', 'S_subject_boot_dB', 'metadata');
refFreq = ref.freq(:);
refMd = ref.metadata;
refBsubj = size(ref.S_subject_boot_dB, 1);

for i = 1:height(includedRegistry)
    matPath = char(includedRegistry.filePath(i));
    S = load(matPath, 'freq', 'S_subject_boot_dB', 'metadata');
    md = S.metadata;
    freq = S.freq(:);
    thisBsubj = size(S.S_subject_boot_dB, 1);

    [validation, isOk] = check_scalar_match(validation, md.Fs, refMd.Fs, ...
        sprintf('%s Fs mismatch', includedRegistry.subjectID(i)));
    validation = check_scalar_warning(validation, md.T, refMd.T, ...
        sprintf('%s T mismatch; subject will be frequency-aligned during group bootstrap', includedRegistry.subjectID(i)));
    validation = check_scalar_warning(validation, md.N, refMd.N, ...
        sprintf('%s N mismatch; subject will be frequency-aligned during group bootstrap', includedRegistry.subjectID(i)));
    [validation, isOk4] = check_scalar_match(validation, md.TW, refMd.TW, ...
        sprintf('%s TW mismatch', includedRegistry.subjectID(i)));
    [validation, isOk5] = check_scalar_match(validation, md.K, refMd.K, ...
        sprintf('%s K mismatch', includedRegistry.subjectID(i)));
    [validation, isOk6] = check_scalar_match(validation, md.Bsubj, refMd.Bsubj, ...
        sprintf('%s Bsubj mismatch', includedRegistry.subjectID(i)));
    [validation, isOk7] = check_vector_match(validation, md.fpass(:), refMd.fpass(:), ...
        sprintf('%s fpass mismatch', includedRegistry.subjectID(i)));
    validation = check_vector_warning(validation, freq, refFreq, ...
        sprintf('%s freq vector mismatch; subject will be frequency-aligned during group bootstrap', includedRegistry.subjectID(i)));
    [validation, isOk9] = check_scalar_match(validation, thisBsubj, refBsubj, ...
        sprintf('%s bootstrap row count mismatch', includedRegistry.subjectID(i)));

    isSubjectOk = isOk && isOk4 && isOk5 && isOk6 && isOk7 && isOk9;
    if ~isSubjectOk
        rowMask = strcmp(registry.subjectID, includedRegistry.subjectID(i));
        registry.excluded(rowMask) = true;
        registry.exclusionReason(rowMask) = "Validation mismatch";
    end
end

includedAfterValidation = registry(~registry.excluded, :);

if isempty(validation.messages)
    validation.messages = "All included subjects passed validation.";
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
    'cfg', 'registry', 'includedAfterValidation', 'validation', ...
    'refFreq', 'refMd', 'refBsubj', '-v7.3');

fprintf('\nSaved registry to %s\n', registryFile);
fprintf('Saved validation results to %s\n', validationMatFile);

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

function validation = check_scalar_warning(validation, value, refValue, message)
    tol = 1e-10;
    ok = isfinite(value) && isfinite(refValue) && abs(double(value) - double(refValue)) <= tol;
    if ~ok
        validation.messages(end + 1, 1) = string(message); %#ok<AGROW>
    end
end

function validation = check_vector_warning(validation, value, refValue, message)
    tol = 1e-10;
    ok = isequal(size(value), size(refValue)) && all(isfinite(value)) && all(isfinite(refValue)) && ...
        all(abs(double(value(:)) - double(refValue(:))) <= tol);
    if ~ok
        validation.messages(end + 1, 1) = string(message); %#ok<AGROW>
    end
end

function value = get_metadata_field(md, fieldName, defaultValue)
    if isfield(md, fieldName)
        value = md.(fieldName);
    else
        value = defaultValue;
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
        warning('validate_group_mfdb_inputs:AgeLookupFailed', ...
            'Could not repair age for %s from Sevo metadata: %s', subjectID, ME.message);
    end
end
