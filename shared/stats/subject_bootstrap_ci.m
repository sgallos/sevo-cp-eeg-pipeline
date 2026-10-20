function out = subject_bootstrap_ci(groupA, groupB, opts)
%SUBJECT_BOOTSTRAP_CI Confidence intervals that resample SUBJECTS (children).
%   out = SUBJECT_BOOTSTRAP_CI(groupA, groupB) takes one row per subject
%   (columns = frequencies, age windows, ... anything) and returns 95% CIs for
%   each group's summary and for the difference summary(A) - summary(B).
%
%   Each bootstrap draw picks subjects WITH replacement within each group,
%   so the CI answers: "how much would this change with a different sample
%   of children?" That is the question a CP-vs-control claim needs.
%
%   opts (all optional):
%     statFn - summary across subjects, e.g. @median (default) or @mean
%     B      - number of bootstrap draws (default 2000)
%     alpha  - 0.05 for 95% CIs (default)
%     seed   - random seed (default: mfdb_config().randomSeed)
%
%   out fields: estimateA, estimateB, difference, ciA, ciB, ciDifference
%   (each CI is 2 x nColumns: [low; high]).

    if nargin < 3, opts = struct(); end
    statFn = get_opt(opts, 'statFn', @median);
    B = get_opt(opts, 'B', 2000);
    alpha = get_opt(opts, 'alpha', 0.05);
    seed = get_opt(opts, 'seed', []);
    if isempty(seed)
        cfg = mfdb_config();
        seed = cfg.randomSeed;
    end

    summarize = @(X) statFn(X, 1, 'omitnan');
    nA = size(groupA, 1);
    nB = size(groupB, 1);

    out = struct();
    out.estimateA = summarize(groupA);
    out.estimateB = summarize(groupB);
    out.difference = out.estimateA - out.estimateB;

    rng(seed);
    bootA = zeros(B, size(groupA, 2));
    bootB = zeros(B, size(groupB, 2));
    for b = 1:B
        bootA(b, :) = summarize(groupA(randi(nA, nA, 1), :));
        bootB(b, :) = summarize(groupB(randi(nB, nB, 1), :));
    end

    pct = 100 * [alpha / 2, 1 - alpha / 2];
    out.ciA = prctile(bootA, pct, 1);
    out.ciB = prctile(bootB, pct, 1);
    out.ciDifference = prctile(bootA - bootB, pct, 1);
    out.nA = nA;
    out.nB = nB;
    out.B = B;
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
