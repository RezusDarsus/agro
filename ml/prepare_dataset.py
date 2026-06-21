"""Deduplicate reviewed raw images and create reproducible train/val/test splits."""
import argparse
import hashlib
import random
import shutil
from pathlib import Path
from PIL import Image

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']
EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}

def dhash(path: Path) -> int:
    with Image.open(path) as im:
        im = im.convert('L').resize((9, 8))
        pixels = list(im.getdata())
    value = 0
    for y in range(8):
        for x in range(8):
            value = (value << 1) | (pixels[y * 9 + x] > pixels[y * 9 + x + 1])
    return value

def hamming(a: int, b: int) -> int:
    return (a ^ b).bit_count()

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--source', required=True, help='Expert-reviewed class folders')
    p.add_argument('--output', default='../sample_data/dataset')
    p.add_argument('--seed', type=int, default=42)
    p.add_argument('--near-duplicate-distance', type=int, default=5)
    args = p.parse_args()
    source, output = Path(args.source), Path(args.output)
    rng = random.Random(args.seed)
    seen_exact, seen_visual = set(), []
    accepted = {name: [] for name in CLASSES}
    rejected = []

    for label in CLASSES:
        for path in sorted((source / label).glob('*')):
            if path.suffix.lower() not in EXTENSIONS:
                continue
            try:
                exact = hashlib.sha256(path.read_bytes()).hexdigest()
                visual = dhash(path)
            except Exception as exc:
                rejected.append((str(path), f'corrupt: {exc}'))
                continue
            if exact in seen_exact:
                rejected.append((str(path), 'exact duplicate'))
                continue
            if any(hamming(visual, old) <= args.near_duplicate_distance for old in seen_visual):
                rejected.append((str(path), 'near duplicate'))
                continue
            seen_exact.add(exact); seen_visual.append(visual); accepted[label].append(path)

    for split in ('train', 'val', 'test'):
        for label in CLASSES:
            (output / split / label).mkdir(parents=True, exist_ok=True)
    for label, files in accepted.items():
        rng.shuffle(files)
        n = len(files); train_end = round(n * .70); val_end = train_end + round(n * .15)
        groups = {'train': files[:train_end], 'val': files[train_end:val_end], 'test': files[val_end:]}
        for split, items in groups.items():
            for index, src in enumerate(items):
                shutil.copy2(src, output / split / label / f'{label}_{index:05d}{src.suffix.lower()}')
        print(f'{label}: {len(groups["train"])} train, {len(groups["val"])} val, {len(groups["test"])} test')
    Path('output').mkdir(exist_ok=True)
    Path('output/rejected_duplicates.tsv').write_text('\n'.join(f'{p}\t{r}' for p, r in rejected), encoding='utf-8')
    print(f'Rejected {len(rejected)} corrupt/duplicate files. Seed: {args.seed}')

if __name__ == '__main__': main()

