function c = group_colors()
%GROUP_COLORS The one colour scheme for every figure: Control = blue, CP = red.
%   line  - curves and dots
%   fill  - shaded bands drawn with transparency (FaceAlpha)
%   light - opaque pale version, for CI patches drawn without transparency
    c.controlLine = [0.00 0.38 0.95];
    c.controlFill = [0.22 0.62 1.00];
    c.cpLine = [0.92 0.02 0.08];
    c.cpFill = [1.00 0.30 0.36];
    c.controlLight = 0.4 * c.controlLine + 0.6;   % 60% blended with white
    c.cpLight = 0.4 * c.cpLine + 0.6;
end
