function R = global_coherence_cornelissen(data, Fs, s)
%GLOBAL_COHERENCE_CORNELISSEN Global coherence and leading eigenvector, Cornelissen et al. 2018.
%   R = GLOBAL_COHERENCE_CORNELISSEN(data, Fs, s) with data samples x channels and s from
%   gc_settings. Each non-overlapping window (s.windowSec) is linearly detrended and gives a
%   multitaper cross-spectral matrix, C(f) = mean over tapers of x_k(f) x_k(f)^H. Windows are
%   taken in consecutive blocks of s.blockWindows; within a block the real and imaginary parts
%   of every entry are replaced by their medians. At each frequency and block:
%     gc = largest / sum of the singular values (= eigenvalues; see below)
%     u  = leading singular vector (= leading eigenvector)
%   Windows left over after the last full block are not used.
%   An entry-wise median of Hermitian matrices is Hermitian but need not be positive
%   semi-definite, so a few eigenvalues can be slightly negative. The published code
%   (GlobalCoherence.m, Cornelissen et al. 2015) uses svd, whose singular values are the
%   absolute eigenvalues; this does the same and reports the share of negative eigenvalue
%   mass in R.negativeShare so it can be checked.
%   R has freq (Hz), gc (blocks x freq), u (channels x freq x blocks) and negativeShare
%   (blocks x freq).
    [nSamples, nChan] = size(data);
    nWin = round(s.windowSec * Fs);
    tapers = dpss(nWin, s.TW, s.K);
    freq = (0:nWin - 1)' * Fs / nWin;
    keep = find(freq <= s.maxHz);
    freq = freq(keep);  nF = numel(keep);

    nWindows = floor(nSamples / nWin);
    nBlocks = floor(nWindows / s.blockWindows);
    C = complex(zeros(nChan, nChan, nF, nBlocks * s.blockWindows));
    for w = 1:nBlocks * s.blockWindows
        seg = detrend(data((w - 1) * nWin + (1:nWin), :));
        for k = 1:s.K
            X = fft(seg .* tapers(:, k));          % nWin x nChan
            X = X(keep, :).';                      % nChan x nF
            for f = 1:nF
                C(:, :, f, w) = C(:, :, f, w) + X(:, f) * X(:, f)' / s.K;
            end
        end
    end

    gc = nan(nBlocks, nF);  negativeShare = gc;  u = nan(nChan, nF, nBlocks);
    for b = 1:nBlocks
        w = (b - 1) * s.blockWindows + (1:s.blockWindows);
        M = median(real(C(:, :, :, w)), 4) + 1i * median(imag(C(:, :, :, w)), 4);
        for f = 1:nF
            A = (M(:, :, f) + M(:, :, f)') / 2;    % exactly Hermitian (removes rounding)
            [U, S] = svd(A);
            sv = diag(S);
            gc(b, f) = sv(1) / sum(sv);
            u(:, f, b) = U(:, 1);
            e = eig(A);
            negativeShare(b, f) = sum(abs(e(e < 0))) / sum(abs(e));
        end
    end
    R = struct('freq', freq, 'gc', gc, 'u', u, 'negativeShare', negativeShare, ...
        'nWindowsUsed', nBlocks * s.blockWindows, 'nWindows', nWindows);
end
