# Global coherence

**Aim.** To show how coordinated activity across the whole montage differs between CP and Control,
and how it is spread over the scalp, beside the band power topoplots.

**Method, following Cornelissen et al. 2018** (Br J Anaesth 120:1274, Methods, "global coherence"):
1. Each child's stage 01 epoch (120 s, Laplacian, 256 Hz) is cut into non-overlapping 2 s windows (60 windows).
2. Each window is linearly detrended and gives a multitaper cross-spectral matrix (TW 2, K 3, the tapers of
   their published code, Cornelissen et al. 2015 eLife Source code 1, since the 2018 paper does not state them).
3. In consecutive blocks of 10 windows, the real and the imaginary part of every entry are replaced by their
   medians ("to remove the noise artefact"). 120 s gives 6 blocks.
4. At each frequency and block the matrix is decomposed. **Global coherence (GC)** is the largest eigenvalue
   over the sum of eigenvalues (Cimenser et al. 2011). **Spatial coherence** at an electrode is |u₁|², the
   squared magnitude of its entry in the leading eigenvector. |u₁|² sums to 1 over the electrodes.
5. Each child's value is the mean over the 6 blocks and over the band's frequencies (delta 1–4, theta 4–8,
   alpha 8–13 Hz, `state_space_bands.m`, as in the power maps). Group values are medians across children.

The decomposition uses `svd`, as their code does. An entry-wise median need not be positive semi-definite, so
a few eigenvalues can be slightly negative; `child_gc.csv` reports the largest share of negative eigenvalue mass
(`maxNegativeShare`) so this can be checked.

**Electrodes.** A child's GC uses the electrodes the topoplots draw (`topoplot_channel_rules.m`) that are clean
in that child: 23 to 35 per child. Only 5 electrodes are clean in all 24 children, so a common set is not
possible. GC cannot fall below 1/N for N electrodes, so it is slightly higher with fewer electrodes; the median
count is 33 in both groups.

| File | Content |
|---|---|
| `gc_settings.m` | Window, tapers, block size |
| `global_coherence_cornelissen.m` | GC and leading eigenvector for one recording |
| `compute_child_gc.m`, `load_child_gc.m` | Every child; computed once and reused (`child_gc.mat`, `child_gc.csv`) |
| `run_gc_group_topoplots.m` | Control, CP, CP − Control (Hedges' g, spatial cluster test) for alpha, delta, theta; band GC in the title (`gc_band_statistics.csv`) |
| `plot_gc_by_age.m` | One map per child, youngest to oldest, with the child's GC |
| `run_gc_state_space_maps.m` | The stage 06 state-space model fitted to |u₁|² at every electrode, maps at ages 11–15, plus the same model on band GC |

Needs EEGLAB and the `topoplots/` folder on the path. Outputs go to `outputs/additional/global_coherence/`.

**Checks.** `tests/test_global_coherence.m`: a rhythm shared by 5 of 20 simulated channels gives GC above 0.9
at its frequency, near noise elsewhere, and puts more than 99% of |u₁|² on those 5 channels; weights sum to 1;
with one window per block the result equals a direct eigendecomposition. On one window, GC and |u₁|² match
Cornelissen's published `pkmtxsptrm` + `svd` to 3e-16 at every frequency from 0 to 30 Hz.

**Where this differs from earlier code.**
- Cornelissen's published code (2015) uses 2 s windows every 3 s and a running median over 5 windows. Their
  2018 Methods say non-overlapping windows and a median over 10. This follows the 2018 Methods.
- The earlier peds_cp version (`GlobalCoherence_corn_sg.m`) has the same core but uses 20 s windows, TW 5 / K 9,
  and a fixed list of 21 dropped channels. Its `U_topo` (magnitude of the mean complex eigenvector) depends on
  the arbitrary phase `svd` gives each eigenvector, so only its `w_topo` (mean |u₁|²) is meaningful.
- The thesis `GC_eig.m` method 0 is the standard GC of Cimenser et al. 2011 on a summed cross-spectral matrix,
  without the median step.

All of this is exploratory and additional; the primary analyses do not change.
