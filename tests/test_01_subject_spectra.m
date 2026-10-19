function tests = test_01_subject_spectra
%TEST_01_SUBJECT_SPECTRA Stage 01 on one subject, compared with saved outputs.
%   Runs the 120 s subject-level MFDB for CS28 into a temporary folder and
%   checks it against the reference output (referenceOutputsDir in
%   config_local.m). Comparisons are skipped when no reference is set.
%
%   - The multitaper spectrum has no randomness, so it must match exactly.
%   - The bootstrap is random. The reference was made without a seed, so
%     its 95% CI can only agree within Monte Carlo error.
%   - With the seed in mfdb_config.m, two runs must be identical.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    paths = setup_project();

    cfg = mfdb_config();
    cfg.outputDir = tempname;
    testCase.addTeardown(@() rmdir(cfg.outputDir, 's'));

    subjectID = 'CS28';
    tic;
    run_subject_mfdb_bootstrap_for_id(subjectID, true, cfg);
    fprintf('Stage 01 runtime for %s: %.1f s\n', subjectID, toc);

    testCase.TestData.new = load(fullfile(cfg.outputDir, subjectID, 'CS28_F3_mfdb.mat'));
    testCase.TestData.cfg = cfg;
    testCase.TestData.refFile = fullfile(paths.referenceOutputsDir, 'outputs', ...
        'mfdb_subject_level', subjectID, 'CS28_F3_mfdb.mat');
end

function testOriginalSpectrumMatchesReference(testCase)
    ref = load_reference(testCase);
    new = testCase.TestData.new;
    verifyEqual(testCase, new.freq, ref.freq, 'AbsTol', 1e-12);
    verifyEqual(testCase, new.S_subject_original_dB, ref.S_subject_original_dB, 'AbsTol', 1e-9);
    verifyEqual(testCase, [new.Fs new.N new.ageYears], [ref.Fs ref.N ref.ageYears]);
    verifyEqual(testCase, new.usedElectrodeLabel, ref.usedElectrodeLabel);
end

function testBootstrapCIWithinMonteCarloError(testCase)
    ref = load_reference(testCase);
    new = testCase.TestData.new;
    ciNew = prctile(new.S_subject_boot_dB, [2.5 97.5]);
    ciRef = prctile(ref.S_subject_boot_dB, [2.5 97.5]);

    % Yardstick: how much do CIs move between two seeds of OUR code?
    otherSeed = run_with_seed(testCase, testCase.TestData.cfg.randomSeed + 1);
    ciOther = prctile(otherSeed.S_subject_boot_dB, [2.5 97.5]);

    dRef = abs(ciNew(:) - ciRef(:));
    dSeed = abs(ciNew(:) - ciOther(:));
    fprintf('CI |diff| vs reference:  median %.3f, 99th pct %.3f dB\n', median(dRef), prctile(dRef, 99));
    fprintf('CI |diff| between seeds: median %.3f, 99th pct %.3f dB\n', median(dSeed), prctile(dSeed, 99));

    % The reference should look like "just another seed". A real change to
    % the method would push these well past seed-to-seed noise.
    verifyLessThan(testCase, median(dRef), 1.5 * median(dSeed));
    verifyLessThan(testCase, prctile(dRef, 99), 1.5 * prctile(dSeed, 99));
    widthRatio = median(diff(ciNew)) / median(diff(ciRef));
    verifyEqual(testCase, widthRatio, 1, 'AbsTol', 0.01);
end

function testSeededRunIsReproducible(testCase)
    again = run_with_seed(testCase, testCase.TestData.cfg.randomSeed);
    verifyEqual(testCase, again.S_subject_boot_dB, testCase.TestData.new.S_subject_boot_dB);
end

function S = run_with_seed(testCase, seed)
    cfg = testCase.TestData.cfg;
    cfg.randomSeed = seed;
    cfg.outputDir = tempname;
    testCase.addTeardown(@() rmdir(cfg.outputDir, 's'));
    run_subject_mfdb_bootstrap_for_id('CS28', true, cfg);
    S = load(fullfile(cfg.outputDir, 'CS28', 'CS28_F3_mfdb.mat'), 'S_subject_boot_dB');
end

function ref = load_reference(testCase)
    refFile = testCase.TestData.refFile;
    assumeTrue(testCase, isfile(refFile), 'No reference output; comparison skipped.');
    ref = load(refFile);
end
