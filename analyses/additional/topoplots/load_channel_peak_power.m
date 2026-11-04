function T = load_channel_peak_power(cohort)
%LOAD_CHANNEL_PEAK_POWER Alpha peak vs 7 Hz at every channel, from the saved spectra.
%   T has one row per child and channel: subjectID, groupLabel, channel, isUsable, alpha
%   (absolute, dB), peakHz, hasPeak, peakVs7. The child's peak comes from the median
%   spectrum of its usable electrodes of the group maps.
    B = load_channel_band_power(cohort);
    excluded = lower(excluded_channels());
    spectra = load_channel_spectra(cohort);
    rows = cell(numel(spectra), 1);
    for s = 1:numel(spectra)
        here = B(B.subjectID == string(spectra(s).subjectID), :);
        [~, where] = ismember(spectra(s).channel, here.channel);
        row = here(where, {'subjectID', 'groupLabel', 'channel', 'isUsable', 'alpha'});
        clean = row.isUsable & ~ismember(lower(row.channel), excluded);
        [peakHz, hasPeak] = find_alpha_peak(spectra(s).freq, median(spectra(s).dB(:, clean), 2));
        row.peakHz(:) = peakHz;
        row.hasPeak(:) = hasPeak;
        row.peakVs7 = peak_vs_7hz(spectra(s).freq, spectra(s).dB, peakHz);
        rows{s} = row;
    end
    T = vertcat(rows{:});
end
