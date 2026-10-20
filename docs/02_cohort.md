[All pages](README.md) · [Figure gallery](figures.md)

# Stage 02: band power per subject and cohort definition

**Question this stage answers:** how is each child's spectrum reduced to delta, theta and
alpha band power, and which children meet the inclusion criteria?

> [!IMPORTANT]
> **24 children are analysed (12 Control and 12 CP), aged 10–16 and all recorded under sevoflurane.**
> Each child gets one delta (1–4 Hz), theta (4–8 Hz) and alpha (8–13 Hz) power value, the mean of four 30 s pieces.
> This table feeds the state-space model (stage 06), and every stage takes its children from the same cohort definition.

## The method, in words
Cut each child's 2 minutes into four 30 s pieces and take the area under each piece's spectrum over each band.
Average the four pieces to get one number per band per child.
Only children who pass the shared cohort rules (and have all four pieces) are kept.

## Where the sub-epochs come from (stage 01)
The 120 s epoch is cut into **4 × 30 s** pieces, each with its own multitaper spectrum
($TW = 4$, $K = 7$, so $W = 4/30 \approx 0.13$ Hz) and its own 2,000-draw bootstrap.
Shorter pieces mean coarser frequency resolution, but they give 4 looks at each child instead of 1.

## The steps, in equations

### 1. Integrate each band ([`integrate_subepoch_band`](../analyses/primary/02_cohort/extract_band_power_subepochs.m#L118))
Band power is the **area under the linear spectrum**, then converted to dB:

```math
P_{\text{band}} = 10\log_{10}\!\int_{f_\text{lo}}^{f_\text{hi}} \hat S(f)\,df
```

(numerically `trapz` over the frequency bins in the band).
It also does the same integral on each of the 2,000 bootstrap spectra and keeps their variance (`*_mfdb_var`), which measures how uncertain each 30 s band power is.

### 2. Who gets in ([lines 63–72](../analyses/primary/02_cohort/extract_band_power_subepochs.m#L63))
A subject is included if both hold:
- they are in **`get_cohort()`**, the single cohort definition used by every stage
  ([shared/cohort_criteria.m](../shared/cohort_criteria.m)), which requires sevoflurane, age **10–16 years**,
  channel **F3** (the two children without a usable F3 are out) and at least **120 s** of EEG
- they have exactly **4** sub-epochs

The result is **24 subjects, 12 Control and 12 CP.**

### 3. Collapse 4 sub-epochs → 1 number per subject

```math
\bar P_{\text{subject}} = \frac{1}{4}\sum_{j=1}^{4} P_j \quad(\text{in dB})
```

The within-subject SD and range and the "empirical SEM variance" $\operatorname{var}(P_j)/4$ are also saved as diagnostics, but the main model does not use them.

## Settings
| Setting | Value | Meaning |
|---|---|---|
| Bands | delta 1–4, theta 4–8, **alpha 8–13 Hz** | edges in [state_space_bands.m](../analyses/primary/06_state_space_model/state_space_bands.m), shared with stage 06 |
| Sub-epochs | 4 × 30 s, $TW = 4$, $K = 7$ | ±0.13 Hz resolution |
| Bootstrap | 2,000 spectra per sub-epoch | for the `*_mfdb_var` columns |
| Collapse | mean of the 4 sub-epochs, in dB | one row per child |

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

**Upper bound.** If every ⚠️/❌ case were resolved in favour of inclusion, CP could go from
**12 → 19**. Controls stay at 12, because every eligible control is already in except the one with 60 s of data.

**Confirmed along the way.** One control has no F4 channel, which is why the coherence
cohort (stage 05) has 23 children.

## Questions to revisit
- Averaging the 4 sub-epochs **in dB** is a geometric mean of linear power, which is a
  bit lower than the arithmetic mean. Fine, but worth saying in the methods.
- The original `collapse_...m` header still says "76 rows → 19 rows" (old cohort). Fix the
  comment in the readability pass.

## Code and files
- **Code:** [extract_band_power_subepochs.m](../analyses/primary/02_cohort/extract_band_power_subepochs.m)
  → [collapse_subepoch_power_table_for_ssm.m](../analyses/primary/02_cohort/collapse_subepoch_power_table_for_ssm.m).
- **Input:** stage 01 sub-epoch spectra, `outputs/mfdb_subepoch_level/<ID>/<ID>_F3_mfdb_subepochs.mat`.
- **Output:** `outputs/state_space_model/power_table_for_ssm_subepochs.csv` (96 rows = 24 × 4)
  and `..._collapsed.csv` (24 rows). **The collapsed table defines the cohort** for stages 03 and 06.

---
[← 01_subject_spectra](01_subject_spectra.md) · [03_power_spectra →](03_power_spectra.md)
