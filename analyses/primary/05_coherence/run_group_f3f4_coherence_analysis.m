function resultsFile = run_group_f3f4_coherence_analysis(opts)
%RUN_GROUP_F3F4_COHERENCE_ANALYSIS Group-level descriptive and inferential F3-F4 coherence analysis.
%   Optional opts fields (used by tests/):
%     validationMatFile - stage 05 validation results
%     subjectIDs        - cohort (default: get_cohort() subjects that also have F4)
%     groupOutDir       - where to save the group results

%% Step 1: Setup
if nargin < 1, opts = struct(); end
paths = project_paths();
ensure_chronux_paths();
validationMatFile = get_opt(opts, 'validationMatFile', ...
    fullfile(paths.outputsDir, 'coherence_validation', 'coherence_validation_results.mat'));
groupOutDir = get_opt(opts, 'groupOutDir', fullfile(paths.outputsDir, 'coherence_group_level'));
if ~exist(groupOutDir, 'dir')
    mkdir(groupOutDir);
end

if ~isfile(validationMatFile)
    error('Validation results not found: %s', validationMatFile);
end

fprintf('Loading coherence validation results from %s\n', validationMatFile);

%% Step 2: Load validated subject registry and subject-level coherence/Fourier outputs
V = load(validationMatFile);
includedRegistry = V.includedAfterValidation;

% Cohort: everyone in get_cohort() who also has F4 (coherence needs both channels).
cohort = get_cohort();
cohortSubjectIDs = string(get_opt(opts, 'subjectIDs', cohort.subjectID(cohort.hasF4)));
missingFromValidation = setdiff(cohortSubjectIDs, string(includedRegistry.subjectID));
if ~isempty(missingFromValidation)
    error('Coherence cohort subjects missing from validation (run subject-level coherence): %s', ...
        strjoin(missingFromValidation, ', '));
end
includedRegistry = includedRegistry(ismember(string(includedRegistry.subjectID), cohortSubjectIDs), :);
fprintf('Coherence cohort: %d subjects\n', height(includedRegistry));

if isempty(includedRegistry)
    error('No subjects remain after coherence validation.');
end

subjectTable = table();
subjectTable.subjectID = strings(0, 1);
subjectTable.groupLabel = strings(0, 1);
subjectTable.ageYears = zeros(0, 1);
subjectTable.filePath = strings(0, 1);
subjectTable.alphaCoherenceMean = zeros(0, 1);

coherenceMatrix = [];
freq = [];
metadataRef = struct();
J1c1 = [];
J2c1 = [];
J1c2 = [];
J2c2 = [];

for i = 1:height(includedRegistry)
    matPath = char(includedRegistry.filePath(i));
    S = load(matPath, 'subjectID', 'groupLabel', 'ageYears', 'freq', 'coherence_subject', 'alphaCoherenceMean', 'J_F3_flat', 'J_F4_flat', 'metadata');

    if isempty(freq)
        freq = S.freq(:);
        coherenceMatrix = nan(height(includedRegistry), numel(freq));
        metadataRef = S.metadata;
    end

    coherenceMatrix(i, :) = S.coherence_subject(:).';
    % Use the validated registry age rather than the saved subject file age.
    % Older newly-added outputs may have ageYears = NaN in the subject .mat,
    % while validate_group_coherence_inputs repairs age from the Sevo-only
    % metadata workbook.
    registryAgeYears = double(includedRegistry.ageYears(i));
    subjectTable = [subjectTable; table(string(S.subjectID), string(S.groupLabel), registryAgeYears, string(matPath), ...
        double(S.alphaCoherenceMean), 'VariableNames', {'subjectID','groupLabel','ageYears','filePath','alphaCoherenceMean'})]; %#ok<AGROW>

    if strcmpi(S.groupLabel, 'Control')
        J1c1 = [J1c1, S.J_F3_flat]; %#ok<AGROW>
        J2c1 = [J2c1, S.J_F4_flat]; %#ok<AGROW>
    elseif strcmpi(S.groupLabel, 'CP')
        J1c2 = [J1c2, S.J_F3_flat]; %#ok<AGROW>
        J2c2 = [J2c2, S.J_F4_flat]; %#ok<AGROW>
    else
        error('Unexpected group label %s in %s', string(S.groupLabel), matPath);
    end
end

subjectTable = sortrows(subjectTable, {'groupLabel', 'ageYears', 'subjectID'});
controlMask = strcmpi(subjectTable.groupLabel, 'Control');
cpMask = strcmpi(subjectTable.groupLabel, 'CP');

controlSpectra = coherenceMatrix(controlMask, :);
cpSpectra = coherenceMatrix(cpMask, :);

if isempty(controlSpectra) || isempty(cpSpectra)
    error('Both Control and CP groups are required for group coherence analysis.');
end

fprintf('Included controls: %d\n', sum(controlMask));
fprintf('Included CP subjects: %d\n', sum(cpMask));
fprintf('Frequency bins: %d\n', numel(freq));
fprintf('Control pooled J columns: %d\n', size(J1c1, 2));
fprintf('CP pooled J columns: %d\n', size(J1c2, 2));

%% Step 3: Compute descriptive group coherence curves
controlMedian = median(controlSpectra, 1, 'omitnan');
cpMedian = median(cpSpectra, 1, 'omitnan');
controlIQR = prctile(controlSpectra, [25 75], 1);
cpIQR = prctile(cpSpectra, [25 75], 1);

alphaBand = metadataRef.alphaBand(:).';
alphaMask = freq >= alphaBand(1) & freq <= alphaBand(2);

if any(alphaMask)
    controlAlphaSummary = struct( ...
        'median', median(subjectTable.alphaCoherenceMean(controlMask), 'omitnan'), ...
        'iqr', prctile(subjectTable.alphaCoherenceMean(controlMask), [25 75]), ...
        'n', sum(controlMask));
    cpAlphaSummary = struct( ...
        'median', median(subjectTable.alphaCoherenceMean(cpMask), 'omitnan'), ...
        'iqr', prctile(subjectTable.alphaCoherenceMean(cpMask), [25 75]), ...
        'n', sum(cpMask));
else
    controlAlphaSummary = struct('median', NaN, 'iqr', [NaN NaN], 'n', sum(controlMask));
    cpAlphaSummary = struct('median', NaN, 'iqr', [NaN NaN], 'n', sum(cpMask));
end

%% Step 4: Run the Chronux/Bokil two-group coherence test
primaryP = 0.001;
exploratoryP = 0.01;
[dz, vdz, Adz] = two_group_test_coherence(J1c1, J2c1, J1c2, J2c2, primaryP, 'n', freq); %#ok<ASGLU>

dz = dz(:);
vdz = vdz(:);
Adz = logical(Adz(:));
pvals = 2 * (1 - normcdf(abs(dz)));

if numel(freq) < 2
    error('Need at least two frequency bins to compute contiguous-width criterion.');
end

df = median(diff(freq));
contiguousWidthHz = 2 * metadataRef.tapers(1) / metadataRef.movingwin(1);
minContiguousBins = ceil(contiguousWidthHz / df);

sigMask_raw = pvals < primaryP;
sigMask_contiguous = apply_contiguous_width(sigMask_raw, minContiguousBins);
sigMask_raw_exploratory = pvals < exploratoryP;
sigMask_contiguous_exploratory = apply_contiguous_width(sigMask_raw_exploratory, minContiguousBins);

inference = struct();
inference.primaryP = primaryP;
inference.exploratoryP = exploratoryP;
inference.dz = dz;
inference.vdz = vdz;
inference.Adz = Adz;
inference.pvals = pvals;
inference.df = df;
inference.contiguousWidthHz = contiguousWidthHz;
inference.minContiguousBins = minContiguousBins;
inference.sigMask_raw = sigMask_raw;
inference.sigMask_contiguous = sigMask_contiguous;
inference.sigMask_raw_exploratory = sigMask_raw_exploratory;
inference.sigMask_contiguous_exploratory = sigMask_contiguous_exploratory;
inference.specialLowFrequencyHandlingApplied = false;
inference.specialLowFrequencyHandlingNote = 'No separate <= 3 Hz exception applied in this implementation.';

fprintf('\nInference summary:\n');
fprintf('Primary threshold p < %.3g\n', primaryP);
fprintf('Exploratory threshold p < %.3g\n', exploratoryP);
fprintf('Frequency spacing df = %.3f Hz\n', df);
fprintf('Contiguous-width criterion = %.3f Hz (%d bins)\n', contiguousWidthHz, minContiguousBins);
fprintf('Primary raw significant bins: %d\n', sum(sigMask_raw));
fprintf('Primary contiguous significant bins: %d\n', sum(sigMask_contiguous));
fprintf('Exploratory contiguous significant bins: %d\n', sum(sigMask_contiguous_exploratory));

%% Step 5: Scalar alpha-coherence group comparison
alphaComparison = struct();
alphaComparison.controlValues = subjectTable.alphaCoherenceMean(controlMask);
alphaComparison.cpValues = subjectTable.alphaCoherenceMean(cpMask);
alphaComparison.ranksumP = ranksum(alphaComparison.cpValues, alphaComparison.controlValues);
[~, alphaComparison.ttestP, ~, alphaComparison.ttestStats] = ttest2(alphaComparison.cpValues, alphaComparison.controlValues);

fprintf('\nAlpha-coherence scalar comparison:\n');
fprintf('Wilcoxon rank-sum p = %.6f\n', alphaComparison.ranksumP);
fprintf('Two-sample t-test p = %.6f\n', alphaComparison.ttestP);

%% Step 6: Save group outputs
resultsFile = fullfile(groupOutDir, 'group_f3f4_coherence_results.mat');
subjectCsv = fullfile(groupOutDir, 'group_f3f4_coherence_subject_table.csv');

writetable(subjectTable, subjectCsv);
save(resultsFile, ...
    'subjectTable', 'freq', ...
    'controlSpectra', 'cpSpectra', ...
    'controlMedian', 'cpMedian', ...
    'controlIQR', 'cpIQR', ...
    'J1c1', 'J2c1', 'J1c2', 'J2c2', ...
    'controlAlphaSummary', 'cpAlphaSummary', ...
    'alphaComparison', 'inference', 'metadataRef', '-v7.3');

fprintf('\nSaved subject table to %s\n', subjectCsv);
fprintf('Saved group coherence results to %s\n', resultsFile);

end

%% Local functions
function ensure_chronux_paths()
    if exist('two_group_test_coherence', 'file') == 2
        return;
    end
    if exist('two_group_test_coherence', 'file') ~= 2
        error('two_group_test_coherence not found on the MATLAB path.');
    end
end

function filteredMask = apply_contiguous_width(mask, minBins)
    filteredMask = false(size(mask));
    if isempty(mask) || ~any(mask)
        return;
    end

    mask = logical(mask(:));
    dMask = diff([false; mask; false]);
    startIdx = find(dMask == 1);
    endIdx = find(dMask == -1) - 1;

    for i = 1:numel(startIdx)
        runIdx = startIdx(i):endIdx(i);
        if numel(runIdx) >= minBins
            filteredMask(runIdx) = true;
        end
    end
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
