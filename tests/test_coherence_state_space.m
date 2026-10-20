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
end
