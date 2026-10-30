"""Exercise the Lua launcher against a real worker, including paths with spaces."""
import json,os,pathlib,shutil,subprocess,tempfile,time,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
class HiddenWorker(unittest.TestCase):
 def test_lua_launch_and_save_listing(self):
  with tempfile.TemporaryDirectory(prefix='hidden worker ',dir=ROOT/'Tests')as directory:
   base=pathlib.Path(directory);mod=base/'ue4ss/Mods/BladesongModFramework';scripts=mod/'Scripts';scripts.mkdir(parents=True)
   shutil.copyfile(ROOT/'Framework/BladesongModFramework/Scripts/bmf-worker.exe',scripts/'bmf-worker.exe')
   source=base/'Saved/SaveGames';source.mkdir(parents=True);(source/'one.sav').write_bytes(b'unchanged save');(source/'ignore.txt').write_text('not a save')
   job=mod/'job.json';job.write_text(json.dumps({'id':'hidden_worker_test','operation':'list-saves','args':{'source':str(source)}}))
   launcher=ROOT/'Framework/BladesongModFramework/Scripts/bmf-launch.dll'
   script=base/'launch.lua';script.write_text("local launch=assert(package.loadlib("+json.dumps(launcher.as_posix())+",'bmf_launch'))\nlocal bytes="+json.dumps((scripts/'bmf-worker.exe').as_posix())+"..'\\0'.."+json.dumps(job.as_posix())+"\nlocal args={#bytes};for i=1,#bytes do args[#args+1]=bytes:byte(i)end\nassert(launch(table.unpack(args))>0)\nassert(launch(1,0)==0)\n")
   subprocess.run([os.environ['BMF_TEST_LUA'],str(script)],check=True,timeout=10)
   result=pathlib.Path(str(job)+'.result.json');limit=time.monotonic()+10
   while not result.exists()and time.monotonic()<limit:time.sleep(.05)
   response=json.loads(result.read_text(encoding='utf-8-sig'));self.assertEqual(response['status'],'complete');self.assertEqual(len(response['files']),1)
   self.assertEqual((source/'one.sav').read_bytes(),b'unchanged save')
if __name__=='__main__':unittest.main()
