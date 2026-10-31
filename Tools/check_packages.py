from pathlib import Path
import json,zipfile,hashlib
from sdk_tools import SDK_ROOT
from validate_manifest import validate_manifest
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'Releases';meta=json.loads((ROOT/'mod.json').read_text());id=meta['id'];version=meta['version']
with zipfile.ZipFile(OUT/f'{id}_{version}_Package.zip')as z:
 m=validate_manifest(json.loads(z.read('mod.json')));assert m['id']==id
 for file in m['files']:assert len(z.read(file['path']))==file['size']and hashlib.sha256(z.read(file['path'])).hexdigest()==file['sha256']
 assert len(z.namelist())==len(m['files'])+1
 assert not any(name.endswith(('manager.lua','catalogue.lua','bmm-worker.exe'))for name in z.namelist())
 assert b'System.Net'not in z.read('Scripts/bmf-worker.exe')
 assert any(name.startswith('assets/logicmods/')for name in z.namelist())
print('PASS: framework-only package, portable hashes, offline helper, and shared runtime assets')
