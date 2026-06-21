"""Rank low-confidence and incorrect labeled images for the next review cycle."""
import argparse
import csv
from pathlib import Path
import numpy as np
from PIL import Image
import tensorflow as tf

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']
def main():
    p = argparse.ArgumentParser(); p.add_argument('--model', default='output/agrolens_model.keras'); p.add_argument('--images', required=True); p.add_argument('--output', default='output/hard_examples.csv'); args = p.parse_args()
    model = tf.keras.models.load_model(args.model); rows = []
    for expected in CLASSES:
        for path in (Path(args.images) / expected).glob('*'):
            try: x = np.asarray(Image.open(path).convert('RGB').resize((224,224)), dtype=np.float32)[None,...]
            except Exception: continue
            probs = model.predict(x, verbose=0)[0]; index = int(probs.argmax()); predicted = CLASSES[index]; confidence = float(probs[index])
            if predicted != expected or confidence < .75: rows.append([str(path), expected, predicted, confidence, 'incorrect' if predicted != expected else 'low_confidence'])
    rows.sort(key=lambda row: (row[4] != 'incorrect', row[3]))
    out = Path(args.output); out.parent.mkdir(exist_ok=True)
    with out.open('w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f); writer.writerow(['file','expected','predicted','confidence','reason']); writer.writerows(rows)
    print(f'Queued {len(rows)} hard examples in {out}. Review labels before retraining.')
if __name__ == '__main__': main()

