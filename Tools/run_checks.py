import argparse,os,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--lua',required=True);args=p.parse_args()
lua=str(Path(args.lua).resolve())
os.environ['BMF_TEST_ROOT']=str(ROOT)
os.environ['BMF_TEST_LUA']=lua
def run(*command):subprocess.run([str(x)for x in command],cwd=ROOT.parent,check=True)
for script in ['validate_repository.py','generate_api.py','build_docs.py']:run(sys.executable,ROOT/'Tools'/script)
files=list((ROOT/'Framework').rglob('*.lua'))+list((ROOT/'SDK/templates').rglob('*.lua'))+list((ROOT/'Examples').rglob('*.lua'))
runtime=ROOT/'Migration/PCL/Bladesong/Binaries/Win64/ue4ss/Mods/PreconstructionLibraryProbe/Scripts/pcl_runtime.lua'
if runtime.exists():files.append(runtime)
with __import__('tempfile').TemporaryDirectory(dir=ROOT/'Tests')as temp:
 syntax=Path(temp)/'syntax.lua'
 syntax.write_text('\n'.join('assert(loadfile('+__import__('json').dumps(str(f).replace('\\','/'))+'))'for f in files)+"\nprint('PASS: all runtime/template Lua syntax')\n",encoding='utf-8')
 run(lua,syntax)
for fixture in ['core.lua','compatibility.lua','catalogue.lua','menu.lua','manager_open.lua','browse.lua','creative_ownership.lua','preservation.lua']:run(lua,ROOT/'Tests'/fixture)
if os.name=='nt':
 run(sys.executable,ROOT/'Tools/build_worker.py')
 for fixture in ['identity_test.py','install_test.py','installer_test.py','hidden_worker_test.py']:run(sys.executable,ROOT/'Tests'/fixture)
else:print('Windows worker fixtures not run on this host')
print('All framework preservation checks passed')
