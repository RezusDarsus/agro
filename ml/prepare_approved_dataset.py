"""Copy only agronomist-approved review rows into a clean reviewed dataset."""
import argparse
import csv
import shutil
from pathlib import Path

LABELS = {'healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown'}

def main():
    p = argparse.ArgumentParser(); p.add_argument('--manifest', default='output/agronomist_review.csv'); p.add_argument('--output', default='../sample_data/reviewed'); p.add_argument('--source-root', default='../sample_data/raw_candidates'); args = p.parse_args()
    here = Path(__file__).resolve().parent; manifest = (here / args.manifest).resolve(); output = (here / args.output).resolve(); source_root = (here / args.source_root).resolve()
    rows = list(csv.DictReader(manifest.open(encoding='utf-8-sig'))); copied = 0; errors = []
    for row in rows:
        if row.get('review_status', '').strip().lower() != 'approved': continue
        label = row.get('verified_label', '').strip()
        if label not in LABELS: errors.append(f'Invalid verified_label {label!r}: {row.get("file")}'); continue
        raw = row.get('file', '').replace('\\', '/'); path = Path(raw)
        candidates = [path, source_root / path, source_root / label / path.name]
        source = next((candidate.resolve() for candidate in candidates if candidate.exists()), None)
        if source is None: errors.append(f'Missing file: {raw}'); continue
        destination = output / label / source.name; destination.parent.mkdir(parents=True, exist_ok=True)
        if destination.exists(): destination = destination.with_stem(f'{destination.stem}_{copied:05d}')
        shutil.copy2(source, destination); copied += 1
    if errors:
        (output / 'preparation_errors.txt').parent.mkdir(parents=True, exist_ok=True)
        (output / 'preparation_errors.txt').write_text('\n'.join(errors), encoding='utf-8')
        raise SystemExit(f'Preparation stopped with {len(errors)} errors. See preparation_errors.txt.')
    print(f'Copied {copied} approved images into {output}. Pending/rejected rows were ignored.')

if __name__ == '__main__': main()
