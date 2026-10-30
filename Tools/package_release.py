"""Emit separate manual-install and in-game update archives, without user data."""
from pathlib import Path
import hashlib,json,tempfile,shutil,zipfile
from package_mod import package
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'Releases';OUT.mkdir(exist_ok=True)
meta=json.loads((ROOT/'mod.json').read_text());version=meta['version'];name=meta['id']
worker=ROOT/'Framework/BladesongModFramework/Scripts/bmf-worker.exe'
assert worker.is_file(),'Build the worker first'
assert len(list((ROOT/'Framework/shared/BladesongFramework/native/25940006').glob('*.dll')))==7,'Build native adapters first'
manual=OUT/f'{name}_{version}_Runtime.zip'
with zipfile.ZipFile(manual,'w',zipfile.ZIP_DEFLATED)as z:
 for p in sorted((ROOT/'Framework').rglob('*')):
  if p.is_file():z.write(p,'Bladesong/Binaries/Win64/ue4ss/Mods/'+p.relative_to(ROOT/'Framework').as_posix())
 for p in sorted((ROOT/'Assets/Cooked').glob('PCLAnchor.*')):z.write(p,'Bladesong/Content/Paks/LogicMods/'+p.name)
 z.write(ROOT/'LICENSE','LICENSE_BladesongModFramework.txt');z.write(ROOT/'THIRD_PARTY_NOTICES.md','THIRD_PARTY_NOTICES_BladesongModFramework.md')
bmf=OUT/f'{name}_{version}_BMF.zip'
with tempfile.TemporaryDirectory(dir=ROOT/'Build')as temp:
 stage=Path(temp);shutil.copytree(ROOT/'Framework/BladesongModFramework',stage,dirs_exist_ok=True)
 shutil.copytree(ROOT/'Framework/shared/BladesongFramework',stage/'shared')
 release=package(stage,bmf)
release['repository']='https://github.com/LTR-JT/BladesongModFramework'
release['download']={'url':f'https://github.com/LTR-JT/BladesongModFramework/releases/download/v{version}/{bmf.name}','sha256':hashlib.sha256(bmf.read_bytes()).hexdigest()}
(OUT/'mod.json').write_text(json.dumps(release,indent=2)+'\n',encoding='utf-8')
archives=[manual,bmf]
for archive in archives:
 with zipfile.ZipFile(archive)as z:assert z.testzip()is None
(OUT/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n'for p in archives),encoding='utf-8')
print('Prepared runtime, in-game update archive, release manifest and checksums:',OUT)
