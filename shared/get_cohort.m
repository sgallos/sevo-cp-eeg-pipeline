function [cohort, allSubjects] = get_cohort()
%GET_COHORT Every subject that meets cohort_criteria(), from the data as it is now.
%   cohort = GET_COHORT() returns one row per eligible subject:
%     subjectID, groupLabel ("Control"/"CP"), ageYears, hasF4, dataFile
%   [cohort, allSubjects] = GET_COHORT() also returns every EEG file found,
%   with an `eligible` flag and a plain-language `reason` for exclusions.
%
%   This is the single source of truth for who is analysed. All stages call
%   it, so adding a subject to the data folder adds them everywhere.
%   Results are cached for the MATLAB session; call `clear get_cohort` to rescan.

    persistent cache
    paths = project_paths();
    if ~isempty(cache) && strcmp(cache.dataDir, paths.dataDir)
        cohort = cache.cohort;
        allSubjects = cache.allSubjects;
        return;
    end

    criteria = cohort_criteria();
    meta = read_metadata(paths.dataDir);
    files = [dir(fullfile(paths.dataDir, 'Controls', '*focus*.mat'));
             dir(fullfile(paths.dataDir, 'Patients', '*focus*.mat'))];

    n = numel(files);
    T = table('Size', [n 10], ...
        'VariableTypes', {'string','string','double','string','logical','logical','double','string','logical','string'}, ...
        'VariableNames', {'subjectID','groupLabel','ageYears','anesthesia','hasF3','hasF4', ...
                          'durationSec','dataFile','eligible','reason'});

    for i = 1:n
        filePath = fullfile(files(i).folder, files(i).name);
        id = sanitize_subject_id(regexp(files(i).name, 'C[SN][\s_]*\d+', 'match', 'once'));
        [labels, durationSec] = read_recording_info(filePath);

        T.subjectID(i) = id;
        T.groupLabel(i) = group_from_id(id);
        T.dataFile(i) = filePath;
        T.hasF3(i) = any(labels == upper(criteria.electrode));
        T.hasF4(i) = any(labels == upper(criteria.coherenceElectrode));
        T.durationSec(i) = durationSec;

        row = find(meta.id == id, 1);
        if isempty(row)
            T.ageYears(i) = NaN;
            T.anesthesia(i) = "missing";
        else
            T.ageYears(i) = meta.ageYears(row);
            T.anesthesia(i) = meta.anesthesia(row);
        end
        [T.eligible(i), T.reason(i)] = check_subject(T(i, :), criteria);
    end

    allSubjects = sortrows(T, {'groupLabel', 'ageYears', 'subjectID'});
    cohort = allSubjects(allSubjects.eligible, {'subjectID','groupLabel','ageYears','hasF4','dataFile'});

    cache = struct('dataDir', paths.dataDir, 'cohort', cohort, 'allSubjects', allSubjects);
end

function [ok, reason] = check_subject(row, c)
    % First failing rule wins, so each excluded subject has one clear reason.
    ok = false;
    if row.anesthesia == "missing"
        reason = "no row in Patients.xlsx";
    elseif row.anesthesia ~= string(c.anesthesia)
        reason = "anesthesia is " + row.anesthesia;
    elseif ~isfinite(row.ageYears) || row.ageYears > 100
        reason = "age unknown (birthdate missing in Patients.xlsx)";
    elseif row.ageYears < c.ageMinYears
        reason = sprintf("age %.2f < %g", row.ageYears, c.ageMinYears);
    elseif row.ageYears > c.ageMaxYears
        reason = sprintf("age %.2f > %g", row.ageYears, c.ageMaxYears);
    elseif ~row.hasF3
        reason = c.electrode + " missing (removed as bad channel)";
    elseif row.durationSec < c.minDurationSec
        reason = sprintf("recording %.0f s < %g s", row.durationSec, c.minDurationSec);
    else
        ok = true;
        reason = "";
    end
end

function meta = read_metadata(dataDir)
    raw = readtable(fullfile(dataDir, 'Patients.xlsx'), 'ReadRowNames', true, ...
        'VariableNamingRule', 'preserve');
    names = raw.Properties.VariableNames;
    anesthesiaCol = names{contains(names, 'ANESTHESIA')};   % 0 = sevo, 1 = propofol
    code = raw.(anesthesiaCol);
    anesthesia = repmat("unknown", height(raw), 1);
    anesthesia(code == 0) = "sevo";
    anesthesia(code == 1) = "prop";
    meta = struct( ...
        'id', string(cellfun(@sanitize_subject_id, raw.Properties.RowNames, 'UniformOutput', false)), ...
        'ageYears', raw.('AGE (YEARS)'), ...
        'anesthesia', anesthesia);
end

function [labels, durationSec] = read_recording_info(filePath)
    % Reads only the header and the size of `data`, not the signal itself.
    S = load(filePath, 'HDR');
    labels = upper(strtrim(string(S.HDR.label(:))));
    info = whos('-file', filePath, 'data');
    durationSec = max(info.size) / S.HDR.frequency(1);
end

function label = group_from_id(id)
    if startsWith(id, "CS")
        label = "CP";
    elseif startsWith(id, "CN")
        label = "Control";
    else
        label = "unknown";
    end
end
