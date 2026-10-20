function tests = test_coherence_state_space
%TEST_COHERENCE_STATE_SPACE The coherence state-space analysis runs and is internally consistent.
%   - Uses the coherence cohort (get_cohort() with F4).
%   - Band coherence reproduces stage 05's per-child alpha value (8-13 Hz).
%   - Fisher z round-trips: tanh(atanh(C)) = C.
%   - FixedHeuristicQ converges for every band. Needs run_all.m sections 1-5.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    p = setup_project();
    assumeTrue(testCase, isfolder(fullfile(p.outputsDir, 'coherence_subject_level')), ...
        'Run run_all.m first; skipped.');
    addpath(fullfile(repoRoot, 'analyses', 'additional', 'coherence_state_space'));
    evalc('testCase.TestData.out = run_coherence_state_space();');
    close all;
    testCase.TestData.outputsDir = p.outputsDir;
end

function testCohort(testCase)
    T = testCase.TestData.out.table;
    cohort = get_cohort();
    verifyEqual(testCase, sort(T.subjectID), sort(cohort.subjectID(cohort.hasF4)));
end

function testBandCoherenceMatchesStage05(testCase)
    T = testCase.TestData.out.table;
    id = char(T.subjectID(1));
    S = load(fullfile(testCase.TestData.outputsDir, 'coherence_subject_level', id, [id '_F3F4_coherence.mat']), ...
        'freq', 'coherence_subject', 'alphaCoherenceMean');
    mask = S.freq >= 8 & S.freq <= 13;
    verifyEqual(testCase, mean(S.coherence_subject(mask)), S.alphaCoherenceMean, 'AbsTol', 1e-12);
    verifyEqual(testCase, tanh(T.alpha_z), T.alpha_coherence, 'AbsTol', 1e-12);
end

function testFitsConvergedAndFiguresWritten(testCase)
    outDir = testCase.TestData.out.outDir;
    for band = ["delta", "theta", "alpha"]
        S = readtable(fullfile(outDir, sprintf('coherence_ssm_%s_summary.csv', band)), 'TextType', 'string');
        verifyEqual(testCase, S.converged(S.versionName == "FixedHeuristicQ"), 1, band);
    end
    verifyTrue(testCase, isfile(fullfile(outDir, 'coherence_state_space_all_bands.png')));
    for band = ["delta", "theta", "alpha"]
        verifyTrue(testCase, isfile(fullfile(outDir, "coherence_ssm_" + band + "_control_vs_cp.png")), band);
        verifyTrue(testCase, isfile(fullfile(outDir, "coherence_ssm_" + band + "_gap.png")), band);
    end
end

function testCounterpartFigures(testCase)
    % Coherograms (Figs 02-03 counterpart) and alpha coherence vs age
    evalc('o = make_coherence_counterparts();');
    close all;
    for name = ["coherograms.png", "coherogram_control.png", "coherogram_cp.png", "alpha_coherence_vs_age.png"]
        verifyTrue(testCase, isfile(fullfile(o.outDir, name)), name);
    end
    cohort = get_cohort();
    verifyEqual(testCase, sum(o.nControl) + sum(o.nCP) > 0, true);
    verifyLessThan(testCase, o.pGroup, 1);
    verifyEqual(testCase, numel(o.effectCI_z), 2);
    verifyEqual(testCase, sum(cohort.hasF4), 23);
end

function testSmoothnessGridForCoherence(testCase)
    % The power smoothness grid, run on coherence: published setting matches the stage fit
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(fullfile(repoRoot, 'analyses', 'additional', 'ssm_smoothness_grid'));
    evalc('o = run_ssm_smoothness_grid("alpha", "coherence");');
    close all;
    G = readtable(fullfile(o.outDir, 'grid.csv'));
    cell = G(G.qF0_multiplier == 1 & G.qDelta_multiplier == 1, :);
    pub = readtable(fullfile(testCase.TestData.out.outDir, 'coherence_ssm_alpha_summary.csv'), 'TextType', 'string');
    pub = pub(pub.versionName == "FixedHeuristicQ", :);
    verifyEqual(testCase, cell.r, pub.r, 'RelTol', 1e-3);
    verifyEqual(testCase, cell.logLik, pub.logLikelihood, 'AbsTol', 1e-3);
end
