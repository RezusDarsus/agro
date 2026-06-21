"""Fail-fast dataset quality and split-leakage audit."""
import argparse
import hashlib
import json
from collections import Counter, defaultdict
from pathlib import Path
from PIL import Image

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']
EXTENSIONS = {'.jpg', '.jpeg', '.png', '.webp'}

def main():
    p = argparse.ArgumentParser(); p.add_argument('--data', default='../sample_data/dataset'); p.add_argument('--minimum-per-class', type=int, default=300); args = p.parse_args()
    root = Path(args.data); counts = defaultdict(Counter); hashes = defaultdict(list); corrupt = []
    for split in ('train', 'val', 'test'):
        for label in CLASSES:
            for path in (root / split / label).glob('*'):
                if path.suffix.lower() not in EXTENSIONS: continue
                try:
                    with Image.open(path) as im: im.verify()
                    digest = hashlib.sha256(path.read_bytes()).hexdigest()
                    hashes[digest].append(str(path)); counts[split][label] += 1
                except Exception as exc: corrupt.append({'file': str(path), 'error': str(exc)})
    leakage = [paths for paths in hashes.values() if len(paths) > 1]
    totals = {label: sum(counts[s][label] for s in counts) for label in CLASSES}
    report = {'counts': {s: dict(c) for s, c in counts.items()}, 'totals': totals, 'exact_duplicate_groups': leakage, 'corrupt': corrupt,
              'needs_more_data': {k: max(0, args.minimum_per_class - v) for k, v in totals.items()}}
    Path('output').mkdir(exist_ok=True); Path('output/dataset_audit.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(json.dumps(report, indent=2))
    if leakage or corrupt: raise SystemExit('AUDIT FAILED: remove split leakage/corrupt files.')
    if any(v < args.minimum_per_class for v in totals.values()): raise SystemExit('AUDIT INCOMPLETE: more reviewed images required.')
    print('AUDIT PASSED')

if __name__ == '__main__': main()

