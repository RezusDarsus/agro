import argparse
from pathlib import Path
import json
import matplotlib.pyplot as plt
import tensorflow as tf

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']
IMG_SIZE = (224, 224)

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--data', default='../sample_data/dataset')
    p.add_argument('--epochs', type=int, default=12)
    p.add_argument('--batch-size', type=int, default=32)
    p.add_argument('--fine-tune-epochs', type=int, default=6)
    args = p.parse_args()
    root, out = Path(args.data), Path('output')
    out.mkdir(exist_ok=True)
    common = dict(image_size=IMG_SIZE, batch_size=args.batch_size, label_mode='int', class_names=CLASSES)
    train = tf.keras.utils.image_dataset_from_directory(root / 'train', shuffle=True, **common)
    val = tf.keras.utils.image_dataset_from_directory(root / 'val', shuffle=False, **common)
    aug = tf.keras.Sequential([tf.keras.layers.RandomFlip('horizontal'), tf.keras.layers.RandomRotation(.08), tf.keras.layers.RandomZoom(.1)])
    base = tf.keras.applications.MobileNetV2(include_top=False, weights='imagenet', input_shape=(224, 224, 3))
    base.trainable = False
    inputs = tf.keras.Input((224, 224, 3))
    x = aug(inputs)
    x = tf.keras.layers.Rescaling(1./255)(x)
    x = base(x, training=False)
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.Dropout(.3)(x)
    x = tf.keras.layers.Dense(128, activation='relu')(x)
    outputs = tf.keras.layers.Dense(5, activation='softmax')(x)
    model = tf.keras.Model(inputs, outputs)
    model.compile(optimizer=tf.keras.optimizers.Adam(1e-4), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
    counts = [len(list((root / 'train' / name).glob('*'))) for name in CLASSES]
    if min(counts) == 0:
        raise ValueError(f'Every class needs training images. Counts: {dict(zip(CLASSES, counts))}')
    total = sum(counts)
    class_weight = {i: total / (len(CLASSES) * count) for i, count in enumerate(counts)}
    callbacks = [
        tf.keras.callbacks.EarlyStopping(patience=3, restore_best_weights=True),
        tf.keras.callbacks.ModelCheckpoint(out / 'best_model.keras', save_best_only=True, monitor='val_accuracy'),
        tf.keras.callbacks.ReduceLROnPlateau(patience=2, factor=.3, min_lr=1e-7),
    ]
    history = model.fit(train, validation_data=val, epochs=args.epochs, class_weight=class_weight, callbacks=callbacks)
    if args.fine_tune_epochs > 0:
        base.trainable = True
        for layer in base.layers[:-30]:
            layer.trainable = False
        model.compile(optimizer=tf.keras.optimizers.Adam(1e-5), loss='sparse_categorical_crossentropy', metrics=['accuracy'])
        fine = model.fit(train, validation_data=val, epochs=args.fine_tune_epochs, class_weight=class_weight, callbacks=callbacks)
        for key, values in fine.history.items(): history.history.setdefault(key, []).extend(values)
    model.save(out / 'agrolens_model.keras')
    (out / 'labels.txt').write_text('\n'.join(CLASSES) + '\n', encoding='utf-8')
    (out / 'training_history.json').write_text(json.dumps(history.history), encoding='utf-8')
    plt.plot(history.history['accuracy'], label='train'); plt.plot(history.history['val_accuracy'], label='validation'); plt.xlabel('Epoch'); plt.ylabel('Accuracy'); plt.legend(); plt.tight_layout(); plt.savefig(out / 'training_history.png')

if __name__ == '__main__': main()
