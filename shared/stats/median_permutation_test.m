function out = median_permutation_test(groupA, groupB, opts)
%MEDIAN_PERMUTATION_TEST Do two groups of subjects differ in their medians?
%   out = MEDIAN_PERMUTATION_TEST(groupA, groupB) takes one value per subject in each
%   group and returns the difference of medians, median(A) - median(B), with:
%     p  - shuffles the group labels; the share of shuffles whose difference is at least
%          as far from 0 as the observed one (two-sided), as (1 + count) / (nPermutations + 1)
%     ci - 95% CI that resamples subjects within each group (subject_bootstrap_ci)
%
%   opts (all optional): nPermutations (10000), B (10000), seed (mfdb_config().randomSeed).
    if nargin < 3, opts = struct(); end
    nPerm = get_opt(opts, 'nPermutations', 10000);
    seed = get_opt(opts, 'seed', []);
    if isempty(seed), seed = mfdb_config().randomSeed; end
    a = groupA(~isnan(groupA));  b = groupB(~isnan(groupB));
    a = a(:);  b = b(:);

    observed = median(a) - median(b);
    pooled = [a; b];
    n = numel(a);
    rng(seed);
    null = zeros(nPerm, 1);
    for k = 1:nPerm
        s = pooled(randperm(numel(pooled)));
        null(k) = median(s(1:n)) - median(s(n + 1:end));
    end
    boot = subject_bootstrap_ci(a, b, struct('statFn', @median, 'B', get_opt(opts, 'B', 10000), 'seed', seed));

    out = struct('difference', observed, 'p', (1 + sum(abs(null) >= abs(observed))) / (nPerm + 1), ...
        'ci', boot.ciDifference(:)', 'medianA', median(a), 'medianB', median(b), 'nA', numel(a), 'nB', numel(b));
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
