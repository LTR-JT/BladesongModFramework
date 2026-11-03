from pathlib import Path
import tempfile,shutil
from sdk_tools import SDK_ROOT
from package_runtime import build
ROOT=Path(__file__).resolve().parents[1];(ROOT/'Build').mkdir(exist_ok=True)
assert (ROOT/'Framework/BladesongModFramework/Scripts/bmf-local-service.dll').is_file(),'Build the local service first'
for version in ['25940006','25431485']:assert len(list((ROOT/'Framework/shared/BladesongFramework/native'/version).glob('*.dll')))==7,'Build native adapters first'
with tempfile.TemporaryDirectory(dir=ROOT/'Build')as temp:
 stage=Path(temp);shutil.copytree(ROOT/'Framework/BladesongModFramework',stage,dirs_exist_ok=True,ignore=shutil.ignore_patterns('bmf-worker.exe','bmf-launch.dll','job_*.json','Data'));shutil.copytree(ROOT/'Framework/shared/BladesongFramework',stage/'shared')
 build(stage,ROOT/'Releases','https://github.com/LTR-JT/BladesongModFramework',ROOT/'LICENSE',ROOT/'THIRD_PARTY_NOTICES.md')
print('Prepared framework-only packages')
