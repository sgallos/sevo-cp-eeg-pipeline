function tests = test_06_state_space_model
%TEST_06_STATE_SPACE_MODEL Stage 06 (state-space model, Figs 05-06) vs saved outputs.
%   Fits the scalar-r SSM for delta, theta and alpha from the ORIGINAL stage 02
%   power table, with the same settings regenerate_publication_figures.m used.
%   EM and the Kalman smoother have no randomness, so every number must match.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(repoRoot);
    p = setup_project();
    refDir = fullfile(p.referenceStateSpaceDir, 'outputs');
    inputTable = fullfile(refDir, 'power_table_for_ssm_subepochs_collapsed.csv');
    assumeTrue(testCase, isfile(fullfile(refDir, 'power_ssm_publication_alpha_summary.csv')), ...
        'Reference SSM outputs not configured; skipped.');

    outDir = tempname;
    mkdir(outDir);
    testCase.addTeardown(@() rmdir(outDir, 's'));
    bands = state_space_bands("original");   % the original fits used alpha 8-12 Hz
    for b = 1:numel(bands)
        evalc(['run_power_ssm_scalar_r(''bandName'', bands(b).name, ''bandLowHz'', bands(b).lowHz, ' ...
            '''bandHighHz'', bands(b).highHz, ''inputTable'', inputTable, ''powerColumn'', bands(b).column, ' ...
            '''qMode'', "all", ''outputPrefix'', "power_ssm_publication", ''outputsDir'', outDir)']);
        close all;
    end
    evalc(['testCase.TestData.figFiles = export_fixed_heuristic_power_ssm_publication_figures(' ...
        '''resultsDir'', outDir, ''publicationRoot'', outDir);']);
    close all;
    testCase.TestData.outDir = outDir;
    testCase.TestData.refDir = refDir;
end

function testSummariesMatchExactly(testCase)
    compare_csv(testCase, 'summary');
end

function testTrajectoriesMatchExactly(testCase)
    compare_csv(testCase, 'trajectories');
end

function testPublicationFiguresWritten(testCase)
    files = testCase.TestData.figFiles;
    verifyNumElements(testCase, files, 12, '3 bands x (Fig 05 + Fig 06) x (SVG + PNG)');
    verifyTrue(testCase, all(arrayfun(@isfile, files)));
end

function compare_csv(testCase, kind)
    for band = ["delta", "theta", "alpha"]
        name = sprintf('power_ssm_publication_%s_%s.csv', band, kind);
        a = readtable(fullfile(testCase.TestData.outDir, name), 'TextType', 'string');
        b = readtable(fullfile(testCase.TestData.refDir, name), 'TextType', 'string');
        verifyEqual(testCase, height(a), height(b), name);
        for col = string(a.Properties.VariableNames)
            if isnumeric(a.(col))
                verifyEqual(testCase, a.(col), b.(col), 'AbsTol', 1e-9, name + ": " + col);
            else
                verifyEqual(testCase, a.(col), b.(col), name + ": " + col);
            end
        end
    end
end
