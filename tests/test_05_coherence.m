function tests = test_05_coherence
%TEST_05_COHERENCE Stage 05 (F3-F4 coherence), compared with saved outputs.
%   Coherence has no random steps (Chronux multitaper + Bokil's analytic
%   two-group test), so every number must match the original exactly.
%   - Subject level: one subject (CS28) recomputed from the raw data.
%   - Validation and group level: fed the ORIGINAL subject-level files.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    paths = setup_project();

    ref = fullfile(paths.referenceOutputsDir, 'coherence', 'outputs');
    assumeTrue(testCase, isfolder(fullfile(ref, 'coherence_subject_level')), ...
        'Reference coherence outputs not configured; skipped.');
    td.ref = ref;

    % Subject level, from raw data
    td.subjOut = make_temp(testCase);
    evalc('run_subject_f3f4_coherence_for_id(''CS28'', true, true, ''sevo'', td.subjOut);');

    % Validation, from the original subject files
    vOpts.subjectRoot = fullfile(ref, 'coherence_subject_level');
    vOpts.validationOutDir = make_temp(testCase);
    evalc('td.validationFile = validate_group_coherence_inputs(vOpts);');

    % Group analysis + figures, from our validation of the original files
    gOpts.validationMatFile = td.validationFile;
    gOpts.groupOutDir = make_temp(testCase);
    evalc('td.groupFile = run_group_f3f4_coherence_analysis(gOpts);');
    evalc('plot_group_f3f4_coherence_results(gOpts.groupOutDir);');  close all;
    evalc('td.svgFile = export_group_f3f4_coherence_publication_svg(''resultsFile'', td.groupFile, ''publicationRoot'', gOpts.groupOutDir);');  close all;
    td.groupOutDir = gOpts.groupOutDir;
    testCase.TestData = td;
end

function testSubjectCoherenceMatches(testCase)
    new = load(fullfile(testCase.TestData.subjOut, 'CS28', 'CS28_F3F4_coherence.mat'));
    ref = load(fullfile(testCase.TestData.ref, 'coherence_subject_level', 'CS28', 'CS28_F3F4_coherence.mat'));
    verifyEqual(testCase, new.freq, ref.freq, 'AbsTol', 1e-12);
    verifyEqual(testCase, new.coherence_subject, ref.coherence_subject, 'AbsTol', 1e-10);
    verifyEqual(testCase, new.alphaCoherenceMean, ref.alphaCoherenceMean, 'AbsTol', 1e-10);
    verifyEqual(testCase, new.J_F3_flat, ref.J_F3_flat, 'AbsTol', 1e-8);
    verifyEqual(testCase, new.J_F4_flat, ref.J_F4_flat, 'AbsTol', 1e-8);
end

function testValidationIncludesSameSubjects(testCase)
    V = load(testCase.TestData.validationFile, 'includedAfterValidation');
    R = load(fullfile(testCase.TestData.ref, 'coherence_validation', 'coherence_validation_results.mat'), ...
        'includedAfterValidation');
    verifyEqual(testCase, sort(string(V.includedAfterValidation.subjectID)), ...
        sort(string(R.includedAfterValidation.subjectID)));
end

function testGroupResultsMatchExactly(testCase)
    new = load(testCase.TestData.groupFile);
    ref = load(fullfile(testCase.TestData.ref, 'coherence_group_level', 'group_f3f4_coherence_results.mat'));
    verifyEqual(testCase, sort(string(new.subjectTable.subjectID)), sort(string(ref.subjectTable.subjectID)));
    verifyEqual(testCase, height(new.subjectTable), 23);
    for name = ["controlMedian", "cpMedian", "controlIQR", "cpIQR"]
        verifyEqual(testCase, new.(name), ref.(name), 'AbsTol', 1e-10, name);
    end
    for name = ["dz", "vdz", "pvals", "sigMask_raw", "sigMask_contiguous"]
        verifyEqual(testCase, new.inference.(name), ref.inference.(name), 'AbsTol', 1e-10, name);
    end
    verifyEqual(testCase, new.alphaComparison.ttestP, ref.alphaComparison.ttestP, 'AbsTol', 1e-12);
    verifyEqual(testCase, new.alphaComparison.ranksumP, ref.alphaComparison.ranksumP, 'AbsTol', 1e-12);
end

function testFiguresAreWritten(testCase)
    d = testCase.TestData.groupOutDir;
    for name = ["01_group_f3f4_coherence_curves.png", "02_group_f3f4_coherence_combined.png", ...
                "03_alpha_coherence_scalar_comparison.png"]
        verifyTrue(testCase, isfile(fullfile(d, name)), name);
    end
    verifyTrue(testCase, isfile(testCase.TestData.svgFile), 'publication SVG');
end

function d = make_temp(testCase)
    d = tempname;
    mkdir(d);
    testCase.addTeardown(@() rmdir(d, 's'));
end
