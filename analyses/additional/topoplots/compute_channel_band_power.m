function T = compute_channel_band_power(cohort, bands, cfg)
%COMPUTE_CHANNEL_BAND_POWER Band power at every channel, one row per child and channel.
%   T = COMPUTE_CHANNEL_BAND_POWER(cohort, bands, cfg) uses the spectrum of stage 01
%   (mtm, cfg.TW, cfg.K, the 120 s epoch) at every channel, so the value at F3 is the
%   value in the F3 analyses. bands is a struct of [low high] ranges in Hz. T has one
%   column per band, in dB, the mean of the dB spectrum over the band, plus
%     nNeighbours - neighbours the Laplacian used, from the file's tooFewNeighbors record
%     isUsable    - false if the channel is all zeros or has too few neighbours
    bandNames = fieldnames(bands);
    rows = cell(height(cohort), 1);
    for s = 1:height(cohort)
        D = load(cohort.dataFile(s));
        data = D.data;
        if size(data, 1) < size(data, 2), data = data'; end   % samples x channels
        labels = string(D.HDR.label(:));
        Fs = D.HDR.frequency(1);
        nChan = numel(labels);

        tooFew = strings(0, 1);  tooFewCount = zeros(0, 1);
        if isfield(D, 'tooFewNeighbors') && ~isempty(D.tooFewNeighbors)
            tooFew = string(cellfun(@(c) c{1}, D.tooFewNeighbors, 'UniformOutput', false))';
            tooFewCount = cellfun(@(c) c{2}, D.tooFewNeighbors)';
        end
        isValid = true(nChan, 1);
        if isfield(D, 'valid_channels'), isValid = logical(D.valid_channels(:)); end

        power = nan(nChan, numel(bandNames));
        for c = 1:nChan
            [S, F] = mtm(data(:, c), cfg.TW, cfg.K, Fs, cfg.method);
            half = 1:(size(S, 1) / 2);
            dB = 10 * log10(max(S(half, 1), eps));
            for b = 1:numel(bandNames)
                range = bands.(bandNames{b});
                power(c, b) = mean(dB(F(half) >= range(1) & F(half) <= range(2)));
            end
        end

        row = table(repmat(string(cohort.subjectID(s)), nChan, 1), ...
            repmat(string(cohort.groupLabel(s)), nChan, 1), labels, ...
            'VariableNames', {'subjectID', 'groupLabel', 'channel'});
        row.isAllZero = all(data == 0, 1)';
        row.isValid = isValid;
        row.nNeighbours = nan(nChan, 1);
        [isFew, where] = ismember(labels, tooFew);
        row.nNeighbours(isFew) = tooFewCount(where(isFew));
        row.isUsable = isValid & ~row.isAllZero;
        for b = 1:numel(bandNames)
            row.(bandNames{b}) = power(:, b);
        end
        rows{s} = row;
    end
    T = vertcat(rows{:});
end
