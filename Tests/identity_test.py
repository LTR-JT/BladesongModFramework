"""Identify only branches from the manifest belonging to this exact game install."""
import hashlib,json,pathlib,shutil,subprocess,sys,tempfile,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]

class Identity(unittest.TestCase):
 def test_explicit_branch_detection(self):
  with tempfile.TemporaryDirectory(dir=ROOT/'Tests')as temp:
   steamapps=pathlib.Path(temp)/'steamapps'
   win64=steamapps/'common/Bladesong/Bladesong/Binaries/Win64'
   scripts=win64/'ue4ss/Mods/BladesongModFramework/Scripts';scripts.mkdir(parents=True)
   shutil.copyfile(ROOT/'Framework/BladesongModFramework/Scripts/bmf-worker.exe',scripts/'bmf-worker.exe')
   exe=win64/'Bladesong-Win64-Shipping.exe';shutil.copyfile(sys.executable,exe)
   for i,(beta,expected)in enumerate([('public','main'),('bleedingedge','bleedingedge'),('some_other_branch','unknown')]):
    (steamapps/'appmanifest_2305640.acf').write_text('"AppState" { "buildid" "123" "BetaKey" "'+beta+'" }')
    job=pathlib.Path(temp)/f'job{i}.json';job.write_text(json.dumps({'id':f'identity{i}','operation':'identify'}))
    subprocess.run([str(scripts/'bmf-worker.exe'),str(job)],timeout=20,check=True)
    result=json.loads(pathlib.Path(str(job)+'.result.json').read_text(encoding='utf-8-sig'))
    self.assertEqual(result['identity']['branch'],expected)
    self.assertEqual(result['identity']['buildid'],'123')
    self.assertEqual(result['identity']['sha256'],hashlib.sha256(exe.read_bytes()).hexdigest())

if __name__=='__main__':unittest.main()
