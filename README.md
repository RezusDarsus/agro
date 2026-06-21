# AgroLens Samegrelo

Camera-based, offline-first hazelnut **quality grader** for Samegrelo, Georgia. This hackathon MVP bundles a real, trained TensorFlow Lite model and runs entirely on-device.

> **Scope:** This model is for close-up hazelnut quality grading. It does not diagnose leaf disease, fungal spot, stink-bug injury, or fruit rot.

> Current model status: the app bundles a real, separately trained **nut-quality** TFLite model with one canonical label system — `quality_nuts`, `nuts_kernel`, `damaged_nuts` — used across ML, `labels.txt`, recommendations, app, and docs. Display strings live in `mobile/assets/nut_quality_display_labels.json`. The five-class plant-health flow remains in safe demo mode until expert-reviewed field data supports it; the two tasks are intentionally not mixed.

## Trained nut-quality model

- Dataset: 15,770 images / 1,577 physical nuts / ten views per nut.
- Leakage-safe split: all views of each `nut_id` remain in one split.
- Train: 11,030 images / 1,103 nuts.
- Validation: 2,360 images / 236 nuts.
- Test: 2,380 images / 238 nuts.
- Single-image accuracy: 94.79%.
- Physical-nut multi-view accuracy: 98.74% (averaging ten view probabilities).
- Physical-nut macro F1: ≈ 0.9874.
- TFLite validation: 29/30 predictions matched Keras (one borderline dynamic-range flip).
- **Main risk:** in single-view mode `damaged_nuts` can occasionally be predicted as `quality_nuts`. Use multi-view inspection for important grading decisions.

See the [nut-quality model card](docs/MODEL_CARD_NUT_QUALITY.md), [nut-quality dataset card](docs/DATASET_CARD_NUT_QUALITY.md), and [demo checklist](docs/DEMO_CHECKLIST.md).

## Features

- **Single-image mode** — fast nut-quality prediction (less reliable than multi-view).
- **Multi-view inspection** — average 5–10 photos of one nut, with per-view agreement count.
- **App decision states** — `confident`, `uncertain` (conf < 0.70 → retake), and
  `manual_review_required` (quality nut with P(damaged) > 0.20, or low multi-view agreement).
- Startup integrity check (model present, input shape `[1,224,224,3]`, labels match outputs);
  clear demo/mock mode if it fails instead of pretending.
- Confidence, transparent heuristic severity, Georgian recommendations, and a safety warning.
- Local diagnosis history; no backend, Firebase, account, or paid API.
- MobileNetV2 training, evaluation, multi-variant TFLite export, and validation scripts.

## Screenshots

Add emulator or device captures here after running the app.

## Repository

```text
mobile/       Flutter Material 3 application
ml/           TensorFlow/Keras training and export pipeline
sample_data/  Empty five-class train/val/test dataset structure
docs/         Technical report, formulas, and pitch
```

## Run the Flutter app

Install Flutter 3.22+ and an Android SDK, then:

```bash
cd mobile
flutter pub get
flutter run
```

The checked-in configuration intentionally omits the model asset, so the app starts in demo mode. Camera/gallery access is requested by `image_picker`; a platform created by `flutter create .` supplies the standard Android/iOS wrappers if they are absent.

## Train the model

Python 3.10 or 3.11 is recommended.

For the nut-quality model:

```powershell
cd ml
python prepare_nut_quality.py --root ../sample_data/raw_candidates/nuts
python train_nut_quality.py --epochs 8 --fine-tune-epochs 3
python evaluate_nut_quality.py            # metrics + misclassified gallery + FAILURE_ANALYSIS.md
python export_nut_quality_tflite.py       # float32 / dynamic_range (default) / int8 + export_comparison.json
python validate_nut_quality_tflite.py     # Keras vs TFLite on >=30 images -> tflite_validation.json
python evaluate_external_test.py          # optional: real Samegrelo phone photos, if present
```

The export step writes the dynamic-range model to both
`ml/output/nut_quality/nut_quality_model.tflite` and (when re-bundling)
`mobile/assets/nut_quality_model.tflite`. The model is already bundled, so the
app runs the trained model out of the box; if the asset is missing or fails the
startup integrity check, the app falls back to clearly-labelled demo mode.

To evaluate a real external test set, place phone photos under
`sample_data/external_samegrelo_test/{quality_nuts,nuts_kernel,damaged_nuts}/`
before running `evaluate_external_test.py`; it writes `external_test_report.json`
and `external_confusion_matrix.png`.

For future plant-health data, first approve `agronomist_review.csv`, then run:

```powershell
python prepare_approved_dataset.py
python prepare_dataset.py --source ../sample_data/reviewed --output ../sample_data/dataset
python audit_dataset.py --data ../sample_data/dataset
```

```bash
cd ml
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python train.py --data ../sample_data/dataset
```

Windows activation:

```powershell
.venv\Scripts\activate
```

The data tree must contain images under `train`, `val`, and `test`, with one folder for each of `healthy`, `stink_bug_damage`, `fungal_spot`, `fruit_rot`, and `unknown`.

## Export and enable TFLite

```bash
cd ml
python export_tflite.py
```

This creates `mobile/assets/agrolens_model.tflite` and copies labels. Then uncomment the model asset line in `mobile/pubspec.yaml`, run `flutter pub get`, and rebuild. If the model or labels cannot load, the app safely falls back to mock mode.

Test and evaluate:

```bash
python predict.py --model output/agrolens_model.keras --image path/to/image.jpg
python evaluate.py --model output/agrolens_model.keras --data ../sample_data/dataset/test
```

## Limitations

This is an AI assistant, not a certified agronomist diagnosis. The mock classifier is for UI demos. The severity score is a heuristic rather than measured lesion area. Real deployment requires expert-reviewed regional data, calibrated confidence, device testing, and field validation.
