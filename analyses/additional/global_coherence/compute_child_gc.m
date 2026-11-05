function [W, G, spectra] = compute_child_gc(cohort, channels)
%COMPUTE_CHILD_GC Global coherence and spatial coherence for every child.
%   [W, G, spectra] = COMPUTE_CHILD_GC(cohort, channels). Each child's GC uses the electrodes
%   in channels that are clean in that child (the electrodes the topoplots draw), on the
%   stage 01 epoch (120 s, Laplacian, 256 Hz). Settings from gc_settings.m; bands from
%   state_space_bands.m.
%     W        one row per child and electrode: spatial coherence |u_1|^2 per band, the mean
%              over the band's frequencies and the blocks (columns delta, theta, alpha)
%     G        one row per child: age, number of electrodes, band GC (gc_delta, ...), the
%              mean over the band's frequencies and the blocks, and the largest
%              negative-eigenvalue share in 0.5-30 Hz
%     spectra  freq and gc (children x freq, the mean over blocks)
    s = gc_settings();
    edges = state_space_bands();
    B = load_channel_band_power(cohort);         % which channels are clean in each child
    rowsW = cell(height(cohort), 1);  rowsG = cell(height(cohort), 1);  gcSpec = [];
    for i = 1:height(cohort)
        id = string(cohort.subjectID(i));
        D = load(cohort.dataFile(i));
        data = double(D.data);
        if size(data, 1) < size(data, 2), data = data'; end
        labels = string(D.HDR.label(:));
        clean = B.channel(B.subjectID == id & B.isUsable);
        use = find(ismember(labels, channels) & ismember(labels, clean));
        R = global_coherence_cornelissen(data(:, use), D.HDR.frequency(1), s);
        gcChild = mean(R.gc, 1);
        weight = mean(abs(R.u).^2, 3);             % channels x freq
        row = table(repmat(id, numel(use), 1), repmat(string(cohort.groupLabel(i)), numel(use), 1), ...
            labels(use), true(numel(use), 1), 'VariableNames', {'subjectID', 'groupLabel', 'channel', 'isUsable'});
        g = table(id, string(cohort.groupLabel(i)), cohort.ageYears(i), numel(use), R.nWindowsUsed, ...
            'VariableNames', {'subjectID', 'groupLabel', 'ageYears', 'nElectrodes', 'nWindowsUsed'});
        for b = 1:numel(edges)
            in = R.freq >= edges(b).lowHz & R.freq <= edges(b).highHz;
            row.(edges(b).name) = mean(weight(:, in), 2);
            g.("gc_" + edges(b).name) = mean(gcChild(in));
        end
        g.maxNegativeShare = max(R.negativeShare(:, R.freq >= 0.5), [], 'all');
        rowsW{i} = row;  rowsG{i} = g;  gcSpec(i, :) = gcChild; %#ok<AGROW>
        fprintf('%s: %d electrodes, %d windows, alpha GC %.3f\n', id, numel(use), R.nWindowsUsed, g.gc_alpha);
    end
    W = vertcat(rowsW{:});  G = vertcat(rowsG{:});
    spectra = struct('freq', R.freq, 'gc', gcSpec, 'subjectID', G.subjectID);
end
