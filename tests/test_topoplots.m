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
        struct('alpha', [8 13]), testCase.TestData.cfg);
end

function testF3MatchesStage01(testCase)
    % The value at F3 must be the value from stage 01, for every child.
    T = testCase.TestData.T;  cfg = testCase.TestData.cfg;
    ids = unique(T.subjectID);
    for s = 1:numel(ids)
        d = dir(fullfile(cfg.outputDir, char(ids(s)), '*_mfdb.mat'));
        R = load(fullfile(d(1).folder, d(1).name), 'freq', 'S_subject_original_dB');
        expected = mean(R.S_subject_original_dB(R.freq >= 8 & R.freq <= 13));
        verifyEqual(testCase, T.alpha(T.subjectID == ids(s) & T.channel == "F3"), expected, ...
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
