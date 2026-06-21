"""Create a CSV that a qualified agronomist must sign before splitting."""
import argparse
import csv
from pathlib import Path

CLASSES = ['healthy', 'stink_bug_damage', 'fungal_spot', 'fruit_rot', 'unknown']
def main():
    p = argparse.ArgumentParser(); p.add_argument('--source', required=True); p.add_argument('--output', default='output/agronomist_review.csv'); args = p.parse_args()
    rows = []
    for proposed in CLASSES:
        for path in sorted((Path(args.source) / proposed).glob('*')):
            if path.is_file(): rows.append([str(path), proposed, '', 'pending', '', ''])
    out = Path(args.output); out.parent.mkdir(exist_ok=True)
    with out.open('w', newline='', encoding='utf-8-sig') as f:
        writer = csv.writer(f); writer.writerow(['file','proposed_label','verified_label','review_status','agronomist_name','notes']); writer.writerows(rows)
    print(f'Created {out} with {len(rows)} rows. Only rows marked approved should enter training.')
if __name__ == '__main__': main()

