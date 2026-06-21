"""Export the nut-quality model to several TFLite variants and compare them.

Produces:
  output/nut_quality/nut_quality_model_float32.tflite
  output/nut_quality/nut_quality_model_dynamic_range.tflite
  output/nut_quality/nut_quality_model_int8.tflite      (if train images exist)
  output/nut_quality/nut_quality_model.tflite           (the chosen mobile default)
  output/nut_quality/export_comparison.json

The dynamic-range model is the mobile default: it keeps a float32 input
(compatible with the on-device preprocessor that feeds raw 0..255 RGB) while
shrinking the weights, so it is the best size/accuracy trade-off for the app.
The full-integer int8 model is exported for reference and benchmarking only;
it expects int8 input and would require a different mobile preprocessing path.
"""
import argparse
import csv
import json
import time
from pathlib import Path

import numpy as np
import tensorflow as tf
from PIL import Image

CLASSES = ['quality_nuts', 'nuts_kernel', 'damaged_nuts']
DEFAULT_VARIANT = 'dynamic_range'


def load_rows(manifest, project, limit=None, stride=False):
    rows = list(csv.DictReader(manifest.open(encoding='utf-8')))
    if limit and len(rows) > limit:
        # Stride-sample so every class is represented (manifests are class-ordered).
        rows = rows[::max(1, len(rows) // limit)][:limit] if stride else rows[:limit]
    return rows, [project / r['file'] for r in rows]


def load_image(path):
    return np.asarray(
        Image.open(path).convert('RGB').resize((224, 224)), dtype=np.float32
    )[None, ...]


def representative_dataset(paths):
    def gen():
        for path in paths:
            yield [load_image(path)]
    return gen


def convert(model, optimizations=None, rep=None, full_int8=False):
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    if optimizations:
        converter.optimizations = optimizations
    if rep is not None:
        converter.representative_dataset = rep
    if full_int8:
        converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
        converter.inference_input_type = tf.int8
        converter.inference_output_type = tf.int8
    return converter.convert()


def tflite_accuracy(model_bytes, paths, truth):
    interpreter = tf.lite.Interpreter(model_content=model_bytes)
    interpreter.allocate_tensors()
    inp = interpreter.get_input_details()[0]
    out = interpreter.get_output_details()[0]
    int8_in = inp['dtype'] == np.int8
    correct = 0
    start = time.perf_counter()
    for path, label in zip(paths, truth):
        image = load_image(path)
        if int8_in:
            scale, zero = inp['quantization']
            image = np.clip(np.round(image / scale + zero), -128, 127).astype(np.int8)
        interpreter.set_tensor(inp['index'], image)
        interpreter.invoke()
        pred = int(interpreter.get_tensor(out['index'])[0].argmax())
        correct += int(pred == label)
    elapsed = time.perf_counter() - start
    return correct / len(paths), (elapsed / len(paths)) * 1000.0


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', default='output/nut_quality')
    p.add_argument('--accuracy-images', type=int, default=400,
                   help='Test images used to score each variant (0 = skip).')
    p.add_argument('--rep-images', type=int, default=160,
                   help='Train images for int8 representative dataset.')
    args = p.parse_args()

    here = Path(__file__).resolve().parent
    project = here.parent
    out = here / args.output
    out.mkdir(parents=True, exist_ok=True)

    model = tf.keras.models.load_model(out / 'nut_quality_model.keras')

    rep_paths = []
    rep_manifest = out / 'train.csv'
    if rep_manifest.exists():
        _, rep_paths = load_rows(rep_manifest, project, args.rep_images)

    test_paths, test_truth = [], []
    test_manifest = out / 'test.csv'
    if args.accuracy_images and test_manifest.exists():
        rows, test_paths = load_rows(test_manifest, project, args.accuracy_images, stride=True)
        test_truth = [int(r['label_id']) for r in rows]

    variants = {
        'float32': dict(optimizations=None),
        'dynamic_range': dict(optimizations=[tf.lite.Optimize.DEFAULT]),
    }
    if rep_paths:
        variants['int8'] = dict(
            optimizations=[tf.lite.Optimize.DEFAULT],
            rep=representative_dataset(rep_paths),
            full_int8=True,
        )

    comparison = {'default_variant': DEFAULT_VARIANT, 'variants': {}}
    for name, kwargs in variants.items():
        try:
            blob = convert(model, **kwargs)
        except Exception as exc:  # pragma: no cover - hardware/op support varies
            comparison['variants'][name] = {'error': str(exc)}
            print(f'[{name}] export failed: {exc}')
            continue
        path = out / f'nut_quality_model_{name}.tflite'
        path.write_bytes(blob)
        size_kb = round(len(blob) / 1024, 1)
        entry = {'file': path.name, 'size_kb': size_kb}
        if test_paths:
            acc, ms = tflite_accuracy(blob, test_paths, test_truth)
            entry['test_accuracy'] = round(acc, 4)
            entry['ms_per_image'] = round(ms, 2)
        comparison['variants'][name] = entry
        print(f'[{name}] {size_kb} KB '
              + (f"acc={entry.get('test_accuracy')} "
                 f"{entry.get('ms_per_image')} ms/img" if test_paths else ''))

    default_src = out / f'nut_quality_model_{DEFAULT_VARIANT}.tflite'
    if default_src.exists():
        (out / 'nut_quality_model.tflite').write_bytes(default_src.read_bytes())
        comparison['mobile_default_file'] = 'nut_quality_model.tflite'
        comparison['mobile_default_copied_from'] = default_src.name

    (out / 'export_comparison.json').write_text(
        json.dumps(comparison, indent=2), encoding='utf-8')
    print(json.dumps(comparison, indent=2))


if __name__ == '__main__':
    main()
