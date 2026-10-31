from pathlib import Path
import os, subprocess
ROOT = Path(__file__).resolve().parents[1]
fx = Path(os.environ.get('WINDIR', r'C:\Windows')) / 'Microsoft.NET/Framework64/v4.0.30319'
compiler = fx / 'csc.exe'
if not compiler.exists():
    raise SystemExit('Windows .NET Framework 4.x compiler is required to build the worker')
subprocess.run([str(compiler), '/nologo', '/optimize+', '/target:winexe', '/out:' + str(ROOT/'Framework/BladesongModFramework/Scripts/bmf-worker.exe'), '/reference:'+str(fx/'System.Web.Extensions.dll'), str(ROOT/'RuntimeHelper/Runtime.cs')],check=True)

from msvc import build
build(ROOT/"NativeSource/common/worker_launch.cpp", ROOT/"Framework/BladesongModFramework/Scripts/bmf-launch.dll", ROOT/"Build/worker-launch")
