function result = run_subject_f3f4_coherence_for_id(subjectID, f3QualityPass, f4QualityPass, anesthesia, outputDir)
%RUN_SUBJECT_F3F4_COHERENCE_FOR_ID Export subject-level F3/F4 coherence and Fourier transforms.
%   Optional outputDir (default: outputs/coherence_subject_level) is used by tests/.

    if nargin < 2 || isempty(f3QualityPass)
        f3QualityPass = true;
    end
    if nargin < 3 || isempty(f4QualityPass)
        f4QualityPass = true;
    end
    if nargin < 4 || isempty(anesthesia)
        anesthesia = 'sevo';
    end

    paths = project_paths();
    ensure_chronux_paths();

    epochDurationSec = 120;
    movingwin = [2 2];
    segLen = 512;
    nWindows = 60;

    params = struct();
    params.tapers = [3 5];
    params.Fs = [];
    params.fpass = [0.5 40];
    params.pad = 0;
    params.err = 0;
    params.trialave = 0;

    alphaBand = [8 13];
    if nargin < 5 || isempty(outputDir)
        outputDir = fullfile(paths.outputsDir, 'coherence_subject_level');
    end
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    fprintf('Subject: %s\n', subjectID);
    fprintf('Anesthesia filter: %s\n', anesthesia);
    fprintf('Moving window: [%.1f %.1f] s\n', movingwin(1), movingwin(2));
    fprintf('Tapers: [%g %g]\n', params.tapers(1), params.tapers(2));
    fprintf('fpass: [%.1f %.1f] Hz\n', params.fpass(1), params.fpass(2));

    % dataDir holds the sevoflurane data (the only anesthesia this pipeline analyses).
    preprocessedDir = paths.dataDir;

    files = find_subject_data_files(preprocessedDir, {subjectID});
    if isempty(files)
        error('No focus file found for %s in %s', subjectID, preprocessedDir);
    end

    dataPath = files(1).path;
    fprintf('Loading %s\n', dataPath);

    D = load(dataPath);
    assert(isfield(D, 'data') && isfield(D, 'HDR'), 'Expected data and HDR in %s', dataPath);

    rawData = D.data;
    fprintf('Original data size: %dx%d\n', size(rawData, 1), size(rawData, 2));

    if size(rawData, 1) < size(rawData, 2)
        data = rawData';
    else
        data = rawData;
    end

    if size(data, 1) < size(data, 2)
        error('Data must be samples x channels after orientation fix.');
    end

    labels = string(D.HDR.label(:));
    Fs = D.HDR.frequency(1);
    params.Fs = Fs;
    N = size(data, 1);
    T = N / Fs;

    fprintf('Using data size: %dx%d (samples x channels)\n', size(data, 1), size(data, 2));
    fprintf('Fs = %.6f Hz | T = %.3f s\n', Fs, T);

    expectedN = round(epochDurationSec * Fs);
    if N ~= expectedN
        error('Expected %d samples for a %.1f s epoch, found %d. Exclude this subject.', expectedN, epochDurationSec, N);
    end
    if segLen ~= round(movingwin(1) * Fs)
        error('segLen (%d) does not match moving window duration %.3f s at Fs %.6f.', segLen, movingwin(1), Fs);
    end
    if N ~= segLen * nWindows
        error('Expected N = segLen * nWindows = %d, found %d.', segLen * nWindows, N);
    end

    f3Idx = find(strcmpi(labels, 'F3'), 1, 'first');
    f4Idx = find(strcmpi(labels, 'F4'), 1, 'first');

    if isempty(f3Idx)
        error('F3 not found for %s. Exclude this subject.', subjectID);
    end
    if isempty(f4Idx)
        error('F4 not found for %s. Exclude this subject.', subjectID);
    end
    if ~f3QualityPass
        error('F3 QC flag is false for %s. Exclude this subject.', subjectID);
    end
    if ~f4QualityPass
        error('F4 QC flag is false for %s. Exclude this subject.', subjectID);
    end

    signalF3 = double(data(:, f3Idx));
    signalF4 = double(data(:, f4Idx));
    fprintf('Using F3 index %d and F4 index %d\n', f3Idx, f4Idx);

    F3_segs = reshape(signalF3(1:(segLen * nWindows)), segLen, nWindows);
    F4_segs = reshape(signalF4(1:(segLen * nWindows)), segLen, nWindows);

    [tapers, pad, FsChronux, fpass, ~, ~] = getparams(params);
    nfft = max(2^(nextpow2(segLen) + pad), segLen);
    [freq, findx] = getfgrid(FsChronux, nfft, fpass);
    tapers = dpsschk(tapers, segLen, FsChronux);

    J_F3 = mtfftc(F3_segs, tapers, nfft, FsChronux);
    J_F4 = mtfftc(F4_segs, tapers, nfft, FsChronux);
    J_F3 = J_F3(findx, :, :);
    J_F4 = J_F4(findx, :, :);

    [nFreq, nTapers, nTrials] = size(J_F3);
    if nTrials ~= nWindows
        error('Expected %d trials after segmentation, found %d.', nWindows, nTrials);
    end

    J_F3_flat = reshape(permute(J_F3, [1 3 2]), nFreq, []);
    J_F4_flat = reshape(permute(J_F4, [1 3 2]), nFreq, []);

    S12_trial = squeeze(mean(conj(J_F3) .* J_F4, 2));
    S1_trial = squeeze(mean(conj(J_F3) .* J_F3, 2));
    S2_trial = squeeze(mean(conj(J_F4) .* J_F4, 2));
    C_trial = abs(S12_trial ./ sqrt(S1_trial .* S2_trial));

    coherence_windows = C_trial.';
    timeBins = ((0:(nTrials - 1)) * movingwin(2) + movingwin(1) / 2).';
    coherence_subject = mean(C_trial, 2, 'omitnan').';

    df = median(diff(freq));
    alphaMask = freq >= alphaBand(1) & freq <= alphaBand(2);
    if any(alphaMask)
        alphaCoherenceMean = mean(coherence_subject(alphaMask), 'omitnan');
    else
        alphaCoherenceMean = NaN;
        warning('No alpha-band frequency bins found for %s.', subjectID);
    end

    fprintf('mtfftc output size after fpass selection: %dx%dx%d (freq x tapers x trials)\n', nFreq, nTapers, nTrials);
    fprintf('Flattened J size: %dx%d\n', size(J_F3_flat, 1), size(J_F3_flat, 2));
    fprintf('Frequency spacing df = %.6f Hz\n', df);
    fprintf('Alpha-band mean coherence: %.6f\n', alphaCoherenceMean);

    meta = load_subject_metadata(metadata_options_for_anesthesia(anesthesia));
    ageYears = lookup_subject_age_years(subjectID, meta);
    groupLabel = infer_group_label(subjectID);

    subjectOutDir = fullfile(outputDir, subjectID);
    if ~exist(subjectOutDir, 'dir')
        mkdir(subjectOutDir);
    end

    outFile = fullfile(subjectOutDir, sprintf('%s_F3F4_coherence.mat', subjectID));

    metadata = struct();
    metadata.subjectID = subjectID;
    metadata.groupLabel = groupLabel;
    metadata.ageYears = ageYears;
    metadata.dataPath = dataPath;
    metadata.filePath = outFile;
    metadata.Fs = Fs;
    metadata.T = T;
    metadata.N = N;
    metadata.epochDurationSec = epochDurationSec;
    metadata.f3Index = f3Idx;
    metadata.f4Index = f4Idx;
    metadata.f3QualityPass = f3QualityPass;
    metadata.f4QualityPass = f4QualityPass;
    metadata.movingwin = movingwin;
    metadata.segLen = segLen;
    metadata.nWindows = nWindows;
    metadata.tapers = params.tapers;
    metadata.fpass = params.fpass;
    metadata.pad = params.pad;
    metadata.alphaBand = alphaBand;
    metadata.nfft = nfft;
    metadata.nTimeBins = numel(timeBins);
    metadata.nFreqBins = numel(freq);
    metadata.nTrials = nTrials;
    metadata.nTapers = nTapers;
    metadata.df = df;
    metadata.contiguousWidthHz = 2 * params.tapers(1) / movingwin(1);

    save(outFile, ...
        'subjectID', 'groupLabel', 'ageYears', 'dataPath', ...
        'Fs', 'T', 'N', 'freq', 'timeBins', ...
        'coherence_subject', 'coherence_windows', 'alphaCoherenceMean', ...
        'movingwin', 'params', 'segLen', 'nWindows', ...
        'J_F3_flat', 'J_F4_flat', 'nTrials', 'nTapers', ...
        'metadata', '-v7.3');

    fprintf('Saved subject-level coherence output to %s\n', outFile);

    result = struct();
    result.subjectID = string(subjectID);
    result.groupLabel = string(groupLabel);
    result.ageYears = ageYears;
    result.outFile = string(outFile);
    result.f3Index = f3Idx;
    result.f4Index = f4Idx;
    result.alphaCoherenceMean = alphaCoherenceMean;
    result.Fs = Fs;
    result.T = T;
    result.N = N;
    result.freq = freq;
    result.timeBins = timeBins;
    result.nTrials = nTrials;
    result.nTapers = nTapers;
end

function ageYears = lookup_subject_age_years(subjectID, meta)
    controlIDs = string(meta.controls.sortedTable.Properties.RowNames);
    patientIDs = string(meta.patients.sortedTable.Properties.RowNames);

    idx = find(strcmpi(controlIDs, string(subjectID)), 1, 'first');
    if ~isempty(idx)
        ageYears = meta.controls.sortedTable.('AGE (YEARS)')(idx);
        return;
    end

    idx = find(strcmpi(patientIDs, string(subjectID)), 1, 'first');
    if ~isempty(idx)
        ageYears = meta.patients.sortedTable.('AGE (YEARS)')(idx);
        return;
    end

    ageYears = NaN;
end

function metadataOptions = metadata_options_for_anesthesia(anesthesia)
    metadataOptions = struct('anesthesia', anesthesia);
end

function groupLabel = infer_group_label(subjectID)
    if startsWith(string(subjectID), 'CS', 'IgnoreCase', true)
        groupLabel = 'CP';
    elseif startsWith(string(subjectID), 'CN', 'IgnoreCase', true)
        groupLabel = 'Control';
    else
        error('Cannot infer group from subjectID %s.', subjectID);
    end
end

function ensure_chronux_paths()
    if exist('mtfftc', 'file') == 2 && exist('two_group_test_coherence', 'file') == 2
        return;
    end

    if exist('mtfftc', 'file') ~= 2
        error('mtfftc not found on the MATLAB path. Chronux path setup is incomplete.');
    end
    if exist('two_group_test_coherence', 'file') ~= 2
        warning('two_group_test_coherence not found on the MATLAB path yet. Subject export can proceed, but group inference will fail until Chronux statistical_tests is available.');
    end
end
