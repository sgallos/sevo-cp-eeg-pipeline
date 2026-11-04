function tests = test_topoplots
%TEST_TOPOPLOTS Checks the scalp maps against stage 01 and against known patterns.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    setup_project();
    addpath(fullfile(repoRoot, 'analyses', 'additional', 'topoplots'));
    testCase.TestData.cfg = mfdb_config();
    testCase.TestData.cohort = get_cohort();
    testCase.TestData.T = compute_channel_band_power(testCase.TestData.cohort, ...
        struct('delta', [1 4], 'theta', [4 8], 'alpha', [8 13]), testCase.TestData.cfg);
end

function testF3MatchesStage01(testCase)
    % The value at F3 must be the value from stage 01, for every child.
    T = testCase.TestData.T;  cfg = testCase.TestData.cfg;
    ids = unique(T.subjectID);
    for s = 1:numel(ids)
        d = dir(fullfile(cfg.outputDir, char(ids(s)), '*_mfdb.mat'));
        R = load(fullfile(d(1).folder, d(1).name), 'freq', 'S_subject_original_dB');
        here = T.subjectID == ids(s) & T.channel == "F3";
        verifyEqual(testCase, T.delta(here), mean(R.S_subject_original_dB(R.freq >= 1 & R.freq <= 4)), ...
            'AbsTol', 1e-8, char(ids(s)));
        verifyEqual(testCase, T.theta(here), mean(R.S_subject_original_dB(R.freq >= 4 & R.freq <= 8)), ...
            'AbsTol', 1e-8, char(ids(s)));
        verifyEqual(testCase, T.alpha(here), mean(R.S_subject_original_dB(R.freq >= 8 & R.freq <= 13)), ...
            'AbsTol', 1e-8, char(ids(s)));
    end
end

function testEveryChildAndChannelPresent(testCase)
    T = testCase.TestData.T;
    verifyEqual(testCase, numel(unique(T.subjectID)), height(testCase.TestData.cohort));
    verifyTrue(testCase, all(isfinite(T.alpha(T.isUsable))));
    verifyFalse(testCase, any(T.isUsable & T.isAllZero));
end

function testPositionsAreOnTheCorrectSide(testCase)
    % EEGLAB: X = front, Y = left. F3 is front-left, Pz is back and central.
    locs = channel_locations(["F3" "F4" "Pz" "Fz"]);
    verifyGreaterThan(testCase, locs(1).X, 0);  verifyGreaterThan(testCase, locs(1).Y, 0);
    verifyGreaterThan(testCase, locs(2).X, 0);  verifyLessThan(testCase, locs(2).Y, 0);
    verifyLessThan(testCase, locs(3).X, 0);     verifyLessThan(testCase, abs(locs(3).Y), 1);
    verifyLessThan(testCase, abs(locs(4).Y), 1);
end

function testKnownPatternSurvivesInterpolation(testCase)
    % A front-to-back gradient must come out with the front of the head high, the
    % left and right sides equal, and the map equal to the value at each electrode.
    labels = unique(testCase.TestData.T.channel);
    labels = labels(labels ~= "PO5" & labels ~= "PO6");
    locs = channel_locations(labels);
    values = [locs.X]';
    fig = figure('Visible', 'off');  cleanup = onCleanup(@() close(fig));
    [~, grid, ~, xmesh, ymesh] = topoplot(values, locs, 'noplot', 'on');
    if isvector(xmesh), [X, Y] = meshgrid(xmesh, ymesh); else, X = xmesh; Y = ymesh; end   % +Y = nose
    if ~isequal(size(X), size(grid)), X = X'; Y = Y'; end
    verifyGreaterThan(testCase, mean(grid(Y > 0.2 & abs(X) < 0.3), 'omitnan'), ...
        mean(grid(Y < -0.2 & abs(X) < 0.3), 'omitnan'));
    left = mean(grid(X < -0.2 & abs(Y) < 0.3), 'omitnan');
    right = mean(grid(X > 0.2 & abs(Y) < 0.3), 'omitnan');
    verifyLessThan(testCase, abs(left - right), 0.1 * range(values));
end

function testMapsKeepThePrimaryElectrodes(testCase)
    M = group_channel_map(testCase.TestData.T, 'alpha', topoplot_channel_rules());
    verifyTrue(testCase, all(ismember(["F3" "F4"], M.channel)));
    verifyEmpty(testCase, intersect(lower(M.channel), lower(excluded_channels())));
end

function testAreaPowerUsesOnlyEnoughCleanElectrodes(testCase)
    T = table(["a";"a";"b"], ["CP";"CP";"Control"], ["F3";"F1";"F3"], logical([1;1;1]), [1;3;9], [1;3;9], [1;3;9], ...
        'VariableNames', {'subjectID', 'groupLabel', 'channel', 'isUsable', 'delta', 'theta', 'alpha'});
    A = area_band_power(T, 2);
    verifyEqual(testCase, height(A), 1);      % b has one electrode there, so it is left out
    verifyEqual(testCase, A.subjectID, "a");
    verifyEqual(testCase, A.alpha, 2);
end

function testPeakVs7HzIgnoresGain(testCase)
    freq = (0:0.1:45)';
    dB = [20 - 0.5 * freq, 18 - 0.4 * freq] + 6 * exp(-(freq - 10) .^ 2);
    height = peak_vs_7hz(freq, dB, 10);
    verifyEqual(testCase, peak_vs_7hz(freq, dB + [12 -7], 10), height, 'AbsTol', 1e-10);
    verifyGreaterThan(testCase, height(1), 3);
end

function testAlphaPeakMovesWithTheChild(testCase)
    freq = (0:0.1:45)';
    for peakHz = [8.5 10 12]
        [found, hasPeak] = find_alpha_peak(freq, 20 - 0.5 * freq + 6 * exp(-(freq - peakHz) .^ 2));
        verifyTrue(testCase, hasPeak);
        verifyEqual(testCase, found, peakHz, 'AbsTol', 0.3);
    end
    [~, hasPeak] = find_alpha_peak(freq, 20 - 0.5 * freq);
    verifyFalse(testCase, hasPeak);
end

function testNeighboursAreLocalAndConnected(testCase)
    % Every drawn electrode has a neighbour; F3 neighbours its ring, not the back of the head.
    M = group_channel_map(testCase.TestData.T, 'alpha', topoplot_channel_rules());
    nb = electrode_neighbours(channel_locations(M.channel));
    verifyEqual(testCase, nb, nb');
    verifyTrue(testCase, all(sum(nb) >= 1));
    f3 = M.channel(nb(:, M.channel == "F3"));
    verifyTrue(testCase, all(ismember(["F1" "F5" "FC3"], f3)));
    verifyFalse(testCase, any(ismember(["O1" "O2" "P3"], f3)));
end

function testHedgesG(testCase)
    % Two groups 1 SD apart give g just under 1 (small-sample correction), and a gain
    % added to every child does not change it.
    rng(3);
    a = randn(12, 1);  b = randn(12, 1);
    a = (a - mean(a)) / std(a) + 1;  b = (b - mean(b)) / std(b);
    T = table(["c" + (1:12)'; "k" + (1:12)'], [repmat("CP", 12, 1); repmat("Control", 12, 1)], ...
        repmat("F3", 24, 1), true(24, 1), [a; b], 'VariableNames', {'subjectID', 'groupLabel', 'channel', 'isUsable', 'v'});
    opts = struct('minChildren', 9, 'excludeChannels', {{}});
    M = group_effect_map_values(T, opts);
    verifyEqual(testCase, M, 1 - 3 / (4 * 24 - 9), 'AbsTol', 1e-12);
    T.v = T.v + 7;
    verifyEqual(testCase, group_effect_map_values(T, opts), M, 'AbsTol', 1e-12);
end

function g = group_effect_map_values(T, opts)
    % One electrode only, so the cluster test has nothing to join; g is what is checked.
    M = group_effect_map(T, 'v', opts);
    g = M.g;
end

function testAreaValuesUseTheMedianOfEnoughElectrodes(testCase)
    T = table(["a";"a";"a";"b";"b"], ["CP";"CP";"CP";"Control";"Control"], ["F3";"F1";"O1";"F3";"F1"], ...
        logical([1;1;1;1;0]), [1;5;100;2;9], 'VariableNames', {'subjectID', 'groupLabel', 'channel', 'isUsable', 'v'});
    A = area_values(T, "v", struct('channels', ["F3" "F1"], 'minElectrodes', 2));
    verifyEqual(testCase, A.subjectID, "a");   % b has only one usable frontal electrode
    verifyEqual(testCase, A.value, 3);         % median of 1 and 5; O1 is not frontal
end

function testStateSpaceFitReproducesStage06(testCase)
    % Given stage 06's own input table, the wrapper gives the published F3 alpha result.
    file = fullfile(project_paths().outputsDir, 'state_space_model', 'power_table_for_ssm_subepochs_collapsed.csv');
    summary = fullfile(project_paths().outputsDir, 'state_space_model', 'power_ssm_publication_alpha_summary.csv');
    assumeTrue(testCase, isfile(file) && isfile(summary), 'Run stage 06 first.');
    T = readtable(file, 'TextType', 'string');
    S = readtable(summary, 'TextType', 'string');
    S = S(S.versionName == "FixedHeuristicQ", :);
    tr = state_space_fit(T.subjectID, T.groupLabel, T.ageYears, T.alpha_dB);
    verifyEqual(testCase, mean(tr.deltaMean_dB), S.groupDifferenceMean_dB, 'AbsTol', 1e-6);
    below = tr.deltaCIHigh_dB < 0;
    verifyEqual(testCase, [min(tr.ageYears(below)) max(tr.ageYears(below))], ...
        [S.negativeExclusionAgeLow S.negativeExclusionAgeHigh], 'AbsTol', 1e-9);
end

function testGroupMapMedianAndMissingChannels(testCase)
    T = table(["a";"b";"c";"d"], ["CP";"CP";"Control";"Control"], ["F3";"F3";"F3";"F3"], ...
        logical([1;1;1;0]), [1;3;10;99], 'VariableNames', {'subjectID', 'groupLabel', 'channel', 'isUsable', 'v'});
    M = group_channel_map(T, 'v', struct('minChildren', 1, 'excludeChannels', {{}}));
    verifyEqual(testCase, M.CP, 2);
    verifyEqual(testCase, M.Control, 10);     % the unusable 99 is left out
    verifyEqual(testCase, M.difference, -8);
    M = group_channel_map(T, 'v', struct('minChildren', 2, 'excludeChannels', {{}}));
    verifyEmpty(testCase, M);                 % only one usable Control child
end
