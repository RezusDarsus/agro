"""Generate augmented dataset from raw candidates to reach >1000 photos."""
import argparse
import random
import shutil
from pathlib import Path
from PIL import Image, ImageEnhance

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']

def augment_image(img: Image.Image, seed: int) -> Image.Image:
    rng = random.Random(seed)
    # Random rotation
    angle = rng.uniform(-25, 25)
    img = img.rotate(angle, resample=Image.Resampling.BILINEAR, expand=False)
    
    # Random flip
    if rng.choice([True, False]):
        img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if rng.choice([True, False]):
        img = img.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
        
    # Random brightness
    enhancer = ImageEnhance.Brightness(img)
    factor = rng.uniform(0.75, 1.25)
    img = enhancer.enhance(factor)
    
    # Random contrast
    enhancer = ImageEnhance.Contrast(img)
    factor = rng.uniform(0.75, 1.25)
    img = enhancer.enhance(factor)
    
    return img

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source', default='../sample_data/raw_candidates')
    p.add_argument('--output', default='../sample_data/dataset')
    p.add_argument('--target-per-class', type=int, default=350)
    p.add_argument('--seed', type=int, default=42)
    args = p.parse_args()
    
    source = Path(args.source)
    output = Path(args.output)
    rng = random.Random(args.seed)
    
    # Clean output splits if they exist
    for split in ('train', 'val', 'test'):
        for label in CLASSES:
            split_dir = output / split / label
            if split_dir.exists():
                shutil.rmtree(split_dir)
            split_dir.mkdir(parents=True, exist_ok=True)
            
    print("Starting dataset augmentation and split allocation...")
    
    for label in CLASSES:
        label_dir = source / label
        if not label_dir.exists():
            print(f"Warning: source label directory {label_dir} does not exist.")
            continue
            
        # Find all valid source images
        src_images = []
        for path in label_dir.glob('*'):
            if path.suffix.lower() not in ('.jpg', '.jpeg', '.png', '.webp'):
                continue
            try:
                with Image.open(path) as im:
                    im.verify()
                src_images.append(path)
            except Exception as e:
                print(f"Skipping corrupt image {path}: {e}")
                
        if not src_images:
            print(f"Error: No valid images found for label {label}!")
            continue
            
        print(f"Class '{label}': Found {len(src_images)} source images. Augmenting to {args.target_per_class}...")
        
        # Build list of images to allocate (starting with originals)
        class_images = []
        
        # Add all originals
        for i, path in enumerate(src_images):
            class_images.append((path, None))  # (source path, seed for augmentation)
            
        # Generate augmented versions
        aug_idx = 0
        while len(class_images) < args.target_per_class:
            src_path = rng.choice(src_images)
            class_images.append((src_path, args.seed + len(class_images) + aug_idx))
            aug_idx += 1
            
        # Shuffle allocated images
        rng.shuffle(class_images)
        
        # Split: 70% train, 15% val, 15% test
        n = len(class_images)
        train_end = round(n * 0.70)
        val_end = train_end + round(n * 0.15)
        
        splits = {
            'train': class_images[:train_end],
            'val': class_images[train_end:val_end],
            'test': class_images[val_end:]
        }
        
        for split_name, items in splits.items():
            dest_dir = output / split_name / label
            for idx, (src_path, aug_seed) in enumerate(items):
                dest_path = dest_dir / f"{label}_{idx:05d}.jpg"
                
                try:
                    with Image.open(src_path) as im:
                        im = im.convert('RGB')
                        if aug_seed is not None:
                            im = augment_image(im, aug_seed)
                        im.save(dest_path, 'JPEG', quality=95)
                except Exception as e:
                    print(f"Failed to process/save image {src_path} -> {dest_path}: {e}")
                    
        print(f"Class '{label}': allocated to splits successfully.")
        
    print("Augmentation complete!")

if __name__ == '__main__':
    main()
