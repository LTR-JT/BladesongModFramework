import hashlib,json,pathlib,shutil,subprocess,tempfile,unittest,zipfile,os
ROOT=pathlib.Path(__file__).resolve().parents[1]
SERVICE=ROOT/'Framework/BladesongModFramework/Scripts/bmf-worker.exe'
class Installer(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(dir=ROOT/'Tests');self.root=pathlib.Path(self.tmp.name).resolve();assert self.root.is_relative_to((ROOT/'Tests').resolve())
  self.scripts=self.root/'Bladesong/Binaries/Win64/ue4ss/Mods/BladesongModFramework/Scripts';self.scripts.mkdir(parents=True)
  shutil.copyfile(SERVICE,self.scripts/'bmf-worker.exe');self.sequence=0
 def tearDown(self):self.tmp.cleanup()
 def job(self,op,args,capabilities=None):
  self.sequence+=1;job=self.root/f'job{self.sequence}.json';job.write_text(json.dumps({'id':f'test_{self.sequence}','operation':op,'args':args,'capabilities':capabilities or []}),encoding='utf8')
  run=subprocess.run([str(self.scripts/'bmf-worker.exe'),str(job)],capture_output=True,text=True,timeout=30)
  result=pathlib.Path(str(job)+'.result.json');self.assertTrue(result.exists(),run.stderr);return json.loads(result.read_text(encoding='utf-8-sig'))
 def archive(self,name='Scripts/main.lua',data=b'print("fixture")',hash_override=None):
  self.sequence+=1;p=self.root/f'archive{self.sequence}.zip';m={'schema_version':1,'id':'FixtureMod','name':'Fixture','version':'1.0.0','api':'^1.0.0','files':[{'path':name,'size':len(data),'sha256':hash_override or hashlib.sha256(data).hexdigest()}]}
  with zipfile.ZipFile(p,'w',zipfile.ZIP_DEFLATED)as z:z.writestr(name,data)
  manifest=p.with_suffix('.json');manifest.write_text(json.dumps(m));return p,manifest
 def validate(self,p,m):return self.job('validate-local',{'archive':str(p),'manifest':str(m)})
 def test_valid_archive_and_fresh_install(self):
  p,m=self.archive();result=self.validate(p,m);self.assertEqual(result['status'],'complete',result)
  plan=self.root/'plan.json';plan.write_text(json.dumps({'schema_version':1,'approved':True,'id':'test_install','relaunch':False,'items':[{'manifest':str(m),'payload':result['payload']}]}))
  result=self.job('apply',{'plan':str(plan)});self.assertEqual(result['status'],'complete',result)
  installed=self.scripts.parent.parent/'FixtureMod/Scripts/main.lua';self.assertEqual(installed.read_bytes(),b'print("fixture")')
 def test_manual_dependency_manifest_and_disabled_state(self):
  _,manifest=self.archive();metadata=json.loads(manifest.read_text());metadata['dependencies']={'BladesongModFramework':'^0.1.4'};manifest.write_text(json.dumps(metadata))
  folder=self.scripts.parent;current={'schema_version':1,'id':'BladesongModFramework','name':'Framework','version':'0.1.5','api':'^1.0.0'}
  (folder/'mod.json').write_text(json.dumps(current));(folder/'enabled.txt').write_text('')
  self.assertEqual(self.job('validate-dependencies-local',{'path':str(manifest)})['status'],'complete')
  (folder/'bmf-installed.json').write_text(json.dumps(dict(current,version='0.1.2')))
  self.assertEqual(self.job('validate-dependencies-local',{'path':str(manifest)})['status'],'complete')
  (folder/'enabled.txt').unlink()
  self.assertEqual(self.job('validate-dependencies-local',{'path':str(manifest)})['status'],'failed')
  current['version']='0.1.2';(folder/'mod.json').write_text(json.dumps(current));(folder/'enabled.txt').write_text('')
  self.assertEqual(self.job('validate-dependencies-local',{'path':str(manifest)})['status'],'failed')
 def test_traversal_and_hash(self):
  for path in ['../outside.lua','Scripts/../outside.lua','C:/outside.lua','Scripts/main.lua:evil','Scripts/CON.lua']:
   p,m=self.archive(path);self.assertEqual(self.validate(p,m)['status'],'failed',path)
  p,m=self.archive(hash_override='0'*64);self.assertEqual(self.validate(p,m)['status'],'failed')
 def test_unlisted_link_and_duplicate(self):
  p,m=self.archive()
  with zipfile.ZipFile(p,'a')as z:z.writestr('extra.lua',b'extra')
  self.assertEqual(self.validate(p,m)['status'],'failed')
  p,m=self.archive()
  with zipfile.ZipFile(p,'a')as z:
   i=zipfile.ZipInfo('link');i.create_system=3;i.external_attr=(0o120777<<16);z.writestr(i,b'../escape')
  self.assertEqual(self.validate(p,m)['status'],'failed')
  p,m=self.archive()
  with zipfile.ZipFile(p,'a')as z:z.writestr('SCRIPTS/MAIN.LUA',b'print("fixture")')
  self.assertEqual(self.validate(p,m)['status'],'failed')
 def test_save_path_and_unapproved_plan(self):
  p,m=self.archive('SaveGames/test.sav');self.assertEqual(self.validate(p,m)['status'],'failed')
  plan=self.root/'bad-plan.json';plan.write_text(json.dumps({'schema_version':1,'approved':False,'items':[]}));self.assertEqual(self.job('apply',{'plan':str(plan)})['status'],'failed')
 def test_toggle_is_staged_and_applies_after_exit(self):
  mods=self.scripts.parent.parent;mod=mods/'FixtureMod';mod.mkdir();(mod/'enabled.txt').write_text('');(mods/'mods.txt').write_text('FixtureMod : 1\n')
  result=self.job('toggle',{'id':'FixtureMod','enabled':False});self.assertEqual(result['status'],'complete',result)
  self.assertTrue((mod/'enabled.txt').exists());self.assertIn(': 1',(mods/'mods.txt').read_text())
  plan=self.scripts.parent/'Data/pending.json';data=json.loads(plan.read_text());data['relaunch']=False;plan.write_text(json.dumps(data))
  result=self.job('apply',{'plan':str(plan)});self.assertEqual(result['status'],'complete',result)
  self.assertFalse((mod/'enabled.txt').exists());self.assertIn(': 0',(mods/'mods.txt').read_text())
 def test_failure_rolls_back_prior_write(self):
  p,m=self.archive();manifest=json.loads(m.read_text());data=b'second';manifest['files'].append({'path':'blocked/second.lua','size':len(data),'sha256':hashlib.sha256(data).hexdigest()})
  m.write_text(json.dumps(manifest))
  with zipfile.ZipFile(p,'a')as z:z.writestr('blocked/second.lua',data)
  result=self.validate(p,m);self.assertEqual(result['status'],'complete',result)
  mod=self.scripts.parent.parent/'FixtureMod';mod.mkdir();(mod/'blocked').write_text('existing file')
  plan=self.root/'rollback-plan.json';plan.write_text(json.dumps({'schema_version':1,'approved':True,'id':'rollback_test','relaunch':False,'items':[{'manifest':str(m),'payload':result['payload']}]}))
  result=self.job('apply',{'plan':str(plan)});self.assertEqual(result['status'],'failed',result);self.assertFalse((mod/'Scripts/main.lua').exists());self.assertEqual((mod/'blocked').read_text(),'existing file')
 def test_unmanaged_files_are_preserved(self):
  p,m=self.archive();result=self.validate(p,m);mod=self.scripts.parent.parent/'FixtureMod/Scripts';mod.mkdir(parents=True);(mod/'main.lua').write_text('personal edit')
  plan=self.root/'unmanaged-plan.json';plan.write_text(json.dumps({'schema_version':1,'approved':True,'id':'unmanaged_test','relaunch':False,'items':[{'manifest':str(m),'payload':result['payload']}]}))
  result=self.job('apply',{'plan':str(plan)});self.assertEqual(result['status'],'failed');self.assertEqual((mod/'main.lua').read_text(),'personal edit')
 def test_framework_capabilities_replace_normal_build_lists(self):
  p,m=self.archive();metadata=json.loads(m.read_text());metadata['game_builds']=['0'*64];m.write_text(json.dumps(metadata))
  result=self.job('compatibility-local',{'path':str(m)});self.assertEqual(result['compatibility'],'framework-ready')
  metadata['capabilities']=['forge.read'];m.write_text(json.dumps(metadata))
  self.assertEqual(self.job('compatibility-local',{'path':str(m)})['compatibility'],'requires-framework-work')
  self.assertEqual(self.job('compatibility-local',{'path':str(m)},['forge.read'])['compatibility'],'framework-ready')
  metadata['raw_integration']={'reason':'Native fixture','game_builds':['0'*64]};m.write_text(json.dumps(metadata))
  data=self.scripts.parent/'Data';data.mkdir(exist_ok=True);(data/'identity.json').write_text(json.dumps({'sha256':'1'*64}))
  self.assertEqual(self.job('compatibility-local',{'path':str(m)},['forge.read'])['compatibility'],'raw-build-mismatch')
 def test_simple_index_validation(self):
  p=self.root/'index.json';p.write_text(json.dumps({'mods':[{'name':'Fixture','url':'https://github.com/example/fixture'}]}))
  self.assertEqual(self.job('validate-index-local',{'path':str(p)})['status'],'complete')
  for entry in [{'name':'Fixture','url':'http://github.com/example/fixture'},{'name':'Fixture','url':'https://github.com/example/fixture','version':'1.0.0'}]:
   p.write_text(json.dumps({'mods':[entry]}));self.assertEqual(self.job('validate-index-local',{'path':str(p)})['status'],'failed')
 def test_offline_catalogue_isolates_missing_repository(self):
  url='https://example.com/mod-index.json';repos=['https://github.com/example/good','https://github.com/example/missing']
  cache=self.scripts.parent/'Data/catalogue';cache.mkdir(parents=True)
  key=lambda s:hashlib.sha256(s.encode()).hexdigest()
  (cache/(key(url)+'.index.json')).write_text(json.dumps({'mods':[{'name':'Good','url':repos[0]},{'name':'Missing','url':repos[1]}]}))
  (cache/(key(repos[0])+'.mod.json')).write_text(json.dumps({'id':'Good','name':'Author supplied name','version':'1.0.0','api':'^1.0.0'}))
  result=self.job('browse',{'index_url':url,'offline':True});self.assertEqual(result['status'],'complete')
  self.assertEqual(len(result['entries']),2);entries={x['repository']:x for x in result['entries']}
  self.assertEqual(entries[repos[0]]['manifest']['name'],'Author supplied name');self.assertTrue(entries[repos[0]]['cached'])
  self.assertEqual(entries[repos[1]]['status'],'unavailable')
 def test_automatic_manifest_and_ordinary_discovery(self):
  mods=self.scripts.parent.parent
  for name in ['Ordinary','Declared','Broken']:(mods/name/'Scripts').mkdir(parents=True);(mods/name/'Scripts/main.lua').write_text('')
  (mods/'Declared/mod.json').write_text(json.dumps({'schema_version':1,'id':'Declared','name':'Declared metadata','version':'1.0.0','api':'^1.0.0'}))
  (mods/'Broken/mod.json').write_text('{broken')
  result=self.job('discover',{});self.assertEqual(result['status'],'complete');found={m['id']:m for m in result['mods']}
  self.assertEqual(found['Ordinary']['integration'],'ordinary');self.assertEqual(found['Declared']['integration'],'manifest');self.assertEqual(found['Broken']['integration'],'invalid-manifest')
if __name__=='__main__':unittest.main()
