"""Evaluate nut quality at both image-view and physical-nut level."""
import argparse
import csv
import json
import csv as csv_module
import shutil
from collections import defaultdict
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, ConfusionMatrixDisplay

CLASSES = ['quality_nuts', 'nuts_kernel', 'damaged_nuts']

def main():
    p = argparse.ArgumentParser(); p.add_argument('--model', default='output/nut_quality/nut_quality_model.keras'); p.add_argument('--manifest', default='output/nut_quality/test.csv'); args = p.parse_args()
    here = Path(__file__).resolve().parent; project = here.parent; out = here / 'output/nut_quality'; rows = list(csv.DictReader((here / args.manifest).open(encoding='utf-8')))
    files = [str(project / row['file']) for row in rows]; truth = np.array([int(row['label_id']) for row in rows])
    ds = tf.data.Dataset.from_tensor_slices(files).map(lambda path: tf.image.resize(tf.io.decode_jpeg(tf.io.read_file(path), channels=3), (224,224)), num_parallel_calls=tf.data.AUTOTUNE).batch(32).prefetch(tf.data.AUTOTUNE)
    model = tf.keras.models.load_model(here / args.model); probs = model.predict(ds, verbose=1); predicted = probs.argmax(1)
    image_report = classification_report(truth, predicted, target_names=CLASSES, output_dict=True, zero_division=0)
    image_report_text = classification_report(truth, predicted, target_names=CLASSES, zero_division=0)
    grouped = defaultdict(list); grouped_truth = {}
    for row, probability in zip(rows, probs):
        key = f'{row["label"]}:{row["nut_id"]}'; grouped[key].append(probability); grouped_truth[key] = int(row['label_id'])
    keys = sorted(grouped); nut_probs = np.array([np.mean(grouped[key], axis=0) for key in keys]); nut_truth = np.array([grouped_truth[key] for key in keys]); nut_pred = nut_probs.argmax(1)
    nut_report = classification_report(nut_truth, nut_pred, target_names=CLASSES, output_dict=True, zero_division=0)
    nut_report_text = classification_report(nut_truth, nut_pred, target_names=CLASSES, zero_division=0)
    metrics = {'image_accuracy': accuracy_score(truth, predicted), 'physical_nut_accuracy': accuracy_score(nut_truth, nut_pred), 'test_images': len(rows), 'test_physical_nuts': len(keys), 'image_report': image_report, 'physical_nut_report': nut_report}
    (out/'evaluation.json').write_text(json.dumps(metrics, indent=2), encoding='utf-8')
    (out/'classification_report.json').write_text(json.dumps({'image_view': image_report, 'physical_nut': nut_report}, indent=2), encoding='utf-8')
    (out/'classification_report.txt').write_text(f'IMAGE-VIEW REPORT\n{image_report_text}\nPHYSICAL-NUT REPORT\n{nut_report_text}', encoding='utf-8')
    misclassified = []
    for index in np.where(predicted != truth)[0]:
        confidence = float(probs[index, predicted[index]])
        misclassified.append({'file': rows[index]['file'], 'nut_id': rows[index]['nut_id'],
            'true_label': CLASSES[truth[index]], 'predicted_label': CLASSES[predicted[index]], 'confidence': confidence})
    misclassified.sort(key=lambda row: row['confidence'], reverse=True)
    mis_dir = out/'misclassified'; mis_dir.mkdir(exist_ok=True)
    for old in mis_dir.glob('*'): old.unlink()
    selected = misclassified[:60]
    for index, row in enumerate(selected):
        # Filename encodes true label, predicted label, confidence, nut_id and
        # the original filename so a reviewer can triage without the CSV.
        source = project/row['file']; original = source.stem
        conf = f'{round(row["confidence"]*100):03d}'
        target = mis_dir/(f'{index:02d}_true-{row["true_label"]}_pred-{row["predicted_label"]}'
                          f'_conf-{conf}_nut-{row["nut_id"]}_{original}{source.suffix}')
        shutil.copy2(source, target); row['saved_file'] = str(target.relative_to(out))
    with (out/'misclassified.csv').open('w', newline='', encoding='utf-8') as handle:
        writer = csv_module.DictWriter(handle, fieldnames=['file','nut_id','true_label','predicted_label','confidence','saved_file']); writer.writeheader(); writer.writerows(selected)
    confusion_pairs = {}
    for row in misclassified:
        key = f'{row["true_label"]} -> {row["predicted_label"]}'; confusion_pairs[key] = confusion_pairs.get(key, 0) + 1
    ordered_pairs = dict(sorted(confusion_pairs.items(), key=lambda item: item[1], reverse=True))
    (out/'failure_analysis.json').write_text(json.dumps({'total_misclassified_views': len(misclassified), 'confusion_pairs': ordered_pairs, 'saved_images': len(selected), 'gallery_dir': 'misclassified', 'top_csv': 'misclassified.csv'}, indent=2), encoding='utf-8')
    md = ['# Nut-quality failure analysis', '',
          f'- Test images: **{len(rows)}** | misclassified views: **{len(misclassified)}** '
          f'(single-view accuracy {metrics["image_accuracy"]*100:.2f}%).',
          f'- After averaging ten views per physical nut, accuracy rises to '
          f'**{metrics["physical_nut_accuracy"]*100:.2f}%**.',
          f'- The `misclassified/` gallery holds the {len(selected)} highest-confidence errors '
          '(filenames encode true/pred/confidence/nut_id/original).', '',
          '## Confusion pairs (true -> predicted)', '',
          '| Pair | Count |', '|---|---:|']
    md += [f'| {pair} | {count} |' for pair, count in ordered_pairs.items()]
    top_pair = next(iter(ordered_pairs), None)
    md += ['', '## Main business risk', '',
           f'The dominant error is `{top_pair}`. In single-view mode a damaged nut can '
           'occasionally read as a quality nut, so a quality grade should require either '
           'a confidence margin or several views (use the app multi-view mode) before a '
           'nut is accepted into a quality batch.' if top_pair else 'No misclassifications.']
    (out/'FAILURE_ANALYSIS.md').write_text('\n'.join(md) + '\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in metrics.items() if not k.endswith('report')}, indent=2)); print('\nPhysical-nut report:\n', nut_report_text)
    fig, axes = plt.subplots(1,2,figsize=(12,5)); ConfusionMatrixDisplay(confusion_matrix(truth,predicted), display_labels=CLASSES).plot(ax=axes[0], cmap='Greens', colorbar=False); axes[0].set_title('Image views'); ConfusionMatrixDisplay(confusion_matrix(nut_truth,nut_pred), display_labels=CLASSES).plot(ax=axes[1], cmap='Greens', colorbar=False); axes[1].set_title('Physical nuts (10-view average)'); plt.tight_layout(); plt.savefig(out/'confusion_matrices.png', dpi=160)

if __name__ == '__main__': main()
