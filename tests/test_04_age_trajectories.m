function tests = test_04_age_trajectories
%TEST_04_AGE_TRAJECTORIES Stage 04 (alpha power vs age, Figs 3-4).
%   1. Reproduction: given the same 19 subjects and 10-15.5 yr axis as the
%      saved May outputs, subject alpha power and window means match exactly.
%   2. Correctness: every window's 95% CI contains its own estimate. (The
%      original code failed this: its CIs used the wrong subjects' draws.)
%   3. The default run (get_cohort(), shared age range) writes its figures.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    paths = setup_project();

    refDir = fullfile(paths.referenceOutputsDir, 'outputs');
    may3 = fullfile(refDir, 'mfdb_alpha_power_vs_age', ...
        'mfdb_alpha_f3_10.0_to_15.5_sevo_mean_sliding_hw2.00_step0.50');
    may4 = fullfile(refDir, 'mfdb_alpha_power_difference_vs_age', ...
        'mfdb_alpha_difference_f3_10.0_to_15.5_sevo_mean_stationary_hw0.50_step0.50');
    validationFile = fullfile(refDir, 'mfdb_validation', 'mfdb_validation_results.mat');
    assumeTrue(testCase, isfile([may3 '_results.csv']) && isfile(validationFile), ...
        'Reference outputs not configured; skipped.');

    mayIDs = readtable([may3 '_results.csv'], 'TextType', 'string').SubjectID;
    base = struct('validationFile', validationFile);

    % May reproduction runs
    opts = base;  opts.subjectIDs = mayIDs;  opts.ageRange = [10 15.5];
    opts.outDir = make_temp(testCase);
    evalc('o3 = plot_mfdb_alpha_power_vs_age(opts);');  close all;
    opts.outDir = make_temp(testCase);
    evalc('o4 = plot_mfdb_alpha_power_difference_vs_age(opts);');  close all;

    % Default runs: current cohort and shared age range
    opts = base;  opts.outDir = make_temp(testCase);
    evalc('d3 = plot_mfdb_alpha_power_vs_age(opts);');  close all;
    opts.outDir = make_temp(testCase);
    evalc('d4 = plot_mfdb_alpha_power_difference_vs_age(opts);');  close all;

    td = struct();
    td.subj3 = readtable(fullfile(o3.outDir, [o3.plotFileBase '_results.csv']), 'TextType', 'string');
    td.win3 = readtable(fullfile(o3.outDir, [o3.plotFileBase '_window_support.csv']));
    td.win4 = readtable(fullfile(o4.outDir, [o4.plotFileBase '_window_difference_summary.csv']));
    td.maySubj3 = readtable([may3 '_results.csv'], 'TextType', 'string');
    td.mayWin3 = readtable([may3 '_window_support.csv']);
    td.mayWin4 = readtable([may4 '_window_difference_summary.csv']);
    td.def3 = d3;  td.def4 = d4;
    td.defWin3 = readtable(fullfile(d3.outDir, [d3.plotFileBase '_window_support.csv']));
    td.defWin4 = readtable(fullfile(d4.outDir, [d4.plotFileBase '_window_difference_summary.csv']));
    td.defSubj3 = readtable(fullfile(d3.outDir, [d3.plotFileBase '_results.csv']), 'TextType', 'string');
    testCase.TestData = td;
end

function testSubjectAlphaPowerMatchesMay(testCase)
    new = sortrows(testCase.TestData.subj3, 'SubjectID');
    ref = sortrows(testCase.TestData.maySubj3, 'SubjectID');
    verifyEqual(testCase, new.SubjectID, ref.SubjectID);
    verifyEqual(testCase, new.AlphaPower_dB, ref.AlphaPower_dB, 'AbsTol', 1e-9);
    verifyEqual(testCase, new.AgeYears, ref.AgeYears, 'AbsTol', 1e-9);
end

function testWindowEstimatesMatchMay(testCase)
    w3 = testCase.TestData.win3;  m3 = testCase.TestData.mayWin3;
    verifyEqual(testCase, w3.ControlSummary_dB, m3.ControlSummary_dB, 'AbsTol', 1e-9);
    verifyEqual(testCase, w3.PatientSummary_dB, m3.PatientSummary_dB, 'AbsTol', 1e-9);
    w4 = testCase.TestData.win4;  m4 = testCase.TestData.mayWin4;
    verifyEqual(testCase, w4.DifferenceSummary_dB, m4.DifferenceSummary_dB, 'AbsTol', 1e-9);
end

function testCIsContainTheirEstimates(testCase)
    for w = {testCase.TestData.win3, testCase.TestData.defWin3}
        t = w{1};
        verify_inside(testCase, t.ControlSummary_dB, t.ControlCILow_dB, t.ControlCIHigh_dB, 'Fig 3 control');
        verify_inside(testCase, t.PatientSummary_dB, t.PatientCILow_dB, t.PatientCIHigh_dB, 'Fig 3 CP');
    end
    for w = {testCase.TestData.win4, testCase.TestData.defWin4}
        t = w{1};
        verify_inside(testCase, t.DifferenceSummary_dB, t.DifferenceCILow_dB, t.DifferenceCIHigh_dB, 'Fig 4 difference');
    end
end

function testDefaultRunUsesCurrentCohort(testCase)
    ids = testCase.TestData.defSubj3.SubjectID;
    cohort = get_cohort();
    verifyEqual(testCase, sort(ids), sort(cohort.subjectID));
    for o = {testCase.TestData.def3, testCase.TestData.def4}
        verifyNotEmpty(testCase, dir(fullfile(o{1}.outDir, '*.png')), 'figures written');
    end
end

function verify_inside(testCase, est, lo, hi, label)
    ok = ~isnan(est);
    inside = est(ok) >= lo(ok) & est(ok) <= hi(ok);
    verifyTrue(testCase, all(inside), sprintf('%s: %d of %d CIs miss their estimate', ...
        label, sum(~inside), numel(inside)));
end

function d = make_temp(testCase)
    d = tempname;
    mkdir(d);
    testCase.addTeardown(@() rmdir(d, 's'));
end
