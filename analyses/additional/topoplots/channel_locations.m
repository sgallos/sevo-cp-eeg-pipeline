function chanlocs = channel_locations(labels)
%CHANNEL_LOCATIONS EEGLAB channel locations for these labels, from the standard 10-5 template.
%   Positions are template positions, not each child's measured electrodes.
    ensure_eeglab();
    template = readlocs('standard-10-5-cap385.elp');
    [found, where] = ismember(lower(string(labels(:))), lower(string({template.labels})));
    assert(all(found), 'No template position for: %s', strjoin(string(labels(~found)), ', '));
    chanlocs = template(where);
end

function ensure_eeglab()
    if exist('readlocs', 'file') == 2 && exist('standard-10-5-cap385.elp', 'file') == 2
        return;
    end
    local = config_local();
    assert(isfield(local, 'eeglabDir') && isfolder(local.eeglabDir), ...
        'Set eeglabDir in config_local.m (see config_template.m).');
    addpath(fullfile(local.eeglabDir, 'functions', 'sigprocfunc'), ...
        fullfile(local.eeglabDir, 'functions', 'guifunc'), ...
        fullfile(local.eeglabDir, 'functions', 'miscfunc'), ...
        fullfile(local.eeglabDir, 'functions', 'popfunc'), ...
        fullfile(local.eeglabDir, 'functions', 'adminfunc'), ...
        fullfile(local.eeglabDir, 'plugins', 'dipfit', 'standard_BESA'));
end
