function out = make_candidate_gallery(measureName)
%MAKE_CANDIDATE_GALLERY Published and wobbliest state-space fits, side by side.
%   For each band (delta, theta, alpha), refits the stage 06 model at:
%     1. Published   - FixedHeuristicQ, q_f0 = q_delta = default (Figs 05-06)
%     2. Wobbliest   - the most wobbly gap still inside the supported region
%                      (within 3 log-lik units of the best grid cell)
%   Each panel title states the settings and how well it fits.
%   Needs run_all_bands.m (reads each band's grid.csv).
%   Writes outputs/additional/ssm_smoothness_grid/gallery_<band>.png.
%   make_candidate_gallery("coherence") does the same for F3-F4 coherence.

    if nargin < 1, measureName = "power"; end
    M = ssm_measure(measureName);
    gridDir = M.outRoot;
    raw = readtable(M.inputTable, 'TextType', 'string');
    bands = state_space_bands();
    out = struct();

    for b = 1:numel(bands)
        band = bands(b);
        T = table(string(raw.subjectID), string(raw.groupLabel), double(raw.ageYears), ...
            double(raw.(M.column(band))), zeros(height(raw), 1), ...
            'VariableNames', {'subjectID', 'groupLabel', 'ageYears', 'alpha_dB', 'mfdb_var'});
        G = readtable(fullfile(gridDir, band.name, 'grid.csv'));
        qInit = G.qF0(1) / G.qF0_multiplier(1);
        bestLogLik = max(G.logLik);
        supported = G(G.supported == 1, :);
        [~, k] = max(supported.wobble_dB);
        wobbly = supported(k, :);

        versions = {
            'Published (FixedHeuristicQ)', qInit, qInit, struct()
            'Wobbliest still supported', wobbly.qF0, wobbly.qDelta, struct()};

        fig = figure('Color', 'w', 'Position', [60 60 1200 900]);
        tl = tiledlayout(fig, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
        title(tl, sprintf('%s%s band (%g-%g Hz): published vs wobbliest supported state-space fit, %d children', M.titlePrefix, ...
            title_case(band.name), band.lowHz, band.highHz, height(T)), 'FontWeight', 'bold', 'FontSize', 15);
        rows = table();
        for v = 1:size(versions, 1)
            fit = fit_version(T, versions{v, 2}, versions{v, 3}, versions{v, 4});
            traj = sortrows(fit.trajectory, 'ageYears');
            below = traj.deltaCIHigh_dB < 0;
            ageText = 'nowhere';
            if any(below)
                ageText = sprintf('%.1f-%.1f yr', min(traj.ageYears(below)), max(traj.ageYears(below)));
            end
            settingsText = sprintf('q_{f0} = %s, q_\\delta = %s, r = %.3g %s^2', ...
                q_text(versions{v, 2}), q_text(versions{v, 3}), fit.r, M.units);
            fitText = sprintf('log-lik %.1f (best grid cell %.1f)', fit.logLikelihood, bestLogLik);

            ax = nexttile(tl, v);
            plot_trajectories(ax, T, traj, M);
            title(ax, {versions{v, 1}, settingsText}, 'FontSize', 11);
            ax = nexttile(tl, v + 2);
            plot_gap(ax, traj, M);
            title(ax, {sprintf('CP - Control: %.3g to %.3g %s; band below 0: %s', ...
                min(traj.deltaMean_dB), max(traj.deltaMean_dB), M.units, ageText), fitText}, 'FontSize', 11);

            rows = [rows; table(string(band.name), string(versions{v, 1}), versions{v, 2}, versions{v, 3}, ...
                fit.r, fit.logLikelihood, mean(traj.deltaMean_dB), min(traj.deltaMean_dB), ...
                max(traj.deltaMean_dB), string(ageText), ...
                'VariableNames', {'band', 'version', 'qF0', 'qDelta', 'r', 'logLik', 'meanGap_dB', ...
                'minGap_dB', 'maxGap_dB', 'gapBelowZero'})]; %#ok<AGROW>
        end
        axs = findobj(fig, 'Type', 'axes');
        linkaxes(axs, 'x');
        % Same y-range within each row, so the two versions compare directly
        tiles = flipud(axs);   % creation order: top1, bottom1, top2, bottom2
        linkaxes(tiles(1:2:end), 'y');
        linkaxes(tiles(2:2:end), 'y');
        file = fullfile(gridDir, sprintf('gallery_%s.png', band.name));
        exportgraphics(fig, file, 'Resolution', 160);
        close(fig);
        writetable(rows, fullfile(gridDir, sprintf('gallery_%s.csv', band.name)));
        out.(band.name) = struct('file', file, 'table', rows);
    end
end

function fit = fit_version(T, qF0, qDelta, extra)
    % Same as the grid: r chosen by maximum likelihood for the given smoothness.
    priorArgs = {'initialCovarianceScale', 100};
    if isfield(extra, 'initialCovarianceDiag')
        priorArgs = [priorArgs, {'initialCovarianceDiag', extra.initialCovarianceDiag}];
    end
    model = @(r) SS_age_diff(T, 'observationVarianceMode', 'scalar_r', 'observationVarianceR', r, ...
        'processNoiseQF0', qF0, 'processNoiseQDelta', qDelta, 'minAgeGapYears', 0.05, ...
        priorArgs{:}, 'verbose', false);
    logR = fminbnd(@(lr) -model(exp(lr)).logLikelihood, log(1e-4), log(1e4), optimset('TolX', 1e-6));
    fit = model(exp(logR));
    fit.r = exp(logR);
end

function plot_trajectories(ax, T, traj, M)
    % M.toDisplay maps model units to plotted units (identity for dB, tanh for coherence z)
    controlColor = [0.00 0.38 0.95];
    cpColor = [0.92 0.02 0.08];
    d = M.toDisplay;
    hold(ax, 'on');
    band(ax, traj.ageYears, d(traj.baselineCILow_dB), d(traj.baselineCIHigh_dB), controlColor);
    band(ax, traj.ageYears, d(traj.cpCILow_dB), d(traj.cpCIHigh_dB), cpColor);
    plot(ax, traj.ageYears, d(traj.baselineMean_dB), '-', 'Color', controlColor, 'LineWidth', 2.2);
    plot(ax, traj.ageYears, d(traj.cpMean_dB), '-', 'Color', cpColor, 'LineWidth', 2.2);
    isCP = T.groupLabel == "CP";
    scatter(ax, T.ageYears(~isCP), d(T.alpha_dB(~isCP)), 38, controlColor, 'filled', 'MarkerEdgeColor', 'w');
    scatter(ax, T.ageYears(isCP), d(T.alpha_dB(isCP)), 38, cpColor, 'filled', 'MarkerEdgeColor', 'w');
    style(ax);  ylabel(ax, M.yLabel);
    legend(ax, {'', '', 'Control', 'CP'}, 'Location', 'northeast');
end

function plot_gap(ax, traj, M)
    hold(ax, 'on');
    band(ax, traj.ageYears, traj.deltaCILow_dB, traj.deltaCIHigh_dB, [0.35 0.40 0.50]);
    plot(ax, traj.ageYears, traj.deltaMean_dB, '-', 'Color', [0.2 0.25 0.35], 'LineWidth', 2.2);
    yline(ax, 0, '--', 'Color', [0.4 0.4 0.4]);
    style(ax);  xlabel(ax, 'Age (years)');  ylabel(ax, M.gapLabel);
end

function band(ax, x, lo, hi, c)
    fill(ax, [x; flipud(x)], [lo; flipud(hi)], c, 'FaceAlpha', 0.18, 'EdgeColor', 'none');
end

function style(ax)
    grid(ax, 'on');  box(ax, 'off');  ax.FontSize = 11;  ax.TickDir = 'out';
    xlim(ax, [10 15.5]);
end

function txt = q_text(q)
    if q < 1e-6
        txt = '0';
    else
        txt = sprintf('%.3g', q);
    end
end

function out = title_case(s)
    s = char(s);
    out = [upper(s(1)) s(2:end)];
end
