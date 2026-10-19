function tests = test_00_setup
%TEST_00_SETUP Checks that paths, toolboxes, and input data are in place.
%   Run from the repo root:  results = runtests('tests/test_00_setup.m')
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    testCase.TestData.paths = setup_project();
end

function testDataFolderHasMetadata(testCase)
    paths = testCase.TestData.paths;
    verifyTrue(testCase, isfile(fullfile(paths.dataDir, 'Patients.xlsx')), ...
        'Patients.xlsx should be in dataDir.');
end

function testMetadataLoads(testCase)
    meta = load_subject_metadata(struct('anesthesia', 'sevo'));
    verifyGreaterThan(testCase, numel(meta.controls.ids), 0);
    verifyGreaterThan(testCase, numel(meta.patients.ids), 0);
end

function testSubjectFileIsFound(testCase)
    files = find_subject_data_files(testCase.TestData.paths.dataDir, {'CS28'});
    verifyNumElements(testCase, files, 1);
    verifyTrue(testCase, isfile(files(1).path));
end

function testChronuxIsOnPath(testCase)
    verifyEqual(testCase, exist('mtspecgramc', 'file'), 2);
    verifyEqual(testCase, exist('two_group_test_coherence', 'file'), 2);
end
