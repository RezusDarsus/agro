"""Download reusable Wikimedia Commons candidates with attribution metadata.

Downloaded files are candidates, not approved labels. Run agronomist review
before prepare_dataset.py moves any image into train/val/test.
"""
import argparse
import json
import re
import time
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

API = 'https://commons.wikimedia.org/w/api.php'
USER_AGENT = 'AgroLensSamegrelo/1.0 (educational dataset preparation)'
ALLOWED_LICENSES = ('CC BY', 'CC0', 'Public domain')
QUERIES = {
    'healthy': ['Corylus avellana leaf', 'hazelnut fruit Corylus avellana'],
    'fungal_spot': ['Phyllactinia guttata on Common Hazel', 'hazelnut mildew'],
    'stink_bug_damage': ['Halyomorpha halys damage fruit', 'brown marmorated stink bug feeding damage'],
    'fruit_rot': ['hazelnut mold fruit', 'Corylus fruit disease'],
    'unknown': ['cartoon tree illustration', 'human portrait photograph', 'landscape distant tree', 'apple leaf close up'],
}

def get_json(params):
    request = Request(f'{API}?{urlencode(params)}', headers={'User-Agent': USER_AGENT})
    with urlopen(request, timeout=30) as response:
        return json.load(response)

def clean(value):
    return re.sub('<[^>]+>', '', value or '').strip()

def main():
    p = argparse.ArgumentParser(); p.add_argument('--output', default='../sample_data/raw_candidates'); p.add_argument('--per-query', type=int, default=20); args = p.parse_args()
    root = Path(args.output); root.mkdir(parents=True, exist_ok=True)
    manifest_path = root / 'sources.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.exists() else []
    seen = {row['source_url'] for row in manifest}
    for proposed, queries in QUERIES.items():
        folder = root / proposed; folder.mkdir(exist_ok=True)
        for query in queries:
            data = get_json({'action':'query','generator':'search','gsrsearch':query,'gsrnamespace':6,'gsrlimit':args.per_query,
                             'prop':'imageinfo','iiprop':'url|mime|extmetadata','iiurlwidth':1600,'format':'json'})
            for page in (data.get('query', {}).get('pages', {}) or {}).values():
                info = (page.get('imageinfo') or [{}])[0]; mime = info.get('mime', '')
                if mime not in ('image/jpeg', 'image/png', 'image/webp'): continue
                meta = info.get('extmetadata', {}); license_name = clean(meta.get('LicenseShortName', {}).get('value'))
                if not any(license_name.startswith(prefix) for prefix in ALLOWED_LICENSES): continue
                source_url = info.get('descriptionurl') or info.get('url'); image_url = info.get('thumburl') or info.get('url')
                if not image_url or source_url in seen: continue
                seen.add(source_url); ext = {'image/jpeg':'.jpg','image/png':'.png','image/webp':'.webp'}[mime]
                filename = f'{proposed}_{len(list(folder.glob("*.*"))):04d}{ext}'; destination = folder / filename
                try:
                    req = Request(image_url, headers={'User-Agent': USER_AGENT})
                    with urlopen(req, timeout=60) as response: destination.write_bytes(response.read())
                except Exception as exc:
                    print(f'SKIP {image_url}: {exc}'); continue
                manifest.append({'file': str(destination.relative_to(root)), 'proposed_label': proposed, 'review_status': 'pending',
                    'title': page.get('title'), 'author': clean(meta.get('Artist', {}).get('value')), 'license': license_name,
                    'license_url': clean(meta.get('LicenseUrl', {}).get('value')), 'source_url': source_url, 'search_query': query})
                print(f'DOWNLOADED {destination}')
                time.sleep(.1)
    manifest_path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding='utf-8')
    print(f'Downloaded {len(manifest)} licensed candidates. All remain pending expert review.')

if __name__ == '__main__': main()
