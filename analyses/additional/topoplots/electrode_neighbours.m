function neighbours = electrode_neighbours(chanlocs)
%ELECTRODE_NEIGHBOURS Which drawn electrodes count as neighbours for the cluster test.
%   Two electrodes are neighbours if they share an edge of a Delaunay triangulation of
%   the cap, flattened from above. Edges longer than 1.5 x the median edge are dropped,
%   so electrodes on opposite sides of an area with no drawn electrode are not joined,
%   unless that would leave an electrode with no neighbour; then it keeps its shortest edge.
    n = numel(chanlocs);
    if n < 3, neighbours = ~eye(n); return; end
    xyz = [[chanlocs.X]' [chanlocs.Y]' [chanlocs.Z]'];
    xy = [xyz(:, 2) xyz(:, 1)] ./ vecnorm(xyz, 2, 2);
    tri = delaunay(xy(:, 1), xy(:, 2));
    edges = unique(sort([tri(:, [1 2]); tri(:, [2 3]); tri(:, [1 3])], 2), 'rows');
    len = vecnorm(xy(edges(:, 1), :) - xy(edges(:, 2), :), 2, 2);
    keep = len <= 1.5 * median(len);
    for i = setdiff(1:numel(chanlocs), unique(edges(keep, :)))
        mine = find(any(edges == i, 2));
        [~, k] = min(len(mine));
        keep(mine(k)) = true;
    end
    edges = edges(keep, :);
    neighbours = false(n);
    neighbours(sub2ind([n n], edges(:, 1), edges(:, 2))) = true;
    neighbours = neighbours | neighbours';
end
