function tests = test_07_age_varying_spectrogram
%TEST_07_AGE_VARYING_SPECTROGRAM Stage 07 (Figs 02-03) vs the saved outputs.
%   Spectrograms (Chronux) and window averages have no randomness, so the
%   subjects, per-subject spectra and age-window matrices must match exactly.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    p = setup_project();
    refBase = fullfile(p.referenceOutputsDir, 'age_varying_f3_spectrogram', 'outputs', ...
        'age_varying_f3_timeavg_spec_10.0_to_16.0_sevo');
    assumeTrue(testCase, isfile([refBase '_results.mat']), 'Reference outputs not configured; skipped.');
    outDir = tempname;
    mkdir(outDir);
    testCase.addTeardown(@() rmdir(outDir, 's'));
    evalc('o = plot_age_varying_f3_time_averaged_spectrogram(struct(''outDir'', outDir));');
    close all;
    testCase.TestData.newBase = fullfile(o.outDir, o.plotFileBase);
    testCase.TestData.refBase = refBase;
end

function testSameSubjects(testCase)
    a = readtable([testCase.TestData.newBase '_subjects_used.csv'], 'TextType', 'string');
    b = readtable([testCase.TestData.refBase '_subjects_used.csv'], 'TextType', 'string');
    verifyEqual(testCase, sort(a.SubjectID), sort(b.SubjectID));
    verifyEqual(testCase, height(a), 24);
end

function testResultsMatchExactly(testCase)
    a = load([testCase.TestData.newBase '_results.mat']);
    b = load([testCase.TestData.refBase '_results.mat']);
    common = intersect(fieldnames(a), fieldnames(b));
    nCompared = 0;
    for k = 1:numel(common)
        name = common{k};
        if isnumeric(a.(name)) && isequal(size(a.(name)), size(b.(name)))
            verifyEqual(testCase, a.(name), b.(name), 'AbsTol', 1e-9, name);
            nCompared = nCompared + 1;
        end
    end
    fprintf('Compared %d numeric variables\n', nCompared);
    verifyGreaterThan(testCase, nCompared, 3);
end

function testFiguresWritten(testCase)
    for suffix = ["_primary_control.png", "_primary_cp.png"]
        verifyTrue(testCase, isfile(testCase.TestData.newBase + suffix), suffix);
    end
end
