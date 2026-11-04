function A = area_band_power(T, minElectrodes)
%AREA_BAND_POWER Each child's mean power in each scalp area, one row per child and area.
%   A child counts in an area only with at least minElectrodes clean electrodes there,
%   and stays in the other areas otherwise. Values are the mean dB over those electrodes.
    T = T(T.isUsable & ~ismember(lower(T.channel), lower(excluded_channels())), :);
    areas = scalp_areas();
    edges = state_space_bands();
    rows = cell(numel(areas), 1);
    for a = 1:numel(areas)
        here = T(ismember(T.channel, areas(a).channels), :);
        if isempty(here), continue; end
        [which, subjectID, groupLabel] = findgroups(here.subjectID, here.groupLabel);
        row = table(subjectID, groupLabel);
        row.area = repmat(areas(a).name, height(row), 1);
        row.nElectrodes = splitapply(@numel, here.channel, which);
        for b = 1:numel(edges)
            name = char(edges(b).name);
            row.(name) = splitapply(@mean, here.(name), which);
        end
        rows{a} = row(row.nElectrodes >= minElectrodes, :);
    end
    A = vertcat(rows{:});
end
