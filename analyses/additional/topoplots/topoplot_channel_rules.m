function opts = topoplot_channel_rules()
%TOPOPLOT_CHANNEL_RULES The rules for which electrodes and children the scalp maps use.
%   An electrode is drawn if it is clean in at least minChildren of the 12 children of
%   each group. A child gets a by-age map with at least minElectrodes of those electrodes.
%   These rules apply to the maps only; the primary analyses keep every child.
    opts = struct('minChildren', 9, 'minElectrodes', 24, 'excludeChannels', excluded_channels());
end
