function T = load_channel_band_power(cohort)
%LOAD_CHANNEL_BAND_POWER Delta, theta and alpha power at every channel, computed once.
%   Reads the saved table unless it is missing, misses a child, or is older than the
%   data, the settings or the code that computes it.
    cfg = mfdb_config();
    outDir = fullfile(project_paths().outputsDir, 'additional', 'topoplots');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    file = fullfile(outDir, 'channel_band_power.csv');

    sources = [string(cohort.dataFile(:)); string(which('compute_channel_band_power')); ...
        string(which('mfdb_config')); string(which('state_space_bands'))];
    if isfile(file)
        saved = dir(file);
        newest = max(arrayfun(@(f) dir(f).datenum, sources));
        T = readtable(file, 'TextType', 'string');
        if saved.datenum > newest && all(ismember(string(cohort.subjectID), T.subjectID))
            T = T(ismember(T.subjectID, string(cohort.subjectID)), :);
            T.isUsable = logical(T.isUsable);
            return;
        end
    end
    edges = state_space_bands();
    bands = struct();
    for b = 1:numel(edges), bands.(edges(b).name) = [edges(b).lowHz edges(b).highHz]; end
    T = compute_channel_band_power(cohort, bands, cfg);
    writetable(T, file);
end
