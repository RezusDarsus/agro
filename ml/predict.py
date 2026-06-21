import argparse
from pathlib import Path
import numpy as np
from PIL import Image
import tensorflow as tf

def main():
    p = argparse.ArgumentParser(); p.add_argument('--model', default='output/agrolens_model.keras'); p.add_argument('--image', required=True); args = p.parse_args()
    model = tf.keras.models.load_model(args.model)
    labels = (Path(args.model).parent / 'labels.txt').read_text().splitlines()
    image = np.asarray(Image.open(args.image).convert('RGB').resize((224, 224)), dtype=np.float32)[None, ...]
    probs = model.predict(image, verbose=0)[0]; order = np.argsort(probs)[::-1]
    top = order[0]; predicted = labels[top] if probs[top] >= .65 else 'unknown'
    print(f'Prediction: {predicted}\nConfidence: {probs[top]:.2f}\nTop probabilities:')
    for i in order: print(f'  {labels[i]}: {probs[i]:.2f}')
if __name__ == '__main__': main()

