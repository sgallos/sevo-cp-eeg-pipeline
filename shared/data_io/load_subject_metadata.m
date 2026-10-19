function metadata = load_subject_metadata(options)
%LOAD_SUBJECT_METADATA Returns subject IDs and ages for controls/patients.
%   metadata = LOAD_SUBJECT_METADATA() loads Patients.xlsx from the project
%   data/reference folder, filters by anesthesia (default 'sevo'), and
%   returns structs for controls/patients.
%
%   metadata = LOAD_SUBJECT_METADATA('prop') filters for propofol cases.
%   metadata = LOAD_SUBJECT_METADATA(struct('anesthesia','all','metadataDir','/path'))

    if nargin < 1 || isempty(options)
        options = struct();
    elseif ischar(options) || isstring(options)
        options = struct('anesthesia', char(options));
    end

    if ~isstruct(options)
        error('load_subject_metadata:InvalidOptions', ...
            'Options must be a struct or anesthesia string.');
    end

    paths = project_paths();
    defaultDir = paths.dataDir;

    metadataDir = resolveMetadataDir(options, defaultDir);
    anesthesia = resolveAnesthesia(options);

    sortOptions = struct('anesthesia', anesthesia);
    [controlsSorted, patientsSorted, filteredTable] = ...
        sortPatientsByAge(metadataDir, sortOptions);

    metadata = struct();
    metadata.anesthesia = char(anesthesia);
    metadata.sourceDir = metadataDir;
    metadata.filteredTable = filteredTable;

    metadata.controls.sortedTable = controlsSorted;
    metadata.controls.ids = controlsSorted.Properties.RowNames;
    metadata.controls.ages = num2cell(controlsSorted.("AGE (YEARS)"));

    metadata.patients.sortedTable = patientsSorted;
    metadata.patients.ids = patientsSorted.Properties.RowNames;
    metadata.patients.ages = num2cell(patientsSorted.("AGE (YEARS)"));
end

function metadataDir = resolveMetadataDir(options, defaultDir)
    candidates = {};

    if isfield(options, 'metadataDir') && ~isempty(options.metadataDir)
        candidates{end+1} = options.metadataDir; %#ok<AGROW>
    end

    envOverride = getenv('PEDS_CP_METADATA_DIR');
    if ~isempty(envOverride)
        candidates{end+1} = envOverride; %#ok<AGROW>
    end

    candidates{end+1} = defaultDir;

    metadataDir = '';
    for i = 1:numel(candidates)
        candidate = candidates{i};
        if isfile(fullfile(candidate, 'Patients.xlsx'))
            metadataDir = candidate;
            break;
        end
    end

    if isempty(metadataDir)
        error(['load_subject_metadata:MissingFile', ...
               '\nPatients.xlsx not found. Check that dataDir in ', ...
               'config_local.m points at the folder containing it.']);
    end
end

function anesthesia = resolveAnesthesia(options)
    if isfield(options, 'anesthesia') && ~isempty(options.anesthesia)
        anesthesia = lower(string(options.anesthesia));
    else
        envAnesthesia = getenv('PEDS_CP_ANESTHESIA');
        if ~isempty(envAnesthesia)
            anesthesia = lower(string(envAnesthesia));
        else
            anesthesia = "sevo";
        end
    end

    valid = ["sevo", "prop", "all"];
    if ~any(anesthesia == valid)
        error('load_subject_metadata:InvalidAnesthesia', ...
            'Anesthesia must be one of: %s', strjoin(valid, ', '));
    end
end
