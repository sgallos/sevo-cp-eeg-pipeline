function [W, G, spectra] = load_child_gc(cohort)
%LOAD_CHILD_GC Global coherence for every child, computed once and reused.
%   Reads outputs/additional/global_coherence/child_gc.mat unless it is missing, misses a
%   child, or is older than the data or the code and settings that make it.
%   The electrodes are those the topoplots draw (topoplot_channel_rules.m).
    outDir = fullfile(project_paths().outputsDir, 'additional', 'global_coherence');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    file = fullfile(outDir, 'child_gc.mat');
    sources = [string(cohort.dataFile(:)); string(which('compute_child_gc')); string(which('gc_settings')); ...
        string(which('global_coherence_cornelissen')); string(which('state_space_bands')); ...
        string(which('topoplot_channel_rules')); string(which('excluded_channels'))];
    if isfile(file)
        newest = max(arrayfun(@(f) dir(f).datenum, sources));
        if dir(file).datenum > newest
            S = load(file);
            if all(ismember(string(cohort.subjectID), S.G.subjectID))
                W = S.W;  G = S.G;  spectra = S.spectra;
                return;
            end
        end
    end
    B = load_channel_band_power(cohort);
    channels = group_channel_map(B, 'alpha', topoplot_channel_rules()).channel;
    [W, G, spectra] = compute_child_gc(cohort, channels);
    save(file, 'W', 'G', 'spectra');
    writetable(G, fullfile(outDir, 'child_gc.csv'));
end
