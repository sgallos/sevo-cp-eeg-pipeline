function A = area_values(T, valueColumn, area)
%AREA_VALUES One value per child for an area: the median over its usable electrodes there.
%   A has subjectID, groupLabel, value and nElectrodes. Children with fewer than
%   area.minElectrodes usable electrodes in the area are left out.
    U = T(T.isUsable & ismember(T.channel, area.channels) & ~isnan(T.(valueColumn)), :);
    [ids, ~, which] = unique(U.subjectID);
    value = accumarray(which, U.(valueColumn), [], @median);
    nElectrodes = accumarray(which, 1);
    groupLabel = arrayfun(@(i) U.groupLabel(find(U.subjectID == i, 1)), ids);
    A = table(ids, groupLabel, value, nElectrodes, ...
        'VariableNames', {'subjectID', 'groupLabel', 'value', 'nElectrodes'});
    A = A(A.nElectrodes >= area.minElectrodes, :);
end
