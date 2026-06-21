"""Evaluate the nut-quality model on a manually collected external test set.

Expected layout (real Samegrelo phone photos, no nut_id grouping required):

  sample_data/external_samegrelo_test/
    quality_nuts/*.jpg
    nuts_kernel/*.jpg
    damaged_nuts/*.jpg

Outputs (under ml/output/nut_quality/):
  external_test_report.json
  external_confusion_matrix.png

If the folder is missing or empty the script exits cleanly with a message,
so it is safe to keep in the pipeline before such data has been collected.
"""
import argparse
import json
from pathlib import Path

import numpy as np
import tensorflow as tf
from PIL import Image
import matplotlib.pyplot as plt
from sklearn.metrics import (accuracy_score, classification_report,
                             confusion_matrix, ConfusionMatrixDisplay)

CLASSES = ['quality_nuts', 'nuts_kernel', 'damaged_nuts']
EXTS = {'.jpg', '.jpeg', '.png', '.bmp', '.webp'}


def collect(root):
    items = []
    for label_id, label in enumerate(CLASSES):
        folder = root / label
        if not folder.is_dir():
            continue
        for path in sorted(folder.iterdir()):
            if path.suffix.lower() in EXTS:
                items.append((path, label_id))
    return items


def load_image(path):
    return np.asarray(
        Image.open(path).convert('RGB').resize((224, 224)), dtype=np.float32
    )[None, ...]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--data', default='../sample_data/external_samegrelo_test')
    p.add_argument('--model', default='output/nut_quality/nut_quality_model.keras')
    args = p.parse_args()

    here = Path(__file__).resolve().parent
    out = here / 'output/nut_quality'
    root = (here / args.data).resolve()

    if not root.is_dir():
        print(f'External test set not found at {root}. '
              f'Add images under {"/".join(CLASSES)} subfolders to enable it.')
        return

    items = collect(root)
    if not items:
        print(f'No images found under {root}. Expected subfolders: '
              + ', '.join(CLASSES))
        return

    model = tf.keras.models.load_model(here / args.model)
    truth = np.array([label for _, label in items])
    preds, confidences = [], []
    for path, _ in items:
        probs = model.predict(load_image(path), verbose=0)[0]
        preds.append(int(probs.argmax()))
        confidences.append(float(probs.max()))
    preds = np.array(preds)

    report = classification_report(
        truth, preds, target_names=CLASSES, output_dict=True, zero_division=0)
    payload = {
        'images': len(items),
        'per_class_counts': {c: int((truth == i).sum()) for i, c in enumerate(CLASSES)},
        'accuracy': float(accuracy_score(truth, preds)),
        'mean_confidence': float(np.mean(confidences)),
        'classification_report': report,
        'note': 'External, real-world test set. Lower numbers than the curated '
                'test set are expected and inform production thresholds.',
    }
    (out / 'external_test_report.json').write_text(
        json.dumps(payload, indent=2), encoding='utf-8')

    ConfusionMatrixDisplay(
        confusion_matrix(truth, preds, labels=list(range(len(CLASSES)))),
        display_labels=CLASSES,
    ).plot(cmap='Greens', colorbar=False)
    plt.title('External Samegrelo test set')
    plt.tight_layout()
    plt.savefig(out / 'external_confusion_matrix.png', dpi=160)

    print(json.dumps({k: v for k, v in payload.items()
                      if k != 'classification_report'}, indent=2))


if __name__ == '__main__':
    main()
