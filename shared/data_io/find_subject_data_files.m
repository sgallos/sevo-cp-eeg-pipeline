function fileList = find_subject_data_files(dataDir, subjectIDs)
%FIND_SUBJECT_DATA_FILES Matches subject IDs to focus.mat files.
%   fileList = FIND_SUBJECT_DATA_FILES(dataDir, subjectIDs)
%   Returns struct array with fields:
%       .id   - original subject ID (e.g., 'CN2')
%       .path - full path to the *_focus.mat file

    if isstring(dataDir)
        dataDir = char(dataDir);
    end

    files = [
        dir(fullfile(dataDir, '*focus*.mat'));
        dir(fullfile(dataDir, 'Controls', '*focus*.mat'));
        dir(fullfile(dataDir, 'Patients', '*focus*.mat'))];
    idMap = containers.Map();
    locationPriority = containers.Map({'TopLevel', 'Controls', 'Patients'}, [1, 2, 2]);
    priorityMap = containers.Map();

    for i = 1:numel(files)
        name = files(i).name;
        subjID = parse_subject_id_from_name(name);
        if isempty(subjID)
            continue;
        end

        thisPath = fullfile(files(i).folder, files(i).name);
        thisPriority = infer_location_priority(files(i).folder, dataDir, locationPriority);

        if ~idMap.isKey(subjID) || thisPriority < priorityMap(subjID)
            idMap(subjID) = thisPath;
            priorityMap(subjID) = thisPriority;
        end
    end

    fileList = struct('id', {}, 'path', {});
    for i = 1:numel(subjectIDs)
        rawID = subjectIDs{i};
        sanitized = sanitize_subject_id(rawID);
        if isempty(sanitized)
            continue;
        end

        if idMap.isKey(sanitized)
            fileList(end+1) = struct('id', rawID, 'path', idMap(sanitized)); %#ok<AGROW>
        else
            warning('find_subject_data_files:MissingFile', ...
                'No focus file found for subject %s (sanitized %s).', rawID, sanitized);
        end
    end
end

function priority = infer_location_priority(folderPath, dataDir, locationPriority)
    folderPath = char(folderPath);
    dataDir = char(dataDir);

    if strcmp(folderPath, dataDir)
        priority = locationPriority('TopLevel');
    elseif strcmp(folderPath, fullfile(dataDir, 'Controls'))
        priority = locationPriority('Controls');
    elseif strcmp(folderPath, fullfile(dataDir, 'Patients'))
        priority = locationPriority('Patients');
    else
        priority = 99;
    end
end

function subjID = parse_subject_id_from_name(name)
    token = regexp(name, 'C[SN][\s_]*\d+', 'match', 'once');
    if isempty(token)
        subjID = '';
    else
        subjID = sanitize_subject_id(token);
    end
end
