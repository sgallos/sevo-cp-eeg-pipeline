function spectra = load_channel_spectra(cohort)
%LOAD_CHANNEL_SPECTRA Spectrum of every channel of every child up to 45 Hz, computed once.
%   spectra has one row per child: subjectID, channel (labels), freq (Hz), dB (frequencies
%   x channels). Uses the spectrum of stage 01 (mtm, cfg.TW, cfg.K, the 120 s epoch). Reads
%   the saved file unless it is missing, misses a child, or is older than the data, the
%   settings or this code.
    maxFrequency = 45;
    cfg = mfdb_config();
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    file = fullfile(outDir, 'channel_spectra.mat');

    sources = [string(cohort.dataFile(:)); string(which('load_channel_spectra')); string(which('mfdb_config'))];
    if isfile(file)
        saved = dir(file);
        newest = max(arrayfun(@(f) dir(f).datenum, sources));
        S = load(file, 'spectra');
        if saved.datenum > newest && all(ismember(string(cohort.subjectID), string({S.spectra.subjectID})))
            spectra = S.spectra(ismember(string({S.spectra.subjectID}), string(cohort.subjectID)));
            return;
        end
    end

    spectra = struct('subjectID', {}, 'channel', {}, 'freq', {}, 'dB', {});
    for s = 1:height(cohort)
        D = load(cohort.dataFile(s));
        data = D.data;
        if size(data, 1) < size(data, 2), data = data'; end   % samples x channels
        Fs = D.HDR.frequency(1);
        for c = size(data, 2):-1:1
            [P, F] = mtm(data(:, c), cfg.TW, cfg.K, Fs, cfg.method);
            half = 1:(size(P, 1) / 2);
            keep = F(half) <= maxFrequency;
            dB(:, c) = 10 * log10(max(P(half(keep), 1), eps));
        end
        spectra(s).subjectID = char(string(cohort.subjectID(s)));
        spectra(s).channel = string(D.HDR.label(:));
        spectra(s).freq = F(half(keep));
        spectra(s).dB = dB;
        clear dB
    end
    save(file, 'spectra');
end
