"""Quarantine exact and visually near-duplicate dataset candidates."""
import argparse
import hashlib
import json
import shutil
from collections import Counter
from pathlib import Path
from PIL import Image

def dhash(path: Path) -> int:
    with Image.open(path) as image:
        image = image.convert('L').resize((9, 8))
        pixels = list(image.getdata())
    value = 0
    for y in range(8):
        for x in range(8):
            value = (value << 1) | (pixels[y * 9 + x] > pixels[y * 9 + x + 1])
    return value

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--root', default='../sample_data/raw_candidates')
    p.add_argument('--quarantine', default='../sample_data/quarantine_duplicates')
    p.add_argument('--distance', type=int, default=4)
    args = p.parse_args()
    root = Path(args.root).resolve(); quarantine = Path(args.quarantine).resolve()
    manifest_path = root / 'sources.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    retained = []
    exact_seen = {}
    duplicates = []

    for row in manifest:
        if row.get('review_status') == 'duplicate':
            continue
        path = root / row['file']
        if not path.exists() or not path.is_file():
            continue
        try:
            exact = hashlib.sha256(path.read_bytes()).hexdigest()
            visual = dhash(path)
        except Exception as exc:
            row.update(review_status='invalid', duplicate_reason=f'unreadable: {exc}')
            duplicates.append(row)
            continue
        match = exact_seen.get(exact)
        reason = 'exact duplicate' if match else None
        if not match:
            for old_visual, old_row in retained:
                if (visual ^ old_visual).bit_count() <= args.distance:
                    match = old_row
                    reason = f'perceptual duplicate (dHash distance <= {args.distance})'
                    break
        if match:
            destination = quarantine / row['proposed_label'] / path.name
            destination.parent.mkdir(parents=True, exist_ok=True)
            if destination.exists(): destination = destination.with_stem(destination.stem + '_duplicate')
            shutil.move(str(path), destination)
            row.update(review_status='duplicate', duplicate_reason=reason,
                       duplicate_of=match['file'], quarantine_file=str(destination))
            duplicates.append(row)
        else:
            exact_seen[exact] = row
            retained.append((visual, row))

    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
    (quarantine / 'duplicates.json').write_text(json.dumps(duplicates, indent=2, ensure_ascii=False), encoding='utf-8')
    counts = Counter(row['proposed_label'] for _, row in retained)
    print(json.dumps({'retained_total': len(retained), 'retained_by_label': counts,
                      'quarantined_total': len(duplicates)}, indent=2))

if __name__ == '__main__': main()
