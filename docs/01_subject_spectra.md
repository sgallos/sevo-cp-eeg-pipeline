[All pages](README.md) · [Figure gallery](figures.md)

# Stage 01: one subject's spectrum, plus how sure we are about it

**Question this stage answers:** for one child, what does the power spectrum at F3
look like, and how much would it wobble if we could record the same 2 minutes again?

**Code:** [run_subject_mfdb_bootstrap_for_id.m](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m)
· parameters in [mfdb_config.m](../shared/mfdb_config.m)
**Output:** `outputs/mfdb_subject_level/<ID>/<ID>_F3_mfdb.mat`

## The steps

### 1. Pick the signal ([lines 62–80](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m#L62))
One channel, **F3** (left frontal). If F3 is missing, use **F4** and record that
(`usedFallbackElectrode`). The epoch is **120 s at Fs = 256 Hz**, so $N = 30{,}720$ samples.

### 2. Multitaper spectrum ([line 98](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m#L98), [mtm.m](../shared/mtm.m))
A plain FFT of one window gives a very noisy spectrum. Multitaper fixes this by
looking at the same data through $K$ different, nearly independent "windows" (tapers $h_k$)
and averaging:

$$
X_k(f) = \sum_{t=1}^{N} h_k(t)\, x(t)\, e^{-i 2\pi f t / F_s},
\qquad
\hat S(f) = \frac{1}{K}\sum_{k=1}^{K} \frac{|X_k(f)|^2}{F_s}
$$

| Parameter | Value | Meaning |
|---|---|---|
| $TW$ | 6 | time–bandwidth product |
| $K$ | 11 | number of tapers ($2TW - 1$) |
| half-bandwidth $W$ | $TW/T = 6/120 = 0.05$ Hz | frequency resolution: features closer than ~0.1 Hz blur together |
| `fpass` | [1, 40] Hz | frequencies kept |

Result: `S_subject_original_dB` = $10\log_{10}\hat S(f)$. **No randomness here.**

### 3. Frequency-domain bootstrap (MFDB) ([lines 118–143](../analyses/primary/01_subject_spectra/run_subject_mfdb_bootstrap_for_id.m#L118))
Goal: make 2,000 plausible "alternate spectra" for this child, to get a 95% CI.
Idea (Kim et al. 2018): divide each Fourier coefficient
by the spectrum. What's left is roughly **unit-size noise that looks the same at every
frequency**, so it can be shuffled across frequencies.

1. **Whiten:** $\;s_k(f) = \dfrac{X_k(f)}{\sqrt{\hat S(f)/2}}$, splitting real and imaginary parts
   into one stacked vector of length $n_{\text{fft}}$.
2. **Standardize** each taper's vector to mean 0, SD 1.
3. **Resample:** draw $n_{\text{fft}}$ indices with replacement (`bootsam`). The **same indices
   are reused for all $K$ tapers**, which keeps the tapers' relationship intact.
4. **Re-color:** multiply back by $\sqrt{\hat S(f)/2}$ and average $|X_k^*(f)|^2$ over tapers.
5. Repeat $B_{\text{subj}} = 2000$ times → `S_subject_boot_dB` (2000 × 4681).

The 2.5th and 97.5th percentiles across those 2,000 spectra are the 95% CI.

> **Subtle point:** `mtm.m` divides $\hat S$ by $F_s$ but not $X_k$, so
> step 1 is off by a constant $\sqrt{F_s}$. Step 2 (z-scoring) removes any constant
> factor, so it cancels. Not a bug, but it's an accident of ordering, not a design choice.

---
[02_cohort →](02_cohort.md)
