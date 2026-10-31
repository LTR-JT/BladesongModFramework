from pathlib import Path
import tempfile,shutil
from sdk_tools import SDK_ROOT
from package_runtime import build
ROOT=Path(__file__).resolve().parents[1];(ROOT/'Build').mkdir(exist_ok=True)
assert (ROOT/'Framework/BladesongModFramework/Scripts/bmf-worker.exe').is_file(),'Build the runtime helper first'
for version in ['25940006','25431485']:assert len(list((ROOT/'Framework/shared/BladesongFramework/native'/version).glob('*.dll')))==7,'Build native adapters first'
with tempfile.TemporaryDirectory(dir=ROOT/'Build')as temp:
 stage=Path(temp);shutil.copytree(ROOT/'Framework/BladesongModFramework',stage,dirs_exist_ok=True);shutil.copytree(ROOT/'Framework/shared/BladesongFramework',stage/'shared');assets=stage/'assets/logicmods';assets.mkdir(parents=True)
 for path in (ROOT/'Assets/Cooked').glob('PCLAnchor.*'):shutil.copyfile(path,assets/path.name)
 build(stage,ROOT/'Releases','https://github.com/LTR-JT/BladesongModFramework',ROOT/'LICENSE',ROOT/'THIRD_PARTY_NOTICES.md')
print('Prepared framework-only packages')
