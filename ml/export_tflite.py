import argparse
from pathlib import Path
import shutil
import tensorflow as tf

def main():
    p = argparse.ArgumentParser(); p.add_argument('--model', default='output/agrolens_model.keras'); p.add_argument('--no-quantize', action='store_true'); args = p.parse_args()
    model = tf.keras.models.load_model(args.model)
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    if not args.no_quantize: converter.optimizations = [tf.lite.Optimize.DEFAULT]
    assets = Path(__file__).resolve().parents[1] / 'mobile' / 'assets'; assets.mkdir(parents=True, exist_ok=True)
    (assets / 'agrolens_model.tflite').write_bytes(converter.convert())
    shutil.copy2('output/labels.txt', assets / 'labels.txt')
    print(f'Exported to {assets / "agrolens_model.tflite"}')
    print('Uncomment the model asset line in mobile/pubspec.yaml, then rebuild the app.')
if __name__ == '__main__': main()

