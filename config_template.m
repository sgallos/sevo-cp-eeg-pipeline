function local = config_template()
%CONFIG_TEMPLATE Machine-specific settings. Copy this file to config_local.m.
%
%   1. Copy this file and name the copy config_local.m (same folder).
%   2. In the copy, rename the function on the first line to config_local.
%   3. Set dataDir to the folder you downloaded from the shared Dropbox link.
%
%   config_local.m is listed in .gitignore, so your paths never get committed.

    % Folder that holds Patients.xlsx and the subject *_focus.mat files
    % (the "Sevofluorane" folder from the shared Dropbox link).
    local.dataDir = '/path/to/Sevofluorane';

    % Optional. Folder with previously saved outputs to compare against in
    % tests/. Leave empty if you don't have one; those tests are then skipped.
    local.referenceOutputsDir = '';

    % Optional. The original StateSpaceAlpha folder (power tables, SSM fits),
    % compared against by tests/ from stage 02 on.
    local.referenceStateSpaceDir = '';
end
