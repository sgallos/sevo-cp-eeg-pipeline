function mask_unmeasured_area(ax)
%MASK_UNMEASURED_AREA Blank the parts of a topoplot that have no electrode nearby.
%   Removes colour further from the nearest drawn electrode than 1.5 times the median
%   spacing between electrodes, so the map shows no value that was only extrapolated.
    electrodes = findobj(ax, 'Type', 'line', 'Marker', '.');
    points = [electrodes(1).XData(:), electrodes(1).YData(:)];
    gaps = pdist2(points, points);
    gaps(gaps == 0) = inf;
    spacing = median(min(gaps, [], 2));
    map = findobj(ax, 'Type', 'surface');
    [X, Y] = deal(map(1).XData, map(1).YData);
    nearest = reshape(min(pdist2([X(:), Y(:)], points), [], 2), size(X));
    colours = map(1).CData;
    colours(nearest > 1.5 * spacing) = NaN;
    map(1).CData = colours;
end
