function tests = test_global_coherence
%TEST_GLOBAL_COHERENCE Checks the Cornelissen 2018 global coherence on simulated data.
    tests = functiontests(localfunctions);
end

function setupOnce(~)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    addpath(fullfile(repoRoot, 'analyses', 'additional', 'global_coherence'));
end

function testSharedSourceGivesHighGCOnItsChannels(testCase)
    % A 10 Hz rhythm shared by channels 1-5 on top of independent noise: GC is high at 10 Hz,
    % near the noise level elsewhere, and the leading eigenvector sits on channels 1-5.
    rng(1);  Fs = 256;  t = (0:120 * Fs - 1)' / Fs;  nChan = 20;
    data = randn(numel(t), nChan);
    data(:, 1:5) = data(:, 1:5) + 3 * sin(2 * pi * 10 * t + 0.3);
    R = global_coherence_cornelissen(data, Fs, gc_settings());
    verifyEqual(testCase, size(R.gc, 1), 6);              % 60 windows of 2 s, blocks of 10
    gc = mean(R.gc, 1);
    verifyGreaterThan(testCase, gc(R.freq == 10), 0.9);
    verifyLessThan(testCase, gc(R.freq == 20), 0.25);
    w = mean(abs(R.u(:, R.freq == 10, :)).^2, 3);
    verifyGreaterThan(testCase, sum(w(1:5)), 0.99);
end

function testWeightsSumToOne(testCase)
    rng(2);  R = global_coherence_cornelissen(randn(256 * 40, 8), 256, gc_settings());
    verifyEqual(testCase, squeeze(sum(abs(R.u).^2, 1)), ones(numel(R.freq), size(R.u, 3)), 'AbsTol', 1e-10);
    verifyTrue(testCase, all(R.gc(:) >= 1 / 8 - 1e-12 & R.gc(:) <= 1));
end

function testBlockMedianIsEntrywise(testCase)
    % With one window per block there is no median, so each block's matrix is that window's
    % multitaper cross-spectral matrix: compare GC with a direct computation.
    rng(3);  Fs = 256;  data = randn(Fs * 2, 4);  s = gc_settings();  s.blockWindows = 1;
    R = global_coherence_cornelissen(data, Fs, s);
    tapers = dpss(2 * Fs, s.TW, s.K);  seg = detrend(data);  f = find(R.freq == 10);
    C = zeros(4);
    for k = 1:s.K, X = fft(seg .* tapers(:, k));  x = X(f, :).';  C = C + x * x' / s.K; end
    e = eig((C + C') / 2);
    verifyEqual(testCase, R.gc(1, f), max(e) / sum(e), 'AbsTol', 1e-10);
end
