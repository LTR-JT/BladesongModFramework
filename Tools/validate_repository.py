"""Offline publication checks. No network, no player data reads."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
index=json.loads((ROOT/'mod-index.json').read_text(encoding='utf-8'))
assert set(index)=={'mods'} and len(index['mods'])<=64
seen=set()
for entry in index['mods']:
 assert set(entry)=={'name','url'} and 0<len(entry['name'])<=160
 assert re.fullmatch(r'https://github\.com/[\w.-]+/[\w.-]+/?',entry['url'])
 assert entry['url'].rstrip('/').lower() not in seen;seen.add(entry['url'].rstrip('/').lower())
for rel,digest in json.loads((ROOT/'Tests/frozen/SHA256.json').read_text()).items():
 assert hashlib.sha256((ROOT/'Tests/frozen'/rel).read_bytes()).hexdigest()==digest,'Frozen fixture changed: '+rel
public=json.loads((ROOT/'SDK/api-contract.json').read_text())
historical=json.loads((ROOT/'SDK/contracts/v1.0.0.json').read_text())
current={v['name']:v for v in public}
for api in historical:
 assert api['name'] in current and current[api['name']]['parameters']==api['parameters'] and current[api['name']]['returns']==api['returns'],'Historical API drift'
for directory in ['SDK/templates','Examples','Framework']:
 for p in (ROOT/directory).rglob('mod.json'):
  m=json.loads(p.read_text(encoding='utf-8'))
  assert not {'game_builds','supported_branches','supported_game_builds'}&set(m),str(p)
  assert all(k in m for k in ['id','name','version','api'])
print('PASS: minimal index, frozen source/data hashes, historical API signatures, branch-free standard manifests')
