function tests = test_end_to_end
%TEST_END_TO_END Outputs of run_all.m (computed from raw data) vs the original analysis.
%   Run run_all.m first. Skipped when outputs/ or the reference folders are missing.
%   Deterministic quantities must match exactly; bootstrap-based ones within
%   Monte Carlo noise (the original had no random seed).
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    p = setup_project();
    td.new = p.outputsDir;
    td.ref = fullfile(p.referenceOutputsDir, 'outputs');
    td.refCoh = fullfile(p.referenceOutputsDir, 'coherence', 'outputs');
    td.refSSA = fullfile(p.referenceStateSpaceDir, 'outputs');
    assumeTrue(testCase, isfile(fullfile(td.new, 'coherence_group_level', 'group_f3f4_coherence_results.mat')), ...
        'Run run_all.m first; end-to-end comparison skipped.');
    assumeTrue(testCase, isfolder(td.ref), 'No reference outputs; skipped.');
    td.cohort = get_cohort();
    testCase.TestData = td;
end

function testStage01AllSubjectSpectraMatch(testCase)
    td = testCase.TestData;
    worst = 0;
    for id = td.cohort.subjectID.'
        f = fullfile(char(id), [char(id) '_F3_mfdb.mat']);
        a = load(fullfile(td.new, 'mfdb_subject_level', f), 'S_subject_original_dB');
        b = load(fullfile(td.ref, 'mfdb_subject_level', f), 'S_subject_original_dB');
        worst = max(worst, max(abs(a.S_subject_original_dB - b.S_subject_original_dB)));
    end
    fprintf('Stage 01: max |spectrum difference| over %d children = %.2g dB\n', height(td.cohort), worst);
    verifyLessThan(testCase, worst, 1e-9);
end

function testStage02PowerTablesMatch(testCase)
    td = testCase.TestData;
    a = sortrows(readtable(fullfile(td.new, 'state_space_model', 'power_table_for_ssm_subepochs_collapsed.csv'), 'TextType', 'string'), 'subjectID');
    b = sortrows(readtable(fullfile(td.refSSA, 'power_table_for_ssm_subepochs_collapsed.csv'), 'TextType', 'string'), 'subjectID');
    verifyEqual(testCase, a.subjectID, b.subjectID);
    for band = ["delta_dB", "theta_dB", "alpha_dB"]
        verifyEqual(testCase, a.(band), b.(band), 'AbsTol', 1e-9, band);   % no randomness
    end
    % MFDB variance comes from the bootstrap: compare within Monte Carlo noise
    rel = abs(a.alpha_meanSubepochMfdbVariance - b.alpha_meanSubepochMfdbVariance) ./ b.alpha_meanSubepochMfdbVariance;
    fprintf('Stage 02: alpha MFDB variance, median relative difference %.3f\n', median(rel));
    verifyLessThan(testCase, median(rel), 0.05);
end

function testStage03GroupSpectraMatch(testCase)
    td = testCase.TestData;
    a = load(fullfile(td.new, 'mfdb_group_level', 'group_mfdb_bootstrap_results.mat'), 'groupDiff_original_dB', 'sigMask');
    b = load(fullfile(td.ref, 'mfdb_group_level', 'group_mfdb_bootstrap_results.mat'), 'groupDiff_original_dB', 'sigMask');
    verifyEqual(testCase, a.groupDiff_original_dB, b.groupDiff_original_dB, 'AbsTol', 1e-9);
    flips = sum(a.sigMask(:) ~= b.sigMask(:));
    fprintf('Stage 03: significant bins %d vs %d; %d flip\n', sum(a.sigMask), sum(b.sigMask), flips);
    verifyLessThan(testCase, flips, 60);   % seed-to-seed: ~20 of 4681
end

function testStage05CoherenceMatches(testCase)
    td = testCase.TestData;
    a = load(fullfile(td.new, 'coherence_group_level', 'group_f3f4_coherence_results.mat'), 'controlMedian', 'cpMedian', 'inference', 'alphaComparison');
    b = load(fullfile(td.refCoh, 'coherence_group_level', 'group_f3f4_coherence_results.mat'), 'controlMedian', 'cpMedian', 'inference', 'alphaComparison');
    verifyEqual(testCase, a.controlMedian, b.controlMedian, 'AbsTol', 1e-10);
    verifyEqual(testCase, a.cpMedian, b.cpMedian, 'AbsTol', 1e-10);
    verifyEqual(testCase, a.inference.pvals, b.inference.pvals, 'AbsTol', 1e-10);
    verifyEqual(testCase, a.alphaComparison.ttestP, b.alphaComparison.ttestP, 'AbsTol', 1e-12);
end
