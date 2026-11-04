function labels = excluded_channels()
%EXCLUDED_CHANNELS Channels left out of every scalp map; see README.md.
%   CP1: its montage entry lists CP2 instead of CPz. FT7: about 15 dB above the rest at
%   every frequency in every child who has it. F7, FC5, T7: they list FT7 as a Laplacian
%   neighbour, so they carry a quarter of it.
    labels = ["CP1" "FT7" "F7" "FC5" "T7"];
end
