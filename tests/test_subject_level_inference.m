function tests = test_subject_level_inference
%TEST_SUBJECT_LEVEL_INFERENCE The additional subject-level analyses run and make sense.
%   Needs run_all.m outputs. Checks structure, not specific scientific
%   results: every output is written, and children-resampled CIs are wider
%   than the published measurement-noise CIs (as they must be).
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    p = setup_project();
    assumeTrue(testCase, isfile(fullfile(p.outputsDir, 'coherence_group_level', 'group_f3f4_coherence_results.mat')), ...
        'Run run_all.m first; skipped.');
    addpath(genpath(fullfile(repoRoot, 'analyses', 'additional', 'subject_level_inference')));
    evalc('testCase.TestData.power = run_subject_level_power_spectra();');  close all;
    evalc('testCase.TestData.age = run_subject_level_age_trajectories();');  close all;
    evalc('testCase.TestData.coh = run_subject_level_coherence();');  close all;
end

function testOutputsWritten(testCase)
    td = testCase.TestData;
    verifyTrue(testCase, isfile(fullfile(td.power.outDir, 'power_difference_subject_level.png')));
    verifyTrue(testCase, isfile(fullfile(td.age.outDir, 'alpha_vs_age_subject_level.png')));
    verifyTrue(testCase, isfile(fullfile(td.coh.outDir, 'coherence_subject_level.png')));
end

function testChildResampledCIsAreWider(testCase)
    S = load(fullfile(testCase.TestData.power.outDir, 'subject_level_power_spectra.mat'), 'boot', 'published');
    childWidth = median(diff(S.boot.ciDifference, 1, 1));
    publishedWidth = median(S.published.groupDiff_boot_CI_high_dB - S.published.groupDiff_boot_CI_low_dB);
    verifyGreaterThan(testCase, childWidth, publishedWidth);
end

function testNoBinCIWithFewChildren(testCase)
    bins = testCase.TestData.age.bins;
    few = bins.nCP < 3 | bins.nControl < 3;
    verifyTrue(testCase, all(isnan(bins.ciLow_dB(few))), 'No CI where a group has < 3 children');
end

function testWindowDifferencePanel(testCase)
    % Bottom panel: CP - Control in each window equals the difference of the group means,
    % and has a CI only where both groups have >= 3 children.
    w = testCase.TestData.age.windows;
    verifyEqual(testCase, w.difference_dB, w.CP_mean_dB - w.Control_mean_dB, 'AbsTol', 1e-12);
    few = w.CP_n < 3 | w.Control_n < 3;
    verifyTrue(testCase, all(isnan(w.diff_ciLow_dB(few))));
    verifyTrue(testCase, all(~isnan(w.diff_ciLow_dB(~few))));
    ok = ~few;
    verifyTrue(testCase, all(w.diff_ciLow_dB(ok) <= w.difference_dB(ok) & w.difference_dB(ok) <= w.diff_ciHigh_dB(ok)));
end
