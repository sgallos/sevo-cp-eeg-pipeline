function tests = test_02_cohort
%TEST_02_COHORT Stage 02 (band-power tables + cohort), compared with saved outputs.
%   Feeds the ORIGINAL stage 01 sub-epoch spectra into stage 02, so this
%   tests stage 02 on its own. Stage 02 has no randomness: it only
%   integrates saved spectra over bands. Every value must match the
%   original tables, and the cohort must be the published 12 + 12.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    paths = setup_project();

    refSubepochDir = fullfile(paths.referenceOutputsDir, 'outputs', 'mfdb_subepoch_level');
    refTableDir = fullfile(paths.referenceStateSpaceDir, 'outputs');
    assumeTrue(testCase, isfolder(refSubepochDir) && isfolder(refTableDir), ...
        'Reference outputs not configured; stage 02 comparison skipped.');

    outDir = tempname;
    mkdir(outDir);
    testCase.addTeardown(@() rmdir(outDir, 's'));

    evalc('extract_band_power_subepochs(refSubepochDir, outDir);');
    evalc('collapse_subepoch_power_table_for_ssm(outDir);');

    testCase.TestData.outDir = outDir;
    testCase.TestData.refTableDir = refTableDir;
end

function testSubepochTableMatches(testCase)
    compare_tables(testCase, 'power_table_for_ssm_subepochs.csv', ...
        {'subjectID', 'subepochIdx'});
end

function testCollapsedTableMatches(testCase)
    compare_tables(testCase, 'power_table_for_ssm_subepochs_collapsed.csv', {'subjectID'});
end

function testCohortIsPublished12Plus12(testCase)
    T = readtable(fullfile(testCase.TestData.outDir, ...
        'power_table_for_ssm_subepochs_collapsed.csv'), 'TextType', 'string');
    verifyEqual(testCase, height(T), 24);
    verifyEqual(testCase, sum(T.groupLabel == "Control"), 12);
    verifyEqual(testCase, sum(T.groupLabel == "CP"), 12);
    verifyTrue(testCase, all(T.ageYears >= 10 & T.ageYears <= 16));
    verifyTrue(testCase, all(T.nSubEpochs == 4));
end

function compare_tables(testCase, fileName, keyColumns)
    new = sortrows(readtable(fullfile(testCase.TestData.outDir, fileName), 'TextType', 'string'), keyColumns);
    ref = sortrows(readtable(fullfile(testCase.TestData.refTableDir, fileName), 'TextType', 'string'), keyColumns);

    verifyEqual(testCase, new.Properties.VariableNames, ref.Properties.VariableNames, ...
        'Column names differ.');
    verifyEqual(testCase, height(new), height(ref), 'Row counts differ.');
    if height(new) ~= height(ref)
        return;
    end

    for name = string(new.Properties.VariableNames)
        if isnumeric(new.(name))
            % CSV round trip keeps ~15 significant digits.
            verifyEqual(testCase, new.(name), ref.(name), 'RelTol', 1e-10, ...
                sprintf('%s: column %s differs', fileName, name));
        else
            verifyEqual(testCase, new.(name), ref.(name), ...
                sprintf('%s: column %s differs', fileName, name));
        end
    end
end
