import argparse
from pathlib import Path
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from sklearn.metrics import classification_report, confusion_matrix, ConfusionMatrixDisplay

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']
def main():
    p = argparse.ArgumentParser(); p.add_argument('--model', default='output/agrolens_model.keras'); p.add_argument('--data', default='../sample_data/dataset/test'); args = p.parse_args()
    ds = tf.keras.utils.image_dataset_from_directory(args.data, image_size=(224,224), batch_size=32, shuffle=False, label_mode='int', class_names=CLASSES)
    model = tf.keras.models.load_model(args.model); y_true = np.concatenate([y.numpy() for _, y in ds]); y_prob = model.predict(ds, verbose=0); y_pred = y_prob.argmax(1)
    print(classification_report(y_true, y_pred, target_names=CLASSES, zero_division=0)); cm = confusion_matrix(y_true, y_pred)
    print('Confusion matrix:\n', cm); ConfusionMatrixDisplay(cm, display_labels=CLASSES).plot(xticks_rotation=30, cmap='Greens'); plt.tight_layout(); Path('output').mkdir(exist_ok=True); plt.savefig('output/confusion_matrix.png')
if __name__ == '__main__': main()

