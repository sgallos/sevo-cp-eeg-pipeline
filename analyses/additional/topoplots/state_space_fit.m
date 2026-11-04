function trajectory = state_space_fit(subjectID, groupLabel, ageYears, value)
%STATE_SPACE_FIT The stage 06 state-space model with its published setting, for any value.
%   One value per child. Fixed heuristic q (q = (value range)^2 / (age span)^3 for both the
%   Control curve and the CP - Control gap), r estimated by EM, then the Kalman smoother,
%   exactly as run_power_ssm_scalar_r.m does for F3. Returns the model's trajectory table
%   (posterior means and 95% credible bands at each child's age).
    T = table(string(subjectID(:)), string(groupLabel(:)), ageYears(:), value(:), zeros(numel(value), 1), ...
        'VariableNames', {'subjectID', 'groupLabel', 'ageYears', 'alpha_dB', 'mfdb_var'});
    q = (max(T.alpha_dB) - min(T.alpha_dB))^2 / max((max(T.ageYears) - min(T.ageYears))^3, eps);
    em = SS_age_diff_em(T, 'observationVarianceMode', 'scalar_r', 'fixQ', true, ...
        'initialProcessNoiseQF0', q, 'initialProcessNoiseQDelta', q, 'qInitMultipliers', 1, ...
        'maxIter', 300, 'tolerance', 1e-5, 'logLikTolerance', 1e-4, 'logLikPatience', 3, ...
        'rFloor', 1e-4, 'rCeiling', 1e4, 'minAgeGapYears', 0.05, 'verbose', false);
    fit = SS_age_diff(T, 'observationVarianceMode', 'scalar_r', 'observationVarianceR', em.r_em, ...
        'processNoiseQF0', q, 'processNoiseQDelta', q, 'minAgeGapYears', 0.05, 'verbose', false);
    trajectory = fit.trajectory;
end
