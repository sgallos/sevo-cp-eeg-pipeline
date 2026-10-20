function result = cluster_permutation_test(groupA, groupB, x, opts)
%CLUSTER_PERMUTATION_TEST Which frequency ranges differ between two groups of subjects?
%   result = CLUSTER_PERMUTATION_TEST(groupA, groupB, x) compares two groups
%   (one row per subject, one column per frequency x) and controls false
%   positives across ALL frequencies at once (Maris & Oostenveld, 2007).
%
%   1. At each frequency, a Welch t statistic for A - B.
%   2. Neighbouring frequencies with |t| above the cluster-forming threshold
%      (and the same sign) form a cluster; its "mass" is the sum of |t|.
%   3. Shuffle group labels many times; each shuffle records its largest
%      cluster mass. A real cluster's p-value is the share of shuffles whose
%      largest cluster is at least as big.
%   Because each subject is one row, the subject is the unit of analysis.
%
%   opts (all optional):
%     clusterAlpha - pointwise threshold that forms clusters (default 0.05)
%     nPermutations - default 5000
%     seed          - default mfdb_config().randomSeed
%     transform     - function applied to the data first, e.g. @atanh for
%                     coherence (default: none)
%
%   result.t        - observed t at each x
%   result.clusters - table: xLow, xHigh, nPoints, sign (+1: A > B), mass, p

    if nargin < 4, opts = struct(); end
    clusterAlpha = get_opt(opts, 'clusterAlpha', 0.05);
    nPerm = get_opt(opts, 'nPermutations', 5000);
    seed = get_opt(opts, 'seed', []);
    transform = get_opt(opts, 'transform', []);
    if isempty(seed)
        cfg = mfdb_config();
        seed = cfg.randomSeed;
    end
    if ~isempty(transform)
        groupA = transform(groupA);
        groupB = transform(groupB);
    end

    x = x(:).';
    data = [groupA; groupB];
    isA = [true(size(groupA, 1), 1); false(size(groupB, 1), 1)];
    nA = size(groupA, 1);
    nB = size(groupB, 1);
    % Threshold from the t distribution with Welch-Satterthwaite-free
    % conservative df = min(nA, nB) - 1.
    tThreshold = tinv(1 - clusterAlpha / 2, min(nA, nB) - 1);

    tObs = welch_t(data(isA, :), data(~isA, :));
    observed = find_clusters(tObs, tThreshold);

    rng(seed);
    maxNullMass = zeros(nPerm, 1);
    for k = 1:nPerm
        shuffled = isA(randperm(numel(isA)));
        tNull = welch_t(data(shuffled, :), data(~shuffled, :));
        nullClusters = find_clusters(tNull, tThreshold);
        if ~isempty(nullClusters.mass)
            maxNullMass(k) = max(nullClusters.mass);
        end
    end

    nClusters = numel(observed.mass);
    p = zeros(nClusters, 1);
    for c = 1:nClusters
        p(c) = (1 + sum(maxNullMass >= observed.mass(c))) / (nPerm + 1);
    end

    result = struct();
    result.x = x;
    result.t = tObs;
    result.tThreshold = tThreshold;
    result.clusters = table(x(observed.first(:)).', x(observed.last(:)).', ...
        (observed.last(:) - observed.first(:) + 1), observed.sign(:), observed.mass(:), p, ...
        'VariableNames', {'xLow', 'xHigh', 'nPoints', 'sign', 'mass', 'p'});
    result.clusters = sortrows(result.clusters, 'p');
    result.nPermutations = nPerm;
    result.nA = nA;
    result.nB = nB;
end

function t = welch_t(A, B)
    nA = size(A, 1);
    nB = size(B, 1);
    se = sqrt(var(A, 0, 1) / nA + var(B, 0, 1) / nB);
    t = (mean(A, 1) - mean(B, 1)) ./ max(se, eps);
end

function c = find_clusters(t, threshold)
    c = struct('first', [], 'last', [], 'sign', [], 'mass', []);
    for s = [1 -1]
        above = s * t > threshold;
        edges = diff([false, above, false]);
        firsts = find(edges == 1);
        lasts = find(edges == -1) - 1;
        for k = 1:numel(firsts)
            c.first(end + 1) = firsts(k);
            c.last(end + 1) = lasts(k);
            c.sign(end + 1) = s;
            c.mass(end + 1) = sum(abs(t(firsts(k):lasts(k))));
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
