"""Download openly licensed iNaturalist observations as review candidates."""
import argparse
import json
import time
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API = 'https://api.inaturalist.org/v1/observations'
USER_AGENT = 'AgroLensSamegrelo/1.0 educational dataset preparation'
TAXA = {
    'healthy': [(54491, 'Corylus avellana')],
    'fungal_spot': [(208754, 'Phyllactinia guttata'), (1303303, 'Anisogramma anomala')],
    'stink_bug_damage': [(81923, 'Halyomorpha halys')],
    'fruit_rot': [(775527, 'Monilinia fructigena')],
    'unknown': [(56133, 'Quercus robur'), (469472, 'Malus domestica'),
                (58722, 'Pinus sylvestris'), (79519, 'Vitis vinifera')],
}
ALLOWED = {'cc0', 'cc-by', 'cc-by-sa'}

def get_json(url):
    with urlopen(Request(url, headers={'User-Agent': USER_AGENT}), timeout=45) as response:
        return json.load(response)

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', default='../sample_data/raw_candidates')
    p.add_argument('--per-taxon', type=int, default=100)
    p.add_argument('--target-per-label', type=int, default=60)
    args = p.parse_args()
    root = Path(args.output); root.mkdir(parents=True, exist_ok=True)
    manifest_path = root / 'sources.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else []
    seen = {row['source_url'] for row in manifest}
    added = 0
    for proposed, taxa in TAXA.items():
        folder = root / proposed; folder.mkdir(exist_ok=True)
        label_count = len([path for path in folder.iterdir() if path.is_file()])
        for taxon_id, taxon_name in taxa:
            if label_count >= args.target_per_label: break
            collected = 0
            for page in range(1, 11):
                params = {'taxon_id': taxon_id, 'photos': 'true', 'quality_grade': 'research',
                          'per_page': 100, 'page': page, 'photo_license': 'cc0,cc-by,cc-by-sa',
                          'order_by': 'created_at', 'order': 'desc'}
                data = get_json(f'{API}?{urlencode(params)}')
                if not data.get('results'): break
                for observation in data['results']:
                    for photo in observation.get('photos', []):
                        license_code = (photo.get('license_code') or '').lower()
                        if license_code not in ALLOWED: continue
                        source_url = f'https://www.inaturalist.org/photos/{photo["id"]}'
                        if source_url in seen: continue
                        image_url = photo['url'].replace('/square.', '/large.')
                        destination = folder / f'{proposed}_inat_{photo["id"]}.jpg'
                        try:
                            with urlopen(Request(image_url, headers={'User-Agent': USER_AGENT}), timeout=60) as response:
                                destination.write_bytes(response.read())
                        except Exception as exc:
                            print(f'SKIP {image_url}: {exc}'); continue
                        seen.add(source_url); collected += 1; label_count += 1; added += 1
                        manifest.append({'file': str(destination.relative_to(root)), 'proposed_label': proposed,
                            'review_status': 'pending', 'provider': 'iNaturalist', 'taxon_id': taxon_id,
                            'taxon_name': taxon_name, 'observation_url': observation.get('uri'),
                            'author_attribution': photo.get('attribution'), 'license': license_code,
                            'source_url': source_url})
                        print(f'DOWNLOADED {destination}')
                        if label_count >= args.target_per_label or collected >= args.per_taxon: break
                        time.sleep(.08)
                    if label_count >= args.target_per_label or collected >= args.per_taxon: break
                if label_count >= args.target_per_label or collected >= args.per_taxon: break
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f'Added {added} candidates. All remain pending expert review.')

if __name__ == '__main__': main()
