# AgroLens Nut Quality Model Card

> **Scope:** This model is for close-up hazelnut quality grading. It does not
> diagnose leaf disease, fungal spot, stink-bug injury, or fruit rot.

## Purpose

A separate three-class model for close-up hazelnut quality inspection. It must
not replace, and is intentionally not mixed with, the five-class plant-health
flow (which remains in demo mode).

Canonical classes (the exact strings used everywhere — ML, `labels.txt`,
recommendations, app, and docs):

- `quality_nuts` — intact nuts in shell.
- `nuts_kernel` — shelled kernels.
- `damaged_nuts` — visibly damaged nuts in shell.

Display names (presentation only, from `mobile/assets/nut_quality_display_labels.json`):
`quality_nuts → "Quality hazelnut (in shell)"`, `nuts_kernel → "Hazelnut kernel"`,
`damaged_nuts → "Damaged hazelnut"`. There are no synonym class ids.

There is **no `unknown` output**: the model always returns one of the three
classes. Uncertainty is handled at the app level (see "App decision states").

## Dataset management

15,770 images of 1,577 physical nuts, ten views per nut. Splitting individual
images would leak the same physical nut across splits, so AgroLens splits by
`(class, nut_id)` and keeps all ten views together.

- Training: 11,030 images / 1,103 physical nuts.
- Validation: 2,360 images / 236 physical nuts.
- Test: 2,380 images / 238 physical nuts.
- Corrupt images: 0. Exact duplicate images: 0. Physical-nut leakage: 0.

## Architecture and training

MobileNetV2 (ImageNet weights), 224×224 RGB input, in-graph preprocessing and
augmentation, global average pooling, dropout 0.3, three-class softmax. Eight
epochs frozen transfer learning, then three epochs fine-tuning the final 30
layers at a lower learning rate. Preprocessing is inside the model graph, so the
exported TFLite model consumes raw 0–255 RGB.

## Final metrics (untouched test split)

- **Single-image accuracy: 94.79%** (2,380 images).
- **Physical-nut multi-view accuracy: 98.74%** (238 nuts, ten-view average).
- **Physical-nut macro F1: ≈ 0.9874.**

Physical-nut per-class results:

| Class | Precision | Recall | F1 | Nuts |
|---|---:|---:|---:|---:|
| quality_nuts | 0.96 | 1.00 | 0.98 | 81 |
| nuts_kernel | 1.00 | 1.00 | 1.00 | 79 |
| damaged_nuts | 1.00 | 0.96 | 0.98 | 78 |

## App decision states

The app converts a raw prediction into one of three states:

- `confident` — top probability ≥ 0.70 and no damage flag.
- `uncertain` — top probability < 0.70 → "Uncertain — retake photo."
- `manual_review_required` — predicted `quality_nuts` but P(`damaged_nuts`) > 0.20
  → "Possible damage — manual inspection recommended."

Multi-view mode additionally downgrades to manual review when fewer than 70% of
views agree with the averaged result.

## TFLite export variants

`export_nut_quality_tflite.py` produces three variants and records
`export_comparison.json` (sizes and a stratified 400-image accuracy check):

| Variant | File | Size | Test acc | Input |
|---|---|---:|---:|---|
| float32 | `nut_quality_model_float32.tflite` | ~8.5 MB | ~0.945 | float32 |
| **dynamic_range (default)** | `nut_quality_model_dynamic_range.tflite` | ~2.5 MB | ~0.943 | float32 |
| int8 (full integer) | `nut_quality_model_int8.tflite` | ~2.6 MB | ~0.948 | int8 |

The **dynamic-range** model is the mobile default (`nut_quality_model.tflite`):
near-float accuracy at ~1/3 the size while keeping a float32 input compatible
with the on-device preprocessor. The int8 model is exported for benchmarking;
using it would require an int8 input path in the app.

## Keras ↔ TFLite validation

`validate_nut_quality_tflite.py` compares Keras vs the deployed TFLite model on a
stratified ≥30-image sample and writes `tflite_validation.json` (per-image true
label, both predictions, max abs probability difference, PASS/FAIL). Latest run:
**29/30 argmax agreement**, mean probability difference ≈ 0.015 (the single flip
is a borderline case shifted by dynamic-range quantization).

## Failure analysis (main business risk)

124 of 2,380 single views were misclassified. The dominant error is
**`damaged_nuts → quality_nuts`**: a damaged nut can occasionally read as a
quality nut in single-view mode. Ten-view aggregation removes most of this, but 3
of 78 damaged physical nuts were still missed. A quality grade should therefore
require a confidence margin or several views (use the app's multi-view mode)
before a nut is accepted into a quality batch. See
`ml/output/nut_quality/FAILURE_ANALYSIS.md` and the `misclassified/` gallery
(filenames encode true/predicted/confidence/nut_id/original).

## Limitations

Consistent close-up background and acquisition setup; accuracy may fall on field
photos, other phones, lighting, backgrounds, varieties, or damage types absent
from training. The model does not assess taste, rancidity, aflatoxins, or
internal chemistry, and has no non-nut rejection class. Before production,
collect an external Samegrelo test set (`evaluate_external_test.py`) and add an
`unknown/non-nut` rejection stage.

## Artifacts

- `ml/output/nut_quality/nut_quality_model.keras`
- `ml/output/nut_quality/nut_quality_model.tflite` (mobile default = dynamic range)
- `ml/output/nut_quality/nut_quality_model_{float32,dynamic_range,int8}.tflite`
- `ml/output/nut_quality/export_comparison.json`
- `ml/output/nut_quality/evaluation.json`
- `ml/output/nut_quality/classification_report.{txt,json}`
- `ml/output/nut_quality/confusion_matrices.png`
- `ml/output/nut_quality/tflite_validation.json`
- `ml/output/nut_quality/misclassified.csv` and `misclassified/`
- `ml/output/nut_quality/FAILURE_ANALYSIS.md`
