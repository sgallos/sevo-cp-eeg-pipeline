function cohort = check_cohort()
%CHECK_COHORT Print who is in the cohort, who isn't and why, and what's new.
%   Run this first in any session (Claude Code runs it automatically when a
%   session starts in this repo). It compares the data folder with the
%   subjects that already have stage 01 outputs, so new eligible subjects
%   are flagged before any analysis runs.

    setup_project();
    clear get_cohort
    [cohort, allSubjects] = get_cohort();
    criteria = cohort_criteria();

    fprintf('\n=== Cohort check (%s) ===\n', char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
    fprintf('Criteria: %s, ages %g-%g yr, %s present, >= %g s of data\n', criteria.anesthesia, ...
        criteria.ageMinYears, criteria.ageMaxYears, criteria.electrode, criteria.minDurationSec);
    fprintf('EEG files found: %d\n', height(allSubjects));
    fprintf('ELIGIBLE: %d  (%d Control, %d CP)\n', height(cohort), ...
        sum(cohort.groupLabel == "Control"), sum(cohort.groupLabel == "CP"));
    fprintf('  with F4 too (coherence): %d\n', sum(cohort.hasF4));

    % Exclusions worth a human look (not the routine age/anesthesia ones).
    excluded = allSubjects(~allSubjects.eligible, :);
    routine = startsWith(excluded.reason, "age ") & ~contains(excluded.reason, "unknown") | ...
              startsWith(excluded.reason, "anesthesia");
    flagged = excluded(~routine, :);
    fprintf('Excluded: %d (%d routine: under/over age or propofol)\n', height(excluded), sum(routine));
    for i = 1:height(flagged)
        fprintf('  CHECK %-5s %-7s %s\n', flagged.subjectID(i), flagged.groupLabel(i), flagged.reason(i));
    end

    % New subjects: eligible but not yet computed in stage 01.
    cfg = mfdb_config();
    computed = false(height(cohort), 1);
    for i = 1:height(cohort)
        computed(i) = ~isempty(dir(fullfile(cfg.outputDir, cohort.subjectID(i), '*_mfdb.mat')));
    end
    if all(computed)
        fprintf('All eligible subjects have stage 01 outputs.\n');
    else
        fprintf('NOT YET COMPUTED (run run_all.m): %s\n', strjoin(cohort.subjectID(~computed), ', '));
    end
end
