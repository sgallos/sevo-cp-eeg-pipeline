function tests = test_ssm_smoothness_grid
%TEST_SSM_SMOOTHNESS_GRID The smoothness grid agrees with stage 06 where they overlap.
%   At the published smoothness (q = default) the directly maximized r and the
%   log-likelihood must equal the published EM fit. Needs run_all.m sections 1-6.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    p = setup_project();
    published = fullfile(state_space_outputs_dir(), 'power_ssm_publication_alpha_summary.csv');
    assumeTrue(testCase, isfile(published), 'Run run_all.m (stage 06) first; skipped.');
    addpath(fullfile(repoRoot, 'analyses', 'additional', 'ssm_smoothness_grid'));
    evalc('testCase.TestData.out = run_ssm_smoothness_grid("alpha");');
    close all;
    testCase.TestData.published = readtable(published, 'TextType', 'string');
    testCase.TestData.grid = readtable(fullfile(testCase.TestData.out.outDir, 'grid.csv'));
    testCase.TestData.outputsDir = p.outputsDir;
end

function testPublishedCellMatchesStage06(testCase)
    G = testCase.TestData.grid;
    cell = G(G.qF0_multiplier == 1 & G.qDelta_multiplier == 1, :);
    pub = testCase.TestData.published(testCase.TestData.published.versionName == "FixedHeuristicQ", :);
    verifyEqual(testCase, cell.r, pub.r, 'RelTol', 1e-4);
    verifyEqual(testCase, cell.logLik, pub.logLikelihood, 'AbsTol', 1e-4);
end

function testGridIsComplete(testCase)
    G = testCase.TestData.grid;
    verifyEqual(testCase, height(G), 100);
    verifyTrue(testCase, all(isfinite(G.logLik)));
    verifyTrue(testCase, any(G.supported));
end

function testFigureWritten(testCase)
    verifyTrue(testCase, isfile(fullfile(testCase.TestData.out.outDir, 'smoothness_grid.png')));
end
