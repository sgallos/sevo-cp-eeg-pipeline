function tests = test_stats
%TEST_STATS The subject-level statistics behave correctly on simulated data.
%   Synthetic "subjects" where the right answer is known:
%   - no true difference  -> the cluster test rarely finds one (about 5% of the time)
%   - a planted difference -> it finds it, in the right place
%   - the subject bootstrap 95% CI covers the true difference about 95% of the time
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    setup_project();
end

function testClusterTestFindsPlantedEffect(testCase)
    rng(11);
    x = 1:100;
    A = randn(12, 100) + smooth_noise(12, 100);
    B = randn(12, 100) + smooth_noise(12, 100);
    A(:, 40:60) = A(:, 40:60) + 2.5;   % planted effect at 40-60
    r = cluster_permutation_test(A, B, x, struct('nPermutations', 1000, 'seed', 1));
    verifyNotEmpty(testCase, r.clusters);
    top = r.clusters(1, :);
    verifyLessThan(testCase, top.p, 0.01);
    verifyEqual(testCase, top.sign, 1);
    verifyGreaterThanOrEqual(testCase, top.xLow, 35);
    verifyLessThanOrEqual(testCase, top.xHigh, 65);
end

function testClusterTestFalsePositiveRate(testCase)
    % 200 datasets with NO true difference: about 5% should show any cluster p < 0.05.
    nSims = 200;
    hits = 0;
    for s = 1:nSims
        rng(1000 + s);
        A = randn(12, 60) + smooth_noise(12, 60);
        B = randn(12, 60) + smooth_noise(12, 60);
        r = cluster_permutation_test(A, B, 1:60, struct('nPermutations', 300, 'seed', s));
        hits = hits + any(r.clusters.p < 0.05);
    end
    rate = hits / nSims;
    fprintf('Cluster test false-positive rate under the null: %.3f (target 0.05)\n', rate);
    verifyLessThan(testCase, rate, 0.10);
end

function testSubjectBootstrapCoverage(testCase)
    % True difference = 1. A 95% CI should contain it in roughly 95% of datasets.
    nSims = 300;
    covered = 0;
    for s = 1:nSims
        rng(2000 + s);
        A = 1 + randn(12, 1);
        B = randn(12, 1);
        out = subject_bootstrap_ci(A, B, struct('statFn', @mean, 'B', 1000, 'seed', s));
        covered = covered + (out.ciDifference(1) <= 1 && 1 <= out.ciDifference(2));
    end
    coverage = covered / nSims;
    fprintf('Subject bootstrap 95%% CI coverage: %.3f (target 0.95)\n', coverage);
    % Percentile bootstrap with n = 12 per group runs slightly below nominal.
    verifyGreaterThan(testCase, coverage, 0.88);
    verifyLessThan(testCase, coverage, 0.99);
end

function noise = smooth_noise(n, m)
    % Correlated across neighbouring columns, like adjacent frequency bins.
    noise = movmean(randn(n, m), 7, 2) * 2;
end
