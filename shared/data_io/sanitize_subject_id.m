function cleanID = sanitize_subject_id(subjectID)
%SANITIZE_SUBJECT_ID Normalizes subject identifiers to match folder names.
%   Removes spaces, underscores, and other non-alphanumeric characters.

    if isstring(subjectID)
        subjectID = char(subjectID);
    end

    if ~ischar(subjectID)
        error('sanitize_subject_id:InvalidType', ...
            'Expected char or string, got %s', class(subjectID));
    end

    cleanID = regexprep(subjectID, '[^A-Za-z0-9]', '');
end
