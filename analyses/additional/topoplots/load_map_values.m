function T = load_map_values(cohort)
%LOAD_MAP_VALUES Every per-electrode value the topoplots use, one row per child and channel.
%   delta, theta and alpha band power; peakVs7 and peakHz; and, when specparam_fits.csv
%   exists, alpha height, exponent and offset for each fit range (e.g. alphaHeight_main).
%   Reuses the saved tables; see load_channel_band_power and load_channel_peak_power.
    T = load_channel_peak_power(cohort);
    B = load_channel_band_power(cohort);
    T = outerjoin(T, B(:, {'subjectID', 'channel', 'delta', 'theta'}), ...
        'Keys', {'subjectID', 'channel'}, 'MergeKeys', true, 'Type', 'left');
    file = fullfile(project_paths().outputsDir, 'additional', 'topoplots', 'specparam_fits.csv');
    if ~isfile(file), return; end
    F = readtable(file, 'TextType', 'string');
    for range = unique(F.fitRange)'
        G = F(F.fitRange == range, {'subjectID', 'channel', 'alphaHeight', 'exponent', 'offset'});
        G.Properties.VariableNames(3:5) = cellstr(["alphaHeight" "exponent" "offset"] + "_" + range);
        T = outerjoin(T, G, 'Keys', {'subjectID', 'channel'}, 'MergeKeys', true, 'Type', 'left');
    end
end
