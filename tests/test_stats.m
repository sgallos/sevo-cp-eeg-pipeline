function tests = test_stats
%TEST_STATS The subject-level statistics behave correctly on simulated data.
%   Synthetic "subjects" where the right answer is known:
%   - no true difference  -> the cluster test rarely finds one (about 5% of the time)
%   - a planted difference -> it finds it, in the right place
%   - the same for the spatial (electrode) cluster test
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

function testSpatialClusterTestFindsPlantedEffect(testCase)
    % 36 electrodes on a 6 x 6 grid; CP is planted 1.5 SD lower on a 3 x 3 patch.
    rng(21);
    nb = grid_neighbours(6);
    A = randn(12, 36);  B = randn(12, 36);
    patch = reshape(false(6), 1, []);  patch(sub2ind([6 6], [2 2 2 3 3 3 4 4 4], [2 3 4 2 3 4 2 3 4])) = true;
    A(:, patch) = A(:, patch) - 1.5;
    A(3, 5) = NaN;                       % one unusable electrode in one child
    r = spatial_cluster_test(A, B, nb, struct('nPermutations', 1000, 'seed', 1));
    top = r.clusters(1, :);
    verifyLessThan(testCase, top.p, 0.05);
    verifyEqual(testCase, top.sign, -1);
    verifyTrue(testCase, all(patch(top.electrodes{1})));
end

function testSpatialClusterTestFalsePositiveRate(testCase)
    % 200 datasets with NO true difference: about 5% should show any cluster p < 0.05.
    nb = grid_neighbours(6);
    hits = 0;  nSims = 200;
    for s = 1:nSims
        rng(3000 + s);
        A = randn(12, 36) + movmean(randn(12, 36), 3, 2);
        B = randn(12, 36) + movmean(randn(12, 36), 3, 2);
        r = spatial_cluster_test(A, B, nb, struct('nPermutations', 300, 'seed', s));
        hits = hits + any(r.clusters.p < 0.05);
    end
    rate = hits / nSims;
    fprintf('Spatial cluster test false-positive rate under the null: %.3f (target 0.05)\n', rate);
    verifyLessThan(testCase, rate, 0.10);
end

function testMedianPermutationTest(testCase)
    % No difference: about 5% of datasets give p < 0.05. A 1.5 SD shift is found, and its
    % CI contains the true difference.
    hits = 0;  nSims = 200;
    for s = 1:nSims
        rng(4000 + s);
        r = median_permutation_test(randn(12, 1), randn(12, 1), struct('nPermutations', 500, 'B', 200, 'seed', s));
        hits = hits + (r.p < 0.05);
    end
    rate = hits / nSims;
    fprintf('Median permutation test false-positive rate under the null: %.3f (target 0.05)\n', rate);
    verifyLessThan(testCase, rate, 0.10);
    rng(5);
    r = median_permutation_test(randn(12, 1) - 1.5, randn(12, 1), struct('nPermutations', 2000, 'B', 2000, 'seed', 1));
    verifyLessThan(testCase, r.p, 0.05);
    verifyLessThan(testCase, r.ci(1), -1.5);
    verifyGreaterThan(testCase, r.ci(2), -1.5);
end

function testBenjaminiHochberg(testCase)
    % Worked example: p = 0.01, 0.04, 0.03, 0.20 with m = 4 gives
    % sorted 0.01, 0.03, 0.04, 0.20 -> x m/k = 0.04, 0.06, 0.0533, 0.20 -> running min from the top.
    q = benjamini_hochberg([0.01 0.04 0.03 0.20]);
    verifyEqual(testCase, q, [0.04 0.16/3 0.16/3 0.20], 'AbsTol', 1e-12);
    verifyEqual(testCase, benjamini_hochberg([0.5 NaN]), [0.5 NaN]);
end

function nb = grid_neighbours(n)
    % Electrodes on an n x n grid; neighbours share a side.
    [r, c] = ndgrid(1:n);
    d = abs(r(:) - r(:)') + abs(c(:) - c(:)');
    nb = d == 1;
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
