function [ciLow, ciHigh, nA, nB] = two_stage_window_ci(agesA, bootA, agesB, bootB, centers, halfWidth, opts)
%TWO_STAGE_WINDOW_CI 95% CIs per age window from a two-stage bootstrap.
%   Each draw (1) resamples the CHILDREN in the window with replacement, then
%   (2) gives every resampled child one value from that child's own MFDB
%   bootstrap. The CI therefore covers child-to-child spread (stage 1) and
%   each child's spectral-estimation uncertainty (stage 2).
%
%   agesA, bootA - ages and per-child bootstrap values (cell array) of group A
%   agesB, bootB - the same for group B, or [] for a one-group CI
%   With group B, the CI is for summary(A) - summary(B).
%
%   opts (all optional):
%     statFn     - window summary across children (default @mean)
%     B          - number of draws (default 2000)
%     minN       - fewer children than this in a group: no CI (default 3)
%     seed       - random seed (default mfdb_config().randomSeed)
%
%   Returns NaN CIs for windows where a group has fewer than minN children.

    if nargin < 7, opts = struct(); end
    statFn = get_opt(opts, 'statFn', @mean);
    B = get_opt(opts, 'B', 2000);
    minN = get_opt(opts, 'minN', 3);
    seed = get_opt(opts, 'seed', []);
    if isempty(seed)
        seed = mfdb_config().randomSeed;
    end
    twoGroups = ~isempty(agesB);

    rng(seed);
    nW = numel(centers);
    [ciLow, ciHigh] = deal(nan(nW, 1));
    [nA, nB] = deal(zeros(nW, 1));
    for w = 1:nW
        inA = find(abs(agesA(:) - centers(w)) <= halfWidth);
        nA(w) = numel(inA);
        inB = [];
        if twoGroups
            inB = find(abs(agesB(:) - centers(w)) <= halfWidth);
            nB(w) = numel(inB);
        end
        if nA(w) < minN || (twoGroups && nB(w) < minN)
            continue;
        end
        draws = zeros(B, 1);
        for b = 1:B
            draws(b) = statFn(draw_group(bootA(inA)));
            if twoGroups
                draws(b) = draws(b) - statFn(draw_group(bootB(inB)));
            end
        end
        ciLow(w) = prctile(draws, 2.5);
        ciHigh(w) = prctile(draws, 97.5);
    end
end

function vals = draw_group(boots)
    % Stage 1: resample children; stage 2: one MFDB value per resampled child
    pick = randi(numel(boots), numel(boots), 1);
    vals = zeros(numel(pick), 1);
    for k = 1:numel(pick)
        thisBoot = boots{pick(k)};
        vals(k) = thisBoot(randi(numel(thisBoot)));
    end
end

function value = get_opt(opts, name, defaultValue)
    if isfield(opts, name) && ~isempty(opts.(name))
        value = opts.(name);
    else
        value = defaultValue;
    end
end
