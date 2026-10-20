function write_group_f3f4_coherence_results(resultsFile)
%WRITE_GROUP_F3F4_COHERENCE_RESULTS Print the group coherence results (dz, p-values, alpha t-test).
%   Optional resultsFile (default: outputs/coherence_group_level/group_f3f4_coherence_results.mat).
if nargin < 1 || isempty(resultsFile)
    paths = project_paths();
    resultsFile = fullfile(paths.outputsDir, 'coherence_group_level', 'group_f3f4_coherence_results.mat');
end

if ~isfile(resultsFile)
    error('Group coherence results file not found: %s', resultsFile);
end

fprintf('Loading group coherence results from %s\n', resultsFile);
S = load(resultsFile, 'subjectTable', 'freq', 'controlMedian', 'cpMedian', ...
    'alphaComparison', 'inference', 'metadataRef');

subjectTable = S.subjectTable;
controlMask = strcmpi(subjectTable.groupLabel, 'Control');
cpMask = strcmpi(subjectTable.groupLabel, 'CP');

nControls = sum(controlMask);
nCP = sum(cpMask);
controlAlphaScalar = S.alphaComparison.controlValues(:);
cpAlphaScalar = S.alphaComparison.cpValues(:);
f = S.freq(:);
dz = S.inference.dz(:);
pvals = S.inference.pvals(:);
sigMaskRaw = S.inference.sigMask_raw(:);
sigMaskContiguous = S.inference.sigMask_contiguous(:);
sigMaskRawExploratory = S.inference.sigMask_raw_exploratory(:);
sigMaskContiguousExploratory = S.inference.sigMask_contiguous_exploratory(:);
primaryP = S.inference.primaryP;
exploratoryP = S.inference.exploratoryP;
controlMedianCoherence = S.controlMedian(:);
cpMedianCoherence = S.cpMedian(:);
alphaBand = S.metadataRef.alphaBand(:)';
contiguousWidthHz = S.inference.contiguousWidthHz;

fprintf('\n=== GROUP DESCRIPTIVES ===\n');
fprintf('Controls n = %d\n', nControls);
fprintf('CP n = %d\n', nCP);
fprintf('Control alpha coherence (%.1f-%.1f Hz): median=%.4f, mean=%.4f, std=%.4f\n', ...
    alphaBand(1), alphaBand(2), median(controlAlphaScalar), mean(controlAlphaScalar), std(controlAlphaScalar));
fprintf('CP alpha coherence (%.1f-%.1f Hz): median=%.4f, mean=%.4f, std=%.4f\n', ...
    alphaBand(1), alphaBand(2), median(cpAlphaScalar), mean(cpAlphaScalar), std(cpAlphaScalar));

fprintf('\n=== SCALAR TESTS ===\n');
[pWilcox, ~, statsWilcox] = ranksum(controlAlphaScalar, cpAlphaScalar);
[~, pTtest, ciTtest, statsTtest] = ttest2(controlAlphaScalar, cpAlphaScalar);
fprintf('Wilcoxon p = %.6f, ranksum = %d\n', pWilcox, statsWilcox.ranksum);
fprintf('t-test p = %.6f, t = %.4f, df = %d, CI = [%.4f, %.4f]\n', ...
    pTtest, statsTtest.tstat, statsTtest.df, ciTtest(1), ciTtest(2));

fprintf('\n=== BOKIL TWO-GROUP TEST ===\n');
fprintf('Frequency vector: %d bins, range [%.2f, %.2f] Hz, df = %.4f Hz\n', ...
    numel(f), f(1), f(end), median(diff(f)));
fprintf('dz range: [%.4f, %.4f]\n', min(dz), max(dz));
fprintf('Raw bins significant at p < %.3g: %d / %d\n', primaryP, sum(sigMaskRaw), numel(sigMaskRaw));
fprintf('Bins significant after %.1f Hz contiguous criterion: %d / %d\n', ...
    contiguousWidthHz, sum(sigMaskContiguous), numel(sigMaskContiguous));

fprintf('\n=== PRIMARY SIGNIFICANT BANDS ===\n');
print_sig_bands(f, dz, sigMaskContiguous, primaryP);

fprintf('\n=== SENSITIVITY: p < %.3g ===\n', exploratoryP);
fprintf('Raw bins significant at p < %.3g: %d / %d\n', exploratoryP, sum(sigMaskRawExploratory), numel(sigMaskRawExploratory));
fprintf('Bins significant after %.1f Hz contiguous criterion: %d / %d\n', ...
    contiguousWidthHz, sum(sigMaskContiguousExploratory), numel(sigMaskContiguousExploratory));
print_sig_bands(f, dz, sigMaskContiguousExploratory, exploratoryP);

alphaMask = f >= alphaBand(1) & f <= alphaBand(2);
fprintf('\n=== ALPHA BAND DIRECTION ===\n');
fprintf('Mean dz in alpha band: %.4f\n', mean(dz(alphaMask), 'omitnan'));
fprintf('(Negative dz = controls > CP; Positive dz = CP > controls)\n');

fprintf('\n=== PEAK COHERENCE ===\n');
alphaFreqs = f(alphaMask);
[peakCtrl, idxCtrl] = max(controlMedianCoherence(alphaMask));
[peakCP, idxCP] = max(cpMedianCoherence(alphaMask));
fprintf('Control peak alpha coherence: %.4f at %.1f Hz\n', peakCtrl, alphaFreqs(idxCtrl));
fprintf('CP peak alpha coherence: %.4f at %.1f Hz\n', peakCP, alphaFreqs(idxCP));

end

function print_sig_bands(f, dz, mask, alphaThreshold)
    d = diff([0; mask(:); 0]);
    starts = find(d == 1);
    ends = find(d == -1) - 1;

    if isempty(starts)
        fprintf('No frequency bands survived p < %.3g with contiguous filtering.\n', alphaThreshold);
        return;
    end

    for r = 1:numel(starts)
        fprintf('Significant band: %.1f - %.1f Hz (%.1f Hz wide, max |dz| = %.2f)\n', ...
            f(starts(r)), f(ends(r)), f(ends(r)) - f(starts(r)), max(abs(dz(starts(r):ends(r)))));
    end
end
