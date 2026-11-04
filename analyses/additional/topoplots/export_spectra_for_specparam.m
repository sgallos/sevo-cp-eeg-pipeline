function outFile = export_spectra_for_specparam(cohort)
%EXPORT_SPECTRA_FOR_SPECPARAM Write spectra in 0.25 Hz bins for fit_specparam.py.
%   Linear power is averaged in each bin, because the 120 s spectra are too finely
%   resolved for peak fitting. One row per child and channel; usable channels only.
    binHz = 0.25;
    centres = binHz:binHz:45;
    B = load_channel_band_power(cohort);
    spectra = load_channel_spectra(cohort);
    rows = cell(numel(spectra), 1);
    for s = 1:numel(spectra)
        id = string(spectra(s).subjectID);
        here = B(B.subjectID == id & B.isUsable, :);
        keep = find(ismember(spectra(s).channel, here.channel));
        [~, bin] = min(abs(spectra(s).freq(:) - centres), [], 2);
        power = 10 .^ (spectra(s).dB(:, keep) / 10);
        binned = zeros(numel(centres), numel(keep));
        for b = 1:numel(centres), binned(b, :) = mean(power(bin == b, :), 1); end
        row = array2table(binned', 'VariableNames', compose('f%g', centres));
        row = [table(repmat(id, numel(keep), 1), spectra(s).channel(keep), 'VariableNames', {'subjectID', 'channel'}), row];
        rows{s} = row;
    end
    outFile = fullfile(project_paths().outputsDir, 'additional', 'topoplots', 'spectra_for_specparam.csv');
    writetable(vertcat(rows{:}), outFile);
end
