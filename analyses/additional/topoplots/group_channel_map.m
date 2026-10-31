function M = group_channel_map(T, valueColumn, opts)
%GROUP_CHANNEL_MAP Group medians and CP - Control difference at each channel.
%   M = GROUP_CHANNEL_MAP(T, valueColumn, opts) keeps a channel only if it is usable
%   in at least opts.minChildren children of each group and is not in
%   opts.excludeChannels. Children without a usable value there are left out of that
%   channel's median. M has columns channel, CP, Control, difference, nCP, nControl.
    keep = T.isUsable & ~ismember(lower(T.channel), lower(string(opts.excludeChannels)));
    T = T(keep, :);
    channels = unique(T.channel, 'stable');
    M = table(channels, 'VariableNames', {'channel'});
    M.CP = nan(height(M), 1);  M.Control = M.CP;  M.nCP = zeros(height(M), 1);  M.nControl = M.nCP;
    for c = 1:height(M)
        here = T.channel == channels(c);
        cp = T.(valueColumn)(here & T.groupLabel == "CP");
        control = T.(valueColumn)(here & T.groupLabel == "Control");
        M.CP(c) = median(cp);  M.Control(c) = median(control);
        M.nCP(c) = numel(cp);  M.nControl(c) = numel(control);
    end
    M = M(M.nCP >= opts.minChildren & M.nControl >= opts.minChildren, :);
    M.difference = M.CP - M.Control;
end
