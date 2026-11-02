"""Importer les lieux habités CG de GeoNames ; aucune requête à l'exécution Flutter."""
import argparse
import io
import json
from pathlib import Path
import unicodedata
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parent.parent
URL = 'https://download.geonames.org/export/dump/CG.zip'


def key(value):
    return ''.join(c for c in unicodedata.normalize('NFKD', value.casefold())
                   if c.isalnum() and not unicodedata.combining(c))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path)
    parser.add_argument('--download', action='store_true')
    args = parser.parse_args()
    if args.download:
        with urllib.request.urlopen(URL, timeout=45) as response:
            payload = response.read(10_000_001)
    elif args.source:
        payload = args.source.read_bytes()
    else:
        parser.error('Choisir --source archive.zip ou --download.')
    if len(payload) > 10_000_000:
        raise ValueError('Archive trop volumineuse')
    archive = zipfile.ZipFile(io.BytesIO(payload))
    if archive.getinfo('CG.txt').file_size > 30_000_000:
        raise ValueError('Extrait trop volumineux')
    rows = [line.split('\t') for line in archive.read('CG.txt').decode('utf-8').splitlines()]
    rows = [r for r in rows if len(r) == 19 and r[8] == 'CG' and r[6] == 'P'
            and r[7] in {'PPL', 'PPLA', 'PPLA2', 'PPLA3', 'PPLA4', 'PPLC', 'PPLL'}]
    groups = {}
    for row in sorted(rows, key=lambda r: int(r[14] or 0), reverse=True):
        if not 1 <= len(row[1]) <= 120:
            continue
        entry = groups.setdefault(key(row[1]), {'name': row[1], 'aliases': set(), 'ids': []})
        entry['ids'].append(int(row[0]))
        entry['aliases'].update(v for v in [row[1], row[2], *row[3].split(',')]
                                if 1 <= len(v) <= 120)
    places = []
    for entry in sorted(groups.values(), key=lambda p: key(p['name'])):
        entry['aliases'] = sorted(entry['aliases'])
        places.append(entry)
    result = {'country': 'CG', 'retrieved': '2026-11-01', 'source': URL,
              'license': 'https://creativecommons.org/licenses/by/4.0/',
              'recordCount': len(rows), 'places': places}
    target = ROOT / 'assets/data/congo_places.json'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(result, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    print(f'{len(places)} noms distincts depuis {len(rows)} lieux habités CG ; {target.stat().st_size} octets')


if __name__ == '__main__':
    main()
