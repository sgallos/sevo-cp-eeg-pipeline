function s = gc_settings()
%GC_SETTINGS Global coherence settings, following Cornelissen et al. 2018 (Br J Anaesth 120:1274).
%   Their Methods: non-overlapping 2 s windows; the cross-spectral matrix in each window; the
%   median over 10 windows of the real and of the imaginary part of every entry, "to remove
%   the noise artefact"; then an eigendecomposition at each frequency. Global coherence is
%   the largest eigenvalue over the sum of eigenvalues (Cimenser et al. 2011). Spatial
%   coherence at an electrode is |u_1|^2, the squared magnitude of its entry in the leading
%   eigenvector, averaged over the band; group maps are medians across children.
%   The tapers (TW 2, K 3) are those of their published code (Cornelissen et al. 2015,
%   eLife, Source code 1), since the 2018 paper does not state them.
    s = struct( ...
        'windowSec', 2, ...        % non-overlapping windows
        'TW', 2, 'K', 3, ...       % multitaper settings for each 2 s window
        'blockWindows', 10, ...    % median over this many windows per entry
        'maxHz', 30);              % highest frequency kept
end
