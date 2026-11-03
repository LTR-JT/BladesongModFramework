"""Exercise the real Lua-to-DLL service boundary in a fake game install."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "Framework/BladesongModFramework/Scripts"
SHARED = ROOT / "Framework/shared/BladesongFramework"


class LocalService(unittest.TestCase):
    def test_runtime_services(self):
        with tempfile.TemporaryDirectory(prefix="service fixture ", dir=ROOT / "Tests") as temp:
            base = Path(temp)
            steamapps = base / "steamapps"
            win64 = steamapps / "common/Bladesong/Bladesong/Binaries/Win64"
            mods = win64 / "ue4ss/Mods"
            scripts = mods / "BladesongModFramework/Scripts"
            scripts.mkdir(parents=True)
            shared = mods / "shared/BladesongFramework"
            shared.mkdir(parents=True)
            shutil.copyfile(SCRIPTS / "bmf-local-service.dll", scripts / "bmf-local-service.dll")
            exe = win64 / "Bladesong-Win64-Shipping.exe"
            shutil.copyfile(sys.executable, exe)
            digest = hashlib.sha256(exe.read_bytes()).hexdigest()
            manifest = steamapps / "appmanifest_2305640.acf"
            saves = base / "SaveGames"
            (saves / "profile").mkdir(parents=True)
            (saves / "profile/CreativeMode.sav").write_bytes(b"save")
            (saves / "ignore.txt").write_bytes(b"ignore")
            (saves / "profile/second.SAV").write_bytes(b"save")
            data = scripts.parent / "Data"
            data.mkdir()
            (data / "settings.json").write_text('{"existing":true}')
            script = base / "fixture.lua"
            script.write_text(r"""
local source,root,manifest,saveRoot,settingsPath,digest=...
local J=assert(loadfile(source..'json.lua'))()
local F={_json=J,errors={}}
local C=assert(loadfile(source..'worker_client.lua'))(root,F)
local function job(operation,args)
 local result
 C.StartJob(operation,args,function(value)result=value end)
 local deadline=os.time()+10
 repeat C.Poll() until result or os.time()>deadline
 assert(result,'Local service timed out: '..operation)
 assert(#F.errors==0,table.concat(F.errors,'\n'))
 return result
end
for beta,branch in pairs({public='main',bleedingedge='bleedingedge',other='unknown'}) do
 local file=assert(io.open(manifest,'wb'))
 file:write('"AppState" { "buildid" "123" "BetaKey" "'..beta..'" }')
 file:close()
 local result=job('identify',{})
 assert(result.status=='complete',result.error)
 assert(result.identity.sha256==digest)
 assert(result.identity.branch==branch and result.identity.buildid=='123')
end
local result=job('list-saves',{source=saveRoot})
assert(result.status=='complete',result.error)
assert(#result.files==2)
for _,entry in ipairs(result.files) do
 assert(entry.source:sub(1,#saveRoot+1)==saveRoot..'/')
 assert(entry.source:lower():match('%.sav$'))
end
assert(job('list-saves',{source=saveRoot..'/profile'}).status=='failed')
assert(job('install',{}).status=='failed')
for _,value in ipairs({false,true}) do
 local result=job('settings',{settings={existing=value}})
 assert(result.status=='complete',result.error)
 local file=assert(io.open(settingsPath,'rb'))
 assert(J.decode(file:read('*a')).existing==value)
 file:close()
end
""", encoding="utf-8")
            subprocess.run(
                [
                    os.environ["BMF_TEST_LUA"], str(script), SHARED.as_posix() + "/",
                    shared.as_posix() + "/", manifest.as_posix(), saves.as_posix(),
                    (data / "settings.json").as_posix(), digest,
                ],
                timeout=40, check=True,
            )
            self.assertEqual(list(scripts.parent.glob("job_*")), [])


if __name__ == "__main__":
    unittest.main()
