function result = spatial_cluster_test(groupA, groupB, neighbours, opts)
%SPATIAL_CLUSTER_TEST Which groups of neighbouring electrodes differ between two groups of subjects?
%   result = SPATIAL_CLUSTER_TEST(groupA, groupB, neighbours) is cluster_permutation_test.m
%   with electrodes in place of frequencies (Maris & Oostenveld, 2007). groupA and groupB
%   have one row per subject and one column per electrode; NaN means that electrode is
%   not usable for that subject. neighbours is a logical electrodes x electrodes matrix.
%
%   1. At each electrode, a Welch t statistic for A - B (subjects with NaN left out).
%   2. Neighbouring electrodes with |t| above the cluster-forming threshold and the same
%      sign form a cluster; its "mass" is the sum of |t|.
%   3. Shuffle group labels many times; each shuffle records its largest cluster mass.
%      A real cluster's p-value is the share of shuffles whose largest cluster is at
%      least as big. This controls false positives across all electrodes at once.
%
%   opts (all optional): clusterAlpha (0.05), nPermutations (5000),
%   seed (mfdb_config().randomSeed).
%
%   result.t        - observed t at each electrode
%   result.clusters - table: electrodes (indices), nElectrodes, sign (+1: A > B), mass, p

    if nargin < 4, opts = struct(); end
    clusterAlpha = get_opt(opts, 'clusterAlpha', 0.05);
    nPerm = get_opt(opts, 'nPermutations', 5000);
    seed = get_opt(opts, 'seed', []);
    if isempty(seed), seed = mfdb_config().randomSeed; end

    data = [groupA; groupB];
    isA = [true(size(groupA, 1), 1); false(size(groupB, 1), 1)];
    % Same conservative threshold as cluster_permutation_test: df = min(nA, nB) - 1
    tThreshold = tinv(1 - clusterAlpha / 2, min(size(groupA, 1), size(groupB, 1)) - 1);

    tObs = welch_t(data(isA, :), data(~isA, :));
    observed = find_clusters(tObs, tThreshold, neighbours);

    rng(seed);
    maxNullMass = zeros(nPerm, 1);
    for k = 1:nPerm
        shuffled = isA(randperm(numel(isA)));
        c = find_clusters(welch_t(data(shuffled, :), data(~shuffled, :)), tThreshold, neighbours);
        if ~isempty(c.mass), maxNullMass(k) = max(c.mass); end
    end
    p = arrayfun(@(m) (1 + sum(maxNullMass >= m)) / (nPerm + 1), observed.mass(:));

    result = struct();
    result.t = tObs;
    result.tThreshold = tThreshold;
    result.clusters = table(observed.electrodes(:), cellfun(@numel, observed.electrodes(:)), ...
        observed.sign(:), observed.mass(:), p, ...
        'VariableNames', {'electrodes', 'nElectrodes', 'sign', 'mass', 'p'});
    result.clusters = sortrows(result.clusters, 'p');
    result.nPermutations = nPerm;
end

function t = welch_t(A, B)
    nA = sum(~isnan(A), 1);
    nB = sum(~isnan(B), 1);
    se = sqrt(var(A, 0, 1, 'omitnan') ./ nA + var(B, 0, 1, 'omitnan') ./ nB);
    t = (mean(A, 1, 'omitnan') - mean(B, 1, 'omitnan')) ./ max(se, eps);
end

function c = find_clusters(t, threshold, neighbours)
    c = struct('electrodes', {{}}, 'sign', [], 'mass', []);
    for s = [1 -1]
        above = find(s * t > threshold);
        if isempty(above), continue; end
        bins = conncomp(graph(neighbours(above, above)));
        for b = 1:max(bins)
            members = above(bins == b);
            c.electrodes{end + 1} = members;
            c.sign(end + 1) = s;
            c.mass(end + 1) = sum(abs(t(members)));
        end
    end
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
