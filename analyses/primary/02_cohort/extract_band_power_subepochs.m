function T = extract_band_power_subepochs(subepochRoot, outDir, bands)
%EXTRACT_BAND_POWER_SUBEPOCHS Build a delta/theta/alpha sub-epoch power table.
%
% Uses the saved 4 x 30 s sub-epoch MFDB spectra. No multitaper or MFDB
% bootstrap is rerun here; the script only reintegrates the saved spectra
% over each band:
%   delta: 1-4 Hz
%   theta: 4-8 Hz
%   alpha: 8-13 Hz
% (band edges from state_space_bands.m, shared with the state-space model)
%
% Output:
%   outputs/power_table_for_ssm_subepochs.csv
%   outputs/power_table_for_ssm_subepochs.mat
%
% Subjects: every saved F3 sub-epoch file whose subject is in get_cohort()
% (the shared inclusion rules in shared/cohort_criteria.m).
%
% Optional inputs (used by tests/ to read the original stage 01 outputs):
%   subepochRoot - folder of sub-epoch MFDB files (default: stage 01 output)
%   outDir       - where to write the tables (default: state_space_outputs_dir())
%   bands        - band edges (default: state_space_bands(); tests pass
%                  state_space_bands("original") to reproduce the original table)

if nargin < 2 || isempty(outDir)
    outDir = state_space_outputs_dir();
end
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

if nargin < 1 || isempty(subepochRoot)
    cfg = mfdb_config();
    subepochRoot = cfg.subEpochOutputDir;
end

if ~isfolder(subepochRoot)
    error('Sub-epoch output folder not found: %s', subepochRoot);
end

if nargin < 3 || isempty(bands)
    bands = state_space_bands();
end

cohort = get_cohort();   % who is eligible: see shared/cohort_criteria.m
cohortIDs = cohort.subjectID;
subepochFiles = find_subepoch_files(subepochRoot);
nSubjects = numel(subepochFiles);
nExpectedRows = nSubjects * 4;

T = table('Size', [nExpectedRows, 13], ...
    'VariableTypes', {'string','double','string','double', ...
    'double','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'subjectID','subepochIdx','groupLabel','ageYears', ...
    'delta_dB','theta_dB','alpha_dB', ...
    'delta_mfdb_var','theta_mfdb_var','alpha_mfdb_var', ...
    'delta_nFreqBins','theta_nFreqBins','alpha_nFreqBins'});

rowIdx = 0;
for subjectIdx = 1:nSubjects
    subepochFile = string(subepochFiles(subjectIdx));
    S = load(subepochFile, 'subEpochResults', 'groupLabel', 'ageYears', 'subjectID');
    subjectID = string(S.subjectID);

    if ~ismember(subjectID, cohortIDs)
        fprintf('Skipping %s: not in get_cohort() (see check_cohort for the reason).\n', subjectID);
        continue;
    end

    if numel(S.subEpochResults) ~= 4
        warning('Skipping %s: expected 4 sub-epochs, found %d.', ...
            subjectID, numel(S.subEpochResults));
        continue;
    end

    for subepochIdx = 1:numel(S.subEpochResults)
        rowIdx = rowIdx + 1;
        thisSubEpoch = S.subEpochResults{subepochIdx};

        T.subjectID(rowIdx) = subjectID;
        T.subepochIdx(rowIdx) = subepochIdx;
        T.groupLabel(rowIdx) = string(S.groupLabel);
        T.ageYears(rowIdx) = double(S.ageYears);

        for bandIdx = 1:numel(bands)
            band = bands(bandIdx);
            [powerDB, mfdbVar, nFreqBins] = integrate_subepoch_band(thisSubEpoch, ...
                band.lowHz, band.highHz, subjectID, subepochIdx, band.name);

            bandName = string(band.name);
            T.(bandName + "_dB")(rowIdx) = powerDB;
            T.(bandName + "_mfdb_var")(rowIdx) = mfdbVar;
            T.(bandName + "_nFreqBins")(rowIdx) = nFreqBins;
        end
    end
end

T = T(1:rowIdx, :);

outCsv = fullfile(outDir, 'power_table_for_ssm_subepochs.csv');
outMat = fullfile(outDir, 'power_table_for_ssm_subepochs.mat');
writetable(T, outCsv);
save(outMat, 'T', 'bands', 'subepochRoot', 'subepochFiles');

fprintf('Wrote %d sub-epoch rows to %s\n', height(T), outCsv);
disp(T(1:min(12, height(T)), :));
end

function subepochFiles = find_subepoch_files(subepochRoot)
files = dir(fullfile(subepochRoot, '*', '*_F3_mfdb_subepochs.mat'));
if isempty(files)
    error('No F3 sub-epoch files found under %s.', subepochRoot);
end

fullPaths = string(fullfile({files.folder}, {files.name}));
[~, order] = sort(lower(fullPaths));
subepochFiles = fullPaths(order);
end

function [powerDB, mfdbVar, nFreqBins] = integrate_subepoch_band(thisSubEpoch, ...
    lowHz, highHz, subjectID, subepochIdx, bandName)
freq = double(thisSubEpoch.freq(:).');
bandMask = freq >= lowHz & freq <= highHz;
nFreqBins = sum(bandMask);

if nFreqBins == 0
    error('No %s bins found for %s sub-epoch %d in [%g, %g] Hz.', ...
        bandName, subjectID, subepochIdx, lowHz, highHz);
end

originalDB = double(thisSubEpoch.S_subject_original_dB);
bootDB = double(thisSubEpoch.S_subject_boot_dB);

originalLinear = trapz(freq(bandMask), 10.^(originalDB(bandMask) / 10));
powerDB = 10 * log10(max(originalLinear, eps));

bootLinear = trapz(freq(bandMask), 10.^(bootDB(:, bandMask) / 10), 2);
bootPowerDB = 10 * log10(max(bootLinear, eps));
mfdbVar = var(bootPowerDB, 0, 'omitnan');
end
