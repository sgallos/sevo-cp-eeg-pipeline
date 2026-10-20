[All pages](README.md) · [Figure gallery](figures.md)

# Stage 01: single-subject spectrum and its uncertainty

**Question this stage answers:** for each child, what is the F3 power spectrum, and how
precisely is it estimated from a 2-minute recording?

> [!IMPORTANT]
> **Each child gets one smooth spectrum (multitaper) and 2,000 plausible "alternate" spectra (frequency-domain bootstrap).**
> The alternates give a 95% CI about ±2 dB wide per frequency for one 2-minute recording.
> Every later stage builds on these two outputs.

## The method, in words
A plain FFT of one recording gives a very noisy spectrum.
Multitaper looks at the same data through several different, nearly independent "windows" and averages them, which smooths the noise.
To know how uncertain that spectrum is, the frequency-domain bootstrap (MFDB) makes alternate spectra that the same child could plausibly have produced.
It does this by removing the spectrum's shape, shuffling the leftover noise across frequencies, and putting the shape back.

## The steps, in equations

### 1. Pick the signal ([lines 62–80](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m#L62))
One channel, **F3** (left frontal).
If F3 is missing, use **F4** and record that (`usedFallbackElectrode`).
The epoch is **120 s at Fs = 256 Hz**, so $N = 30{,}720$ samples.

### 2. Multitaper spectrum ([line 98](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m#L98), [mtm.m](../shared/mtm.m))
Average over $K$ tapers $h_k$:

```math
X_k(f) = \sum_{t=1}^{N} h_k(t)\, x(t)\, e^{-i 2\pi f t / F_s}
```

```math
\hat S(f) = \frac{1}{K}\sum_{k=1}^{K} \frac{|X_k(f)|^2}{F_s}
```

The result, `S_subject_original_dB`, is $10\log_{10}\hat S(f)$. **This step involves no randomness.**

### 3. Frequency-domain bootstrap (MFDB) ([lines 118–143](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m#L118))
The idea (Kim et al. 2018) is to divide each Fourier coefficient by the spectrum.
What's left is roughly **unit-size noise that looks the same at every frequency**, so it can be shuffled across frequencies.

1. **Whiten.** Compute $s_k(f) = \dfrac{X_k(f)}{\sqrt{\hat S(f)/2}}$, splitting real and imaginary parts into one stacked vector of length $n_{\text{fft}}$.
2. **Standardize** each taper's vector to mean 0, SD 1.
3. **Resample.** Draw $n_{\text{fft}}$ indices with replacement (`bootsam`). The **same indices are reused for all $K$ tapers**, which keeps the tapers' relationship intact.
4. **Re-color.** Multiply back by $\sqrt{\hat S(f)/2}$ and average $|X_k^*(f)|^2$ over tapers.
5. Repeat $B_{\text{subj}} = 2000$ times → `S_subject_boot_dB` (2000 × 4681).

The 2.5th and 97.5th percentiles across those 2,000 spectra are the 95% CI.

<details>
<summary><b>A subtle point about the whitening step</b></summary>

> **Subtle point.** `mtm.m` divides $\hat S$ by $F_s$ but not $X_k$, so
> step 1 is off by a constant $\sqrt{F_s}$. Step 2 (z-scoring) removes any constant
> factor, so it cancels. Not a bug, but it's an accident of ordering, not a design choice.
</details>

## Settings
| Setting | Value | Meaning |
|---|---|---|
| $TW$ | 6 | time–bandwidth product |
| $K$ | 11 | number of tapers ($2TW - 1$) |
| Half-bandwidth $W$ | $TW/T = 6/120 = 0.05$ Hz | frequency resolution: features closer than ~0.1 Hz blur together |
| `fpass` | [1, 40] Hz | frequencies kept |
| $B_{\text{subj}}$ | 2000 | bootstrap spectra per child |
| Random seed | `mfdb_config().randomSeed` | reruns give identical CIs |

## Questions to revisit
- Why shuffle real and imaginary parts together in one pool rather than separately?
- Is pooling across all 1–40 Hz OK when the whitened noise may not be identical everywhere
  (e.g. near the alpha peak)?

## Code and files
- **Code:** [run_subject_mfdb_bootstrap_for_id.m](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m),
  with parameters in [mfdb_config.m](../shared/mfdb_config.m).
- **Output:** `outputs/mfdb_subject_level/<ID>/<ID>_F3_mfdb.mat`.

---
[02_cohort →](02_cohort.md)
