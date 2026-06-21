"""Compare Keras vs TFLite predictions on a sample of held-out test images.

Writes output/nut_quality/tflite_validation.json with, for each image:
  file, true_label, keras_prediction, tflite_prediction,
  max_abs_prob_diff, status (PASS/FAIL)
plus an aggregate summary. A row passes when the Keras and TFLite argmax agree.
"""
import argparse
import csv
import json
from pathlib import Path

import numpy as np
import tensorflow as tf
from PIL import Image

CLASSES = ['quality_nuts', 'nuts_kernel', 'damaged_nuts']


def load_image(path):
    return np.asarray(
        Image.open(path).convert('RGB').resize((224, 224)), dtype=np.float32
    )[None, ...]


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--model', default='output/nut_quality/nut_quality_model.keras')
    p.add_argument('--tflite', default='output/nut_quality/nut_quality_model.tflite')
    p.add_argument('--images', type=int, default=30,
                   help='Minimum number of test images to validate.')
    args = p.parse_args()

    here = Path(__file__).resolve().parent
    project = here.parent
    out = here / 'output/nut_quality'

    rows = list(csv.DictReader((out / 'test.csv').open(encoding='utf-8')))
    # Spread the sample across the test set rather than taking only the first N.
    count = max(args.images, 30)
    if len(rows) > count:
        step = len(rows) // count
        rows = rows[::step][:count]

    keras_model = tf.keras.models.load_model(here / args.model)
    interpreter = tf.lite.Interpreter(model_path=str(here / args.tflite))
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()[0]
    res = interpreter.get_output_details()[0]

    report = []
    for row in rows:
        image = load_image(project / row['file'])
        keras_probs = keras_model.predict(image, verbose=0)[0]
        interpreter.set_tensor(inp['index'], image)
        interpreter.invoke()
        lite_probs = interpreter.get_tensor(res['index'])[0]
        keras_pred = CLASSES[int(keras_probs.argmax())]
        tflite_pred = CLASSES[int(lite_probs.argmax())]
        diff = float(np.max(np.abs(keras_probs - lite_probs)))
        report.append({
            'file': row['file'],
            'true_label': row['label'],
            'keras_prediction': keras_pred,
            'tflite_prediction': tflite_pred,
            'max_abs_prob_diff': round(diff, 6),
            'status': 'PASS' if keras_pred == tflite_pred else 'FAIL',
        })

    passed = sum(r['status'] == 'PASS' for r in report)
    summary = {
        'images_validated': len(report),
        'agreement': f'{passed}/{len(report)}',
        'all_passed': passed == len(report),
        'max_prob_diff_overall': round(max(r['max_abs_prob_diff'] for r in report), 6),
        'mean_prob_diff': round(
            sum(r['max_abs_prob_diff'] for r in report) / len(report), 6),
    }
    payload = {'summary': summary, 'rows': report}
    (out / 'tflite_validation.json').write_text(
        json.dumps(payload, indent=2), encoding='utf-8')
    print(json.dumps(summary, indent=2))


if __name__ == '__main__':
    main()
