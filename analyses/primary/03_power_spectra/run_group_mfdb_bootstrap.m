function groupOutFile = run_group_mfdb_bootstrap(opts)
%RUN_GROUP_MFDB_BOOTSTRAP Group-level MFDB bootstrap using validated subject-level F3 outputs.
%   groupOutFile = RUN_GROUP_MFDB_BOOTSTRAP() uses this repo's outputs.
%   Optional opts fields (used by tests/ to read the original outputs):
%     validationFile       - stage 01 validation results (.mat)
%     stateSpaceCohortFile - stage 02 collapsed power table (defines the cohort)
%     groupOutDir          - where to save group_mfdb_bootstrap_results.mat
%     randomSeed           - bootstrap seed (default: cfg.randomSeed)

%% Step 1: Setup
if nargin < 1, opts = struct(); end
cfg = mfdb_config();

validationFile = get_opt(opts, 'validationFile', cfg.validationFile);
groupOutDir = get_opt(opts, 'groupOutDir', fullfile(cfg.scriptRoot, 'outputs', 'mfdb_group_level'));
if ~exist(groupOutDir, 'dir')
    mkdir(groupOutDir);
end

groupOutFile = fullfile(groupOutDir, 'group_mfdb_bootstrap_results.mat');
useStateSpaceCohort = true;
stateSpaceCohortFile = get_opt(opts, 'stateSpaceCohortFile', ...
    fullfile(state_space_outputs_dir(), 'power_table_for_ssm_subepochs_collapsed.csv'));

if ~isfile(validationFile)
    error('Validation file not found: %s', validationFile);
end

fprintf('Loading validation results from %s\n', validationFile);

%% Step 2: Load validated subject-level MFDB files
V = load(validationFile, 'includedAfterValidation', 'registry', 'validation', 'cfg');

if ~isfield(V, 'includedAfterValidation') || isempty(V.includedAfterValidation)
    error('No included subjects found in validation output.');
end

registry = V.includedAfterValidation;

if useStateSpaceCohort
    if ~isfile(stateSpaceCohortFile)
        error('State-space cohort file not found: %s', stateSpaceCohortFile);
    end

    cohortTable = readtable(stateSpaceCohortFile, 'TextType', 'string');
    cohortSubjectIDs = string(cohortTable.subjectID);
    missingFromValidation = setdiff(cohortSubjectIDs, string(registry.subjectID));
    if ~isempty(missingFromValidation)
        error('State-space cohort subjects missing from MFDB validation: %s', ...
            strjoin(missingFromValidation, ', '));
    end

    registry = registry(ismember(string(registry.subjectID), cohortSubjectIDs), :);
    registry = sortrows(registry, {'groupLabel', 'ageYears', 'subjectID'});
    fprintf('Filtered to StateSpaceAlpha cohort: %d subjects from %s\n', ...
        height(registry), stateSpaceCohortFile);
end

cpMask = strcmpi(registry.groupLabel, 'CP');
controlMask = strcmpi(registry.groupLabel, 'Control');

if ~any(cpMask)
    error('No CP subjects found after validation.');
end
if ~any(controlMask)
    error('No Control subjects found after validation.');
end

cpRegistry = registry(cpMask, :);
controlRegistry = registry(controlMask, :);

fprintf('Validated CP subjects: %d\n', height(cpRegistry));
fprintf('Validated Control subjects: %d\n', height(controlRegistry));

[freq, cpOriginal, cpBoot, cpSubjectIDs, cpAlignment] = load_group_subject_data(cpRegistry);
[freq2, controlOriginal, controlBoot, controlSubjectIDs, controlAlignment] = load_group_subject_data(controlRegistry, freq);

if ~isequal(size(freq), size(freq2)) || any(abs(freq(:) - freq2(:)) > 1e-10)
    error('CP and Control frequency vectors do not match.');
end

nCP = size(cpOriginal, 1);
nControl = size(controlOriginal, 1);
nFreq = numel(freq);
Bgroup = cfg.Bgroup;

%% Step 3: Compute observed group spectra
groupMedian_CP_original_dB = median(cpOriginal, 1, 'omitnan');
groupMedian_Control_original_dB = median(controlOriginal, 1, 'omitnan');
groupDiff_original_dB = groupMedian_CP_original_dB - groupMedian_Control_original_dB;

fprintf('Computed observed group medians over %d frequency bins.\n', nFreq);

%% Step 4: Run group-level bootstrap
groupMedian_CP_boot_dB = zeros(Bgroup, nFreq);
groupMedian_Control_boot_dB = zeros(Bgroup, nFreq);
groupDiff_boot_dB = zeros(Bgroup, nFreq);

rng(get_opt(opts, 'randomSeed', cfg.randomSeed));
for b = 1:Bgroup
    cpDraw = draw_one_boot_per_subject(cpBoot);
    controlDraw = draw_one_boot_per_subject(controlBoot);

    medianCP = median(cpDraw, 1, 'omitnan');
    medianControl = median(controlDraw, 1, 'omitnan');
    groupMedian_CP_boot_dB(b, :) = medianCP;
    groupMedian_Control_boot_dB(b, :) = medianControl;
    groupDiff_boot_dB(b, :) = medianCP - medianControl;
end

fprintf('Completed %d group bootstrap iterations.\n', Bgroup);

%% Step 5: Compute confidence intervals and significance mask
groupMedian_CP_boot_median_dB = median(groupMedian_CP_boot_dB, 1, 'omitnan');
groupMedian_Control_boot_median_dB = median(groupMedian_Control_boot_dB, 1, 'omitnan');
groupMedian_CP_CI_low_dB = prctile(groupMedian_CP_boot_dB, 2.5, 1);
groupMedian_CP_CI_high_dB = prctile(groupMedian_CP_boot_dB, 97.5, 1);
groupMedian_Control_CI_low_dB = prctile(groupMedian_Control_boot_dB, 2.5, 1);
groupMedian_Control_CI_high_dB = prctile(groupMedian_Control_boot_dB, 97.5, 1);

groupDiff_boot_median_dB = median(groupDiff_boot_dB, 1, 'omitnan');
groupDiff_boot_CI_low_dB = prctile(groupDiff_boot_dB, 2.5, 1);
groupDiff_boot_CI_high_dB = prctile(groupDiff_boot_dB, 97.5, 1);

sigMask = (groupDiff_boot_CI_low_dB > 0) | (groupDiff_boot_CI_high_dB < 0);

fprintf('Significant pointwise bins: %d of %d\n', sum(sigMask), nFreq);

%% Step 6: Save group-level outputs
metadata = struct();
metadata.Bsubj = unique(registry.Bsubj);
metadata.Bgroup = Bgroup;
metadata.Fs = unique(registry.Fs);
metadata.T = unique(registry.T);
metadata.N = unique(registry.N);
metadata.TW = unique(registry.TW);
metadata.K = unique(registry.K);
metadata.fpass = [unique(registry.fpassLow), unique(registry.fpassHigh)];
metadata.electrodeLabel = cfg.electrodeLabel;
metadata.f3OnlyAnalysis = true;
metadata.validationFile = validationFile;
metadata.useStateSpaceCohort = useStateSpaceCohort;
metadata.stateSpaceCohortFile = stateSpaceCohortFile;
metadata.excludedSubjects = V.registry(V.registry.excluded, {'subjectID', 'groupLabel', 'exclusionReason'});
metadata.frequencyAlignment = [cpAlignment; controlAlignment];

save(groupOutFile, ...
    'freq', ...
    'cpSubjectIDs', 'controlSubjectIDs', ...
    'groupMedian_CP_original_dB', ...
    'groupMedian_Control_original_dB', ...
    'groupMedian_CP_boot_dB', ...
    'groupMedian_Control_boot_dB', ...
    'groupMedian_CP_boot_median_dB', ...
    'groupMedian_Control_boot_median_dB', ...
    'groupMedian_CP_CI_low_dB', ...
    'groupMedian_CP_CI_high_dB', ...
    'groupMedian_Control_CI_low_dB', ...
    'groupMedian_Control_CI_high_dB', ...
    'groupDiff_original_dB', ...
    'groupDiff_boot_dB', ...
    'groupDiff_boot_median_dB', ...
    'groupDiff_boot_CI_low_dB', ...
    'groupDiff_boot_CI_high_dB', ...
    'sigMask', ...
    'metadata', '-v7.3');

fprintf('Saved group-level MFDB results to %s\n', groupOutFile);
end

%% Local functions
function [freq, originalMatrix, bootCube, subjectIDs, alignmentTable] = load_group_subject_data(groupRegistry, referenceFreq)
    if nargin < 2
        referenceFreq = [];
    end

    nSubjects = height(groupRegistry);
    freq = referenceFreq(:);
    originalMatrix = [];
    bootCube = cell(nSubjects, 1);
    subjectIDs = string(groupRegistry.subjectID);
    alignmentTable = table();
    alignmentTable.subjectID = strings(0, 1);
    alignmentTable.groupLabel = strings(0, 1);
    alignmentTable.sourceNFreq = zeros(0, 1);
    alignmentTable.targetNFreq = zeros(0, 1);
    alignmentTable.wasInterpolated = false(0, 1);

    for i = 1:nSubjects
        matPath = char(groupRegistry.filePath(i));
        S = load(matPath, 'freq', 'S_subject_original_dB', 'S_subject_boot_dB');
        sourceFreq = S.freq(:);

        if isempty(freq)
            freq = sourceFreq;
            originalMatrix = zeros(nSubjects, numel(freq));
        elseif isempty(originalMatrix)
            originalMatrix = zeros(nSubjects, numel(freq));
        end

        needsInterpolation = ~isequal(size(sourceFreq), size(freq)) || ...
            any(abs(sourceFreq(:) - freq(:)) > 1e-10);

        if needsInterpolation
            originalMatrix(i, :) = interp1(sourceFreq, S.S_subject_original_dB(:), ...
                freq, 'linear', 'extrap').';
            bootCube{i} = interp1(sourceFreq, S.S_subject_boot_dB.', ...
                freq, 'linear', 'extrap').';
            fprintf('Frequency-aligned %s from %d to %d bins for group bootstrap.\n', ...
                subjectIDs(i), numel(sourceFreq), numel(freq));
        else
            originalMatrix(i, :) = S.S_subject_original_dB(:).';
            bootCube{i} = S.S_subject_boot_dB;
        end

        alignmentTable = [alignmentTable; table( ...
            string(groupRegistry.subjectID(i)), ...
            string(groupRegistry.groupLabel(i)), ...
            numel(sourceFreq), ...
            numel(freq), ...
            needsInterpolation, ...
            'VariableNames', {'subjectID','groupLabel','sourceNFreq','targetNFreq','wasInterpolated'})]; %#ok<AGROW>
    end
end

function drawMatrix = draw_one_boot_per_subject(bootCube)
    nSubjects = numel(bootCube);
    nFreq = size(bootCube{1}, 2);
    drawMatrix = zeros(nSubjects, nFreq);

    for i = 1:nSubjects
        thisBoot = bootCube{i};
        idx = randi(size(thisBoot, 1));
        drawMatrix(i, :) = thisBoot(idx, :);
    end
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
