# AgroLens ML pipeline

The pipeline trains a five-class MobileNetV2 classifier at 224×224. Put images in the documented dataset folders, then run `python train.py --data ../sample_data/dataset`. Use `export_tflite.py` to place the optimized model in the Flutter assets folder. `predict.py` tests one image and `evaluate.py` reports precision, recall, F1 and a confusion matrix.

## Quality-controlled training cycle

1. Place candidate images in class folders under a separate `raw/` directory.
2. Generate the agronomist sheet: `python create_review_manifest.py --source raw`.
3. Have a qualified agronomist approve/correct every disease label. Do not train on pending rows.
4. Copy only approved files into reviewed class folders and run `python prepare_dataset.py --source reviewed`.
5. Enforce counts and leakage checks: `python audit_dataset.py --data ../sample_data/dataset --minimum-per-class 300`.
6. Train with class balancing and final-layer fine-tuning: `python train.py --data ../sample_data/dataset --epochs 20 --fine-tune-epochs 6`.
7. Evaluate only on the untouched test split: `python evaluate.py --data ../sample_data/dataset/test`.
8. Queue failures for expert review: `python mine_hard_examples.py --images ../sample_data/dataset/test`.
9. Add corrected hard examples to the next data collection cycle; never move test images into training.

The `unknown` class must intentionally include people, animals, cartoons, landscapes, distant trees, unrelated crops, objects, screenshots, and poor-quality images. A numerical target is not a substitute for label quality or Samegrelo field coverage.
