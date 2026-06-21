"""Audit and group-split the 10-view nut-quality dataset by physical nut ID."""
import argparse
import csv
import hashlib
import json
import random
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from PIL import Image

CLASSES = ['quality_nuts', 'nuts_kernel', 'damaged_nuts']

def inspect(item):
    path, row = item
    try:
        with Image.open(path) as image:
            image.verify()
        return row, hashlib.sha256(path.read_bytes()).hexdigest(), None
    except Exception as exc:
        return row, None, str(exc)

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--root', default='../sample_data/raw_candidates/nuts')
    p.add_argument('--seed', type=int, default=42)
    p.add_argument('--output', default='output/nut_quality')
    args = p.parse_args()
    project = Path(__file__).resolve().parents[1]
    root = (Path(__file__).parent / args.root).resolve()
    output = (Path(__file__).parent / args.output).resolve(); output.mkdir(parents=True, exist_ok=True)
    rows = list(csv.DictReader((root / 'nuts.csv').open(encoding='utf-8-sig')))
    normalized = []
    for row in rows:
        label = row['nut_class_name']; path = root / label / row['nut_image_name']
        if not path.exists() and label == 'damaged_nuts':
            path = root / label / row['nut_image_name'].replace('damaged_nuts_', 'damaged_nut_')
        normalized.append((path, {'file': str(path.relative_to(project)), 'label': label,
                                  'label_id': CLASSES.index(label), 'nut_id': row['nut_id']}))
    with ThreadPoolExecutor(max_workers=12) as pool:
        inspected = list(pool.map(inspect, normalized))
    corrupt = []; exact_seen = {}; valid = []
    for row, digest, error in inspected:
        if error: corrupt.append({**row, 'error': error}); continue
        if digest in exact_seen:
            # Keep one byte-identical image. Record rather than copy/delete originals.
            continue
        exact_seen[digest] = row['file']; valid.append(row)

    groups = defaultdict(list)
    for row in valid: groups[(row['label'], row['nut_id'])].append(row)
    rng = random.Random(args.seed); splits = {'train': [], 'val': [], 'test': []}; group_counts = {}
    for label in CLASSES:
        keys = [key for key in groups if key[0] == label]; rng.shuffle(keys)
        n = len(keys); train_end = round(n * .70); val_end = train_end + round(n * .15)
        assignments = {'train': keys[:train_end], 'val': keys[train_end:val_end], 'test': keys[val_end:]}
        group_counts[label] = {split: len(keys_) for split, keys_ in assignments.items()}
        for split, keys_ in assignments.items():
            for key in keys_: splits[split].extend(groups[key])

    fields = ['file', 'label', 'label_id', 'nut_id']
    for split, items in splits.items():
        with (output / f'{split}.csv').open('w', newline='', encoding='utf-8') as handle:
            writer = csv.DictWriter(handle, fieldnames=fields); writer.writeheader(); writer.writerows(items)
    leakage = set((r['label'], r['nut_id']) for r in splits['train']) & set((r['label'], r['nut_id']) for r in splits['test'])
    report = {
        'source_rows': len(rows), 'valid_unique_images': len(valid),
        'exact_duplicates_excluded': len(rows) - len(valid) - len(corrupt), 'corrupt': corrupt,
        'physical_nuts': len(groups), 'group_counts': group_counts,
        'image_counts': {split: dict(Counter(r['label'] for r in items)) for split, items in splits.items()},
        'group_leakage_count': len(leakage), 'seed': args.seed,
    }
    (output / 'audit.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))
    if corrupt or leakage: raise SystemExit('AUDIT FAILED')
    print('AUDIT PASSED: all views of each physical nut stay in one split.')

if __name__ == '__main__': main()
