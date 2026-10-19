function tests = test_cohort
%TEST_COHORT get_cohort() applies cohort_criteria() to the raw data folder.
%   Checks the cohort it finds against the published one. If new subjects are
%   added to the data, update the expected counts here on purpose.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    testCase.TestData.paths = setup_project();
    clear get_cohort
    [testCase.TestData.cohort, testCase.TestData.all] = get_cohort();
end

function testCohortSize(testCase)
    c = testCase.TestData.cohort;
    verifyEqual(testCase, height(c), 24);
    verifyEqual(testCase, sum(c.groupLabel == "Control"), 12);
    verifyEqual(testCase, sum(c.groupLabel == "CP"), 12);
    verifyEqual(testCase, sum(c.hasF4), 23, 'Coherence cohort (needs F4)');
end

function testEveryoneMeetsTheCriteria(testCase)
    c = testCase.TestData.cohort;  k = cohort_criteria();
    verifyTrue(testCase, all(c.ageYears >= k.ageMinYears & c.ageYears <= k.ageMaxYears));
    a = testCase.TestData.all;
    verifyTrue(testCase, all(a.reason(a.eligible) == ""));
    verifyTrue(testCase, all(a.reason(~a.eligible) ~= ""), 'Every exclusion needs a reason');
end

function testMatchesPublishedCohortTable(testCase)
    refFile = fullfile(testCase.TestData.paths.referenceStateSpaceDir, 'outputs', ...
        'power_table_for_ssm_subepochs_collapsed.csv');
    assumeTrue(testCase, isfile(refFile), 'No reference cohort table; skipped.');
    ref = readtable(refFile, 'TextType', 'string');
    verifyEqual(testCase, sort(testCase.TestData.cohort.subjectID), sort(ref.subjectID));
end
