function bands = state_space_bands(version)
%STATE_SPACE_BANDS Delta, theta and alpha band edges for the stage 02 power table and
%   the state-space model (Figs 05-06). Alpha is 8-13 Hz, as in every other figure.
%
%   STATE_SPACE_BANDS("original") returns the edges the original analysis used
%   (alpha 8-12 Hz). Only the reproduction tests use it, to compare against the
%   saved original outputs.
    if nargin < 1, version = "current"; end
    alphaHighHz = 13;
    if version == "original", alphaHighHz = 12; end
    bands = struct( ...
        'name',   {"delta", "theta", "alpha"}, ...
        'lowHz',  {1, 4, 8}, ...
        'highHz', {4, 8, alphaHighHz}, ...
        'column', {"delta_dB", "theta_dB", "alpha_dB"});
end
