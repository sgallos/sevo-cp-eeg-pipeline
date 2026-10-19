function tests = test_03_power_spectra
%TEST_03_POWER_SPECTRA Stage 03 (group MFDB, Figs 1-2), compared with saved outputs.
%   Feeds the ORIGINAL stage 01 validation registry into the group bootstrap
%   (cohort from get_cohort()), so this tests stage 03 on its own.
%   - Group medians of the original spectra have no randomness: exact match.
%   - Bootstrap CIs and the significance mask: must differ from the original
%     no more than two of our own seeds differ from each other.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    paths = setup_project();

    refGroupFile = fullfile(paths.referenceOutputsDir, 'outputs', 'mfdb_group_level', ...
        'group_mfdb_bootstrap_results.mat');
    opts.validationFile = fullfile(paths.referenceOutputsDir, 'outputs', 'mfdb_validation', ...
        'mfdb_validation_results.mat');
    assumeTrue(testCase, isfile(refGroupFile) && isfile(opts.validationFile), ...
        'Reference outputs not configured; skipped.');

    opts.groupOutDir = tempname;
    testCase.addTeardown(@() rmdir(opts.groupOutDir, 's'));
    evalc('run_group_mfdb_bootstrap(opts);');
    testCase.TestData.new = load(fullfile(opts.groupOutDir, 'group_mfdb_bootstrap_results.mat'));
    testCase.TestData.groupOutDir = opts.groupOutDir;

    % Same inputs, different seed: the yardstick for "just Monte Carlo noise".
    cfg = mfdb_config();
    opts.randomSeed = cfg.randomSeed + 1;
    opts.groupOutDir = tempname;
    testCase.addTeardown(@() rmdir(opts.groupOutDir, 's'));
    evalc('run_group_mfdb_bootstrap(opts);');
    testCase.TestData.otherSeed = load(fullfile(opts.groupOutDir, 'group_mfdb_bootstrap_results.mat'));

    testCase.TestData.ref = load(refGroupFile);
end

function testCohortMatches(testCase)
    new = testCase.TestData.new;  ref = testCase.TestData.ref;
    verifyEqual(testCase, sort(string(new.cpSubjectIDs)), sort(string(ref.cpSubjectIDs)));
    verifyEqual(testCase, sort(string(new.controlSubjectIDs)), sort(string(ref.controlSubjectIDs)));
    verifyNumElements(testCase, new.cpSubjectIDs, 12);
    verifyNumElements(testCase, new.controlSubjectIDs, 12);
end

function testGroupMediansMatchExactly(testCase)
    new = testCase.TestData.new;  ref = testCase.TestData.ref;
    verifyEqual(testCase, new.freq, ref.freq, 'AbsTol', 1e-12);
    verifyEqual(testCase, new.groupMedian_CP_original_dB, ref.groupMedian_CP_original_dB, 'AbsTol', 1e-9);
    verifyEqual(testCase, new.groupMedian_Control_original_dB, ref.groupMedian_Control_original_dB, 'AbsTol', 1e-9);
    verifyEqual(testCase, new.groupDiff_original_dB, ref.groupDiff_original_dB, 'AbsTol', 1e-9);
end

function testDifferenceCIWithinMonteCarloError(testCase)
    new = testCase.TestData.new;  ref = testCase.TestData.ref;  other = testCase.TestData.otherSeed;
    ciNew = [new.groupDiff_boot_CI_low_dB(:); new.groupDiff_boot_CI_high_dB(:)];
    ciRef = [ref.groupDiff_boot_CI_low_dB(:); ref.groupDiff_boot_CI_high_dB(:)];
    ciOther = [other.groupDiff_boot_CI_low_dB(:); other.groupDiff_boot_CI_high_dB(:)];
    dRef = abs(ciNew - ciRef);  dSeed = abs(ciNew - ciOther);
    fprintf('Diff CI |change| vs reference:  median %.4f, 99th pct %.4f dB\n', median(dRef), prctile(dRef, 99));
    fprintf('Diff CI |change| between seeds: median %.4f, 99th pct %.4f dB\n', median(dSeed), prctile(dSeed, 99));
    verifyLessThan(testCase, median(dRef), 1.5 * median(dSeed));
    verifyLessThan(testCase, prctile(dRef, 99), 1.5 * prctile(dSeed, 99));
end

function testSignificanceMaskWithinMonteCarloError(testCase)
    new = testCase.TestData.new;  ref = testCase.TestData.ref;  other = testCase.TestData.otherSeed;
    flipsRef = sum(new.sigMask(:) ~= ref.sigMask(:));
    flipsSeed = sum(new.sigMask(:) ~= other.sigMask(:));
    fprintf('Significant bins: ours %d, reference %d (of %d)\n', ...
        sum(new.sigMask), sum(ref.sigMask), numel(new.sigMask));
    fprintf('Bins that flip: vs reference %d, between seeds %d\n', flipsRef, flipsSeed);
    verifyLessThanOrEqual(testCase, flipsRef, max(5, 2 * flipsSeed));
end

function testFiguresAreWritten(testCase)
    outDir = testCase.TestData.groupOutDir;
    evalc('figs = plot_group_mfdb_results(outDir);');
    close all;
    names = {'01_group_median_mfdb_spectra.png', '02_group_mfdb_difference_with_ci.png', ...
             '03_group_mfdb_significance_mask.png', '04_group_mfdb_difference_and_significance.png'};
    for i = 1:numel(names)
        verifyTrue(testCase, isfile(fullfile(outDir, names{i})), names{i});
    end
end
