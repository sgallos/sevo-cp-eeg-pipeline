"""Fit specparam (FOOOF, Donoghue et al. 2020) to every usable channel of every child.

Run after export_spectra_for_specparam.m, from the repo root:
    python analyses/additional/topoplots/fit_specparam.py

The settings were fixed before looking at any fit. 2-30 Hz is the main range, because a
low edge can cut the slow and delta peaks of sevoflurane; the others test the range.
Peak height is in dB above the fitted background. A child with no peak from 7 to 13 Hz
gets height 0, so it stays in the maps.
"""
import csv
from pathlib import Path

import numpy as np
from fooof import FOOOF

RANGES = {"main": (2, 30), "low": (1, 30), "wide": (2, 40)}
ALPHA = (7, 13)
SETTINGS = dict(peak_width_limits=(1, 8), max_n_peaks=6, min_peak_height=0.1, aperiodic_mode="fixed", verbose=False)

folder = Path("outputs/additional/topoplots")
with open(folder / "spectra_for_specparam.csv") as f:
    reader = csv.reader(f)
    header = next(reader)
    freqs = np.array([float(name[1:]) for name in header[2:]])
    rows = list(reader)

with open(folder / "specparam_fits.csv", "w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["subjectID", "channel", "fitRange", "exponent", "offset", "alphaFrequency",
                     "alphaHeight", "hasPeak", "r2", "fitError"])
    for row in rows:
        spectrum = np.array(row[2:], dtype=float)
        for name, limits in RANGES.items():
            fm = FOOOF(**SETTINGS)
            fm.fit(freqs, spectrum, list(limits))
            peaks = fm.get_params("peak_params")
            peaks = np.atleast_2d(peaks) if np.size(peaks) else np.empty((0, 3))
            inAlpha = peaks[(peaks[:, 0] >= ALPHA[0]) & (peaks[:, 0] <= ALPHA[1])]
            hasPeak = len(inAlpha) > 0
            best = inAlpha[np.argmax(inAlpha[:, 1])] if hasPeak else [np.nan, 0.0, np.nan]
            offset, exponent = fm.get_params("aperiodic_params")
            writer.writerow([row[0], row[1], name, exponent, 10 * offset, best[0], 10 * best[1],
                             int(hasPeak), fm.r_squared_, fm.error_])
