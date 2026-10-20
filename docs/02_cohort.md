[All pages](README.md) · [Figure gallery](figures.md)

# Stage 02: band power per subject, and who is in the cohort

**Question this stage answers:** turn each child's spectrum into three numbers
(delta, theta, alpha power), and decide which children are in the analysis.

**Code:** [extract_band_power_subepochs.m](../analyses/primary/02_cohort/extract_band_power_subepochs.m)
→ [collapse_subepoch_power_table_for_ssm.m](../analyses/primary/02_cohort/collapse_subepoch_power_table_for_ssm.m)
**Input:** stage 01 sub-epoch spectra, `outputs/mfdb_subepoch_level/<ID>/<ID>_F3_mfdb_subepochs.mat`
**Output:** `outputs/state_space_model/power_table_for_ssm_subepochs.csv` (96 rows = 24 × 4)
and `..._collapsed.csv` (24 rows). **The collapsed table defines the cohort** for stages 03 and 06.

## Where the sub-epochs come from (stage 01)
The 120 s epoch is cut into **4 × 30 s** pieces, each with its own multitaper spectrum
($TW = 4$, $K = 7$, so $W = 4/30 \approx 0.13$ Hz) and its own 2,000-draw bootstrap.
Shorter pieces mean coarser frequency resolution, but they give 4 looks at each child
instead of 1.

## The steps

### 1. Integrate each band ([`integrate_subepoch_band`](../analyses/primary/02_cohort/extract_band_power_subepochs.m#L118))
Band power is the **area under the linear spectrum**, then converted to dB:

$$
P_{\text{band}} = 10\log_{10}\!\int_{f_\text{lo}}^{f_\text{hi}} \hat S(f)\,df
$$

(numerically `trapz` over the frequency bins in the band).

| Band | Range |
|---|---|
| delta | 1–4 Hz |
| theta | 4–8 Hz |
| alpha | **8–12 Hz** ⚠️ (Figs 3–4 and coherence use 8–13 Hz; see below) |

It also does the same integral on each of the 2,000 bootstrap spectra and keeps their
variance (`*_mfdb_var`): how uncertain that one 30 s band power is.

### 2. Who gets in ([lines 63–72](../analyses/primary/02_cohort/extract_band_power_subepochs.m#L63))
A subject is included if both hold:
- they are in **`get_cohort()`**, the single cohort definition used by every stage
  ([shared/cohort_criteria.m](../shared/cohort_criteria.m)): sevoflurane, age **10–16 years**,
  **F3** present (the two children without a usable F3 are out), at least **120 s** of EEG
- they have exactly **4** sub-epochs

Result: **24 subjects, 12 Control + 12 CP.**

### 3. Collapse 4 sub-epochs → 1 number per subject
$$
\bar P_{\text{subject}} = \frac{1}{4}\sum_{j=1}^{4} P_j \quad(\text{in dB})
$$
Also saved as diagnostics (not used by the main SSM): within-subject SD and range,
and the "empirical SEM variance" $\operatorname{var}(P_j)/4$.

## Cohort audit: is everyone eligible actually included? (2026-10-19)
Traced all **45 EEG files** through every filter.
Every file has a metadata row, and every 10–16 yr sevo subject in the metadata has a file.

| Dropped | Reason | Justified? |
|---|---|---|
| 11 | under 10 yr | ✅ by design |
| 2 | propofol, not sevo | ✅ by design |
| 3 | over 16.0 yr (two of them by under 0.1 yr) | ⚠️ depends on what "10–16" means: if it means "16-year-olds included" (age < 17), all three are in |
| 3 | birthdate missing in the metadata | ❌ unknown true age |
| 1 | F3 removed as a bad channel; F4 is fine | ⚠️ the 120 s analysis used F4 instead; the sub-epoch path requires F3, so it drops here. Defensible, but inconsistent |
| 1 | F3 bad **and** only 60 s of data | ✅ can't make 4 × 30 s sub-epochs |
| **24** | **final cohort** (12 Control + 12 CP) | |

**Upper bound:** if every ⚠️/❌ case resolved in favour of inclusion, CP could go from
**12 → 19**. Controls stay at 12: every eligible control is already in except the one with 60 s of data.

**Confirmed along the way:** one control has no F4 channel, which is why the coherence
cohort (stage 05) has 23 children.

## Questions to revisit
- **Alpha band mismatch:** 8–12 Hz here (feeds SSM Figs 05/06 and the cohort table) vs
  8–13 Hz in Figs 3–4 and coherence. Intentional?
- Averaging the 4 sub-epochs **in dB** is a geometric mean of linear power, which is a
  bit lower than the arithmetic mean. Fine, but worth saying in the methods.
- The original `collapse_...m` header still says "76 rows → 19 rows" (old cohort). Fix the
  comment in the readability pass.

---
[← 01_subject_spectra](01_subject_spectra.md) · [03_power_spectra →](03_power_spectra.md)
