# AgroLens Nut-Quality Dataset Card

> **Scope:** Close-up hazelnut quality grading only. This dataset does not cover
> leaf disease, fungal spot, stink-bug injury, or fruit rot.

## Overview

15,770 close-up images of 1,577 physical hazelnuts, ten angles per nut. One
canonical label system is used everywhere (ML, `labels.txt`, recommendations,
app, docs): `quality_nuts`, `nuts_kernel`, `damaged_nuts`. Display strings live
separately in `mobile/assets/nut_quality_display_labels.json` and never change
the underlying ids.

| Class (canonical) | Images | Physical nuts |
|---|---:|---:|
| quality_nuts | 5,350 | 535 |
| nuts_kernel | 5,230 | 523 |
| damaged_nuts | 5,190 | 519 |

The source CSV has a filename inconsistency for the damaged class
(`damaged_nuts_` vs actual `damaged_nut_`); `prepare_nut_quality.py` resolves it
without altering the source files.

## Leakage-safe split

All ten views of a physical `nut_id` stay in the same split (`prepare_nut_quality.py`
groups by `(class, nut_id)` before assigning splits):

| Split | Images | Physical nuts |
|---|---:|---:|
| Train | 11,030 | 1,103 |
| Validation | 2,360 | 236 |
| Test | 2,380 | 238 |

Audit (`ml/output/nut_quality/audit.json`): **zero** corrupt images, **zero**
exact duplicates, **zero** physical-nut leakage. The preparation script exits
non-zero if any of these checks fail.

## Known risks and limitations

- Consistent close-up backgrounds can inflate performance relative to real field
  photos. An external Samegrelo phone-photo test set is recommended before
  production (`ml/evaluate_external_test.py`,
  `sample_data/external_samegrelo_test/`).
- Ten views improve physical-nut aggregation but are not ten independent samples.
- No `unknown`/non-nut class exists yet, so out-of-domain inputs are forced into
  one of the three classes; the app mitigates this with confidence and
  multi-view agreement thresholds, not a model-level rejection.
- The dataset captures only **visible** condition: it cannot represent flavor,
  rancidity, aflatoxins, or invisible internal defects.

## License

Review the source dataset license before redistribution. The plant-health
candidate media under `sample_data/raw_candidates/` is tracked separately in
`sources.json` with per-image licensing and is **not** part of this nut-quality
dataset.
