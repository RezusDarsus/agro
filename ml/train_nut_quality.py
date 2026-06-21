"""Train a separate three-class nut-quality MobileNetV2 model."""
import argparse
import csv
import json
from pathlib import Path
import matplotlib.pyplot as plt
import tensorflow as tf

CLASSES = ['quality_nuts', 'nuts_kernel', 'damaged_nuts']

def load_manifest(path, project):
    rows = list(csv.DictReader(Path(path).open(encoding='utf-8')))
    return [str(project / row['file']) for row in rows], [int(row['label_id']) for row in rows]

def dataset(files, labels, batch, training):
    ds = tf.data.Dataset.from_tensor_slices((files, labels))
    if training: ds = ds.shuffle(len(files), seed=42, reshuffle_each_iteration=True)
    def decode(path, label):
        image = tf.io.decode_jpeg(tf.io.read_file(path), channels=3)
        image = tf.image.resize(image, (224, 224))
        return image, label
    return ds.map(decode, num_parallel_calls=tf.data.AUTOTUNE).batch(batch).prefetch(tf.data.AUTOTUNE)

def main():
    p = argparse.ArgumentParser(); p.add_argument('--manifests', default='output/nut_quality'); p.add_argument('--epochs', type=int, default=10); p.add_argument('--fine-tune-epochs', type=int, default=4); p.add_argument('--batch-size', type=int, default=32); args = p.parse_args()
    here = Path(__file__).resolve().parent; project = here.parent; manifests = here / args.manifests; out = here / 'output/nut_quality'; out.mkdir(parents=True, exist_ok=True)
    train_x, train_y = load_manifest(manifests / 'train.csv', project); val_x, val_y = load_manifest(manifests / 'val.csv', project)
    train_ds = dataset(train_x, train_y, args.batch_size, True); val_ds = dataset(val_x, val_y, args.batch_size, False)
    augment = tf.keras.Sequential([tf.keras.layers.RandomFlip('horizontal'), tf.keras.layers.RandomRotation(.08), tf.keras.layers.RandomZoom(.1), tf.keras.layers.RandomContrast(.12)])
    base = tf.keras.applications.MobileNetV2(include_top=False, weights='imagenet', input_shape=(224,224,3)); base.trainable = False
    inputs = tf.keras.Input((224,224,3)); x = augment(inputs); x = tf.keras.applications.mobilenet_v2.preprocess_input(x); x = base(x, training=False); x = tf.keras.layers.GlobalAveragePooling2D()(x); x = tf.keras.layers.Dropout(.3)(x); outputs = tf.keras.layers.Dense(3, activation='softmax')(x); model = tf.keras.Model(inputs, outputs)
    callbacks = [tf.keras.callbacks.EarlyStopping(patience=3, restore_best_weights=True), tf.keras.callbacks.ModelCheckpoint(out/'best_model.keras', save_best_only=True), tf.keras.callbacks.ReduceLROnPlateau(patience=2, factor=.3)]
    model.compile(tf.keras.optimizers.Adam(1e-4), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    history = model.fit(train_ds, validation_data=val_ds, epochs=args.epochs, callbacks=callbacks)
    if args.fine_tune_epochs:
        base.trainable = True
        for layer in base.layers[:-30]: layer.trainable = False
        model.compile(tf.keras.optimizers.Adam(1e-5), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
        fine = model.fit(train_ds, validation_data=val_ds, epochs=args.fine_tune_epochs, callbacks=callbacks)
        for key, values in fine.history.items(): history.history.setdefault(key, []).extend(values)
    model.save(out/'nut_quality_model.keras'); (out/'labels.txt').write_text('\n'.join(CLASSES)+'\n', encoding='utf-8'); (out/'history.json').write_text(json.dumps(history.history), encoding='utf-8')
    plt.plot(history.history['accuracy'], label='train'); plt.plot(history.history['val_accuracy'], label='validation'); plt.legend(); plt.tight_layout(); plt.savefig(out/'training_history.png')

if __name__ == '__main__': main()
