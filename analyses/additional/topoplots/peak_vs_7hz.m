function height = peak_vs_7hz(freq, dB, peakHz)
%PEAK_VS_7HZ The child's alpha peak relative to 7 Hz at each channel, in dB.
%   height = PEAK_VS_7HZ(freq, dB, peakHz) takes spectra in dB (frequencies x channels).
%   Each point is the mean dB within 0.5 Hz, and 7 Hz is the dip below alpha in these
%   spectra; see README.md. A gain on a channel cancels.
    point = @(hz) mean(dB(abs(freq - hz) <= 0.5, :), 1)';
    height = point(peakHz) - point(7);
end
