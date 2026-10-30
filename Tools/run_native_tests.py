"""Run behavior fixtures against the exact-build native adapter sources."""
from pathlib import Path
import subprocess,shutil
from msvc import environment
ROOT=Path(__file__).resolve().parents[1];env=environment();work=ROOT/'Build/native-tests';work.mkdir(parents=True,exist_ok=True)
for source in sorted((ROOT/'Tests/native').glob('*.cpp')):
 obj=work/(source.stem+'.obj');exe=work/(source.stem+'.exe')
 subprocess.run([shutil.which('cl.exe',path=env['PATH']),'/nologo','/c','/O2','/GS-','/GR-','/Zl',f'/Fo:{obj}',str(source)],env=env,cwd=work,check=True)
 subprocess.run([shutil.which('link.exe',path=env['PATH']),'/nologo','/NODEFAULTLIB','/ENTRY:main','/SUBSYSTEM:CONSOLE',str(obj),'kernel32.lib','user32.lib','vcruntime.lib',f'/OUT:{exe}'],env=env,cwd=work,check=True)
 subprocess.run([str(exe)],check=True)
print('PASS: native download isolation, blade preservation/rollback and anchor flag fixtures')
