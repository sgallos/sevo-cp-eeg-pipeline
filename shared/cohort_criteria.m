function criteria = cohort_criteria()
%COHORT_CRITERIA The inclusion rules for every analysis. Edit only here.
%   Every stage gets its subjects from get_cohort(), which applies these
%   rules to whatever is in the data folder right now. New subjects that
%   meet them are picked up automatically everywhere.

    criteria = struct();
    criteria.anesthesia = 'sevo';          % sevoflurane cases only
    criteria.ageMinYears = 10;             % inclusive
    criteria.ageMaxYears = 16;             % inclusive
    criteria.electrode = 'F3';             % must be present (not removed as bad)
    criteria.minDurationSec = 120;         % the 120 s epoch, cut into 4 x 30 s

    % Stage-specific extra requirement, applied on top of the cohort:
    % coherence (stage 05) also needs F4.
    criteria.coherenceElectrode = 'F4';
end
