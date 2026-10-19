function [controlsSorted, patientsSorted, rawTable] = sortPatientsByAge(dataDir, options)
% SORTPATIENTSBYAGE Reads patient/control age info and sorts by AGE (YEARS)
%
% Inputs:
%   dataDir - path to the folder containing Patients.xlsx
%   options - struct with optional fields:
%       .anesthesia  -> 'sevo', 'prop', or 'all' (default 'all')
%
% Outputs:
%   controlsSorted - table of CN* sorted by AGE (YEARS)
%   patientsSorted - table of CS* sorted by AGE (YEARS)
%   rawTable       - filtered table prior to CN/CS split

    if nargin < 2 || isempty(options)
        options = struct();
    end

    if ~isfield(options, 'anesthesia') || isempty(options.anesthesia)
        anesthesiaStage = "all";
    else
        anesthesiaStage = lower(string(options.anesthesia));
        assertValidAnesthesia(anesthesiaStage);
    end

    if isstring(dataDir)
        dataDir = char(dataDir);
    end

    % Full path to Excel file
    excelFile = fullfile(dataDir, 'Patients.xlsx');

    % Read with original column names preserved
    T = readtable(excelFile, 'ReadRowNames', true, 'VariableNamingRule', 'preserve');

    T = filterByAnesthesia(T, anesthesiaStage);

    % Separate row names into CN and CS
    rowNames = T.Properties.RowNames;
    isControl = startsWith(rowNames, 'CN');
    isPatient = startsWith(rowNames, 'CS');

    controls = T(isControl, :);
    patients = T(isPatient, :);

    % Sort using original column header
    controlsSorted = sortrows(controls, 'AGE (YEARS)');
    patientsSorted = sortrows(patients, 'AGE (YEARS)');

    % Display summary
    fprintf('🔍 Controls sorted by AGE (YEARS):\n');
    disp(controlsSorted(:, {'AGE (YEARS)', 'AGE (WEEKS)'}));

    fprintf('\n🔍 Patients sorted by AGE (YEARS):\n');
    disp(patientsSorted(:, {'AGE (YEARS)', 'AGE (WEEKS)'}));

    if nargout >= 3
        rawTable = T;
    end
end

function T = filterByAnesthesia(T, anesthesiaStage)
    if anesthesiaStage == "all"
        return;
    end

    columnName = 'ANESTHESIA (0=SEV,  1=PROP)';
    if ~ismember(columnName, T.Properties.VariableNames)
        error('sortPatientsByAge:MissingColumn', ...
            'Column %s not found in Patients.xlsx.', columnName);
    end

    columnData = T.(columnName);
    values = normalizeColumn(columnData);

    if anesthesiaStage == "sevo"
        mask = (values == 0);
    elseif anesthesiaStage == "prop"
        mask = (values == 1);
    else
        error('sortPatientsByAge:InvalidAnesthesia', ...
            'Unknown anesthesia stage: %s', anesthesiaStage);
    end

    mask = mask & ~isnan(values);
    T = T(mask, :);
end

function values = normalizeColumn(columnData)
    if isnumeric(columnData)
        values = columnData;
        return;
    end

    if iscell(columnData)
        values = nan(size(columnData));
        for i = 1:numel(columnData)
            values(i) = str2double(columnData{i});
        end
        return;
    end

    if isstring(columnData)
        values = str2double(columnData);
        return;
    end

    error('sortPatientsByAge:UnsupportedColumnType', ...
        'Unsupported ANESTHESIA column type: %s', class(columnData));
end

function assertValidAnesthesia(value)
    if isempty(value)
        return;
    end

    valid = ["sevo", "prop", "all"];
    if any(value == valid)
        return;
    end

    error('sortPatientsByAge:InvalidAnesthesia', ...
        'Valid anesthesia values are: %s', strjoin(valid, ', '));
end
