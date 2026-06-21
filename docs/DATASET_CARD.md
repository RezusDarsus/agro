# AgroLens Dataset Card

## Nut-quality dataset

The trained model uses 15,770 close-up images representing 1,577 physical hazelnuts, with ten angles per nut. See [the nut-quality dataset card](DATASET_CARD_NUT_QUALITY.md) for full detail. The canonical class ids below are used everywhere; display strings live in `mobile/assets/nut_quality_display_labels.json`.

| Class (canonical) | Images | Physical nuts | Display name |
|---|---:|---:|---|
| quality_nuts | 5,350 | 535 | Quality hazelnut (in shell) |
| nuts_kernel | 5,230 | 523 | Hazelnut kernel |
| damaged_nuts | 5,190 | 519 | Damaged hazelnut |

The source CSV contains a filename error for the damaged class (`damaged_nuts_` versus actual `damaged_nut_`). The preparation script resolves it without altering the source.

All ten views of a physical `nut_id` stay in the same split:

| Split | Images | Physical nuts |
|---|---:|---:|
| Train | 11,030 | 1,103 |
| Validation | 2,360 | 236 |
| Test | 2,380 | 238 |

Audit results: zero corrupt images, zero exact duplicates, and zero physical-nut leakage. The dataset uses a consistent close-up setup and does not contain an unknown/non-nut class. See the source dataset license before redistribution.

## Plant-health candidates

`sample_data/raw_candidates/` also contains licensed candidate media for the future plant-health model. `sources.json` records image-level source and license information. These labels are proposed, not expert-approved. Stink-bug candidates often show insects rather than feeding injury; fruit-rot candidates may be non-hazelnut hosts; fungal candidates may include non-field views.

Only rows marked `approved` by a qualified reviewer in `ml/output/agronomist_review.csv` may be copied by `prepare_approved_dataset.py` into a reviewed dataset. Do not mix these candidates with the three-class nut-quality training data.

## Known risks

- Consistent backgrounds can inflate performance relative to real field images.
- Ten views improve physical-nut aggregation but are not ten independent samples.
- Internet candidate labels require agronomist verification.
- No current model detects blueberry, chemical contamination, flavor, rancidity, aflatoxins, or invisible internal defects.
