function [M, clusters] = group_effect_map(T, valueColumn, opts)
%GROUP_EFFECT_MAP Group medians, effect size and spatial cluster test at each drawn electrode.
%   [M, clusters] = GROUP_EFFECT_MAP(T, valueColumn, opts) adds to group_channel_map:
%     g         Hedges' g, CP - Control: the mean difference divided by the pooled standard
%               deviation between children, with the small-sample correction
%     t         Welch t at each electrode
%     inCluster true where the electrode is in a cluster with p < 0.05
%   clusters is the cluster table of spatial_cluster_test (5,000 shuffles, repo seed).
    M = group_channel_map(T, valueColumn, opts);
    U = T(T.isUsable & ismember(T.channel, M.channel) & ~isnan(T.(valueColumn)), :);
    ids = unique(U.subjectID);
    X = nan(numel(ids), height(M));
    [~, row] = ismember(U.subjectID, ids);
    [~, col] = ismember(U.channel, M.channel);
    X(sub2ind(size(X), row, col)) = U.(valueColumn);
    group = arrayfun(@(i) U.groupLabel(find(U.subjectID == i, 1)), ids);
    cp = X(group == "CP", :);
    control = X(group == "Control", :);

    nCP = sum(~isnan(cp));  nControl = sum(~isnan(control));
    pooledSD = sqrt(((nCP - 1) .* var(cp, 0, 'omitnan') + (nControl - 1) .* var(control, 0, 'omitnan')) ...
        ./ (nCP + nControl - 2));
    correction = 1 - 3 ./ (4 * (nCP + nControl) - 9);
    M.g = ((mean(cp, 'omitnan') - mean(control, 'omitnan')) ./ pooledSD .* correction)';

    result = spatial_cluster_test(cp, control, electrode_neighbours(channel_locations(M.channel)));
    M.t = result.t';
    clusters = result.clusters;
    M.inCluster = false(height(M), 1);
    significant = clusters.electrodes(clusters.p < 0.05);
    M.inCluster([significant{:}]) = true;
end
