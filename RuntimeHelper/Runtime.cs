// Offline runtime services only. This binary cannot download or deploy mods.
using System;using System.IO;using System.Collections.Generic;using System.Diagnostics;using System.Linq;using System.Security.Cryptography;using System.Text;using System.Text.RegularExpressions;using System.Web.Script.Serialization;
class Runtime {
 static JavaScriptSerializer Json=new JavaScriptSerializer{MaxJsonLength=1048576,RecursionLimit=32};
 static string ModRoot,ModsRoot,Data;
 static Dictionary<string,object> D(object x){return (Dictionary<string,object>)x;}
 static object G(object x,string k,object fallback=null){object v;return D(x).TryGetValue(k,out v)?v:fallback;}
 static string S(object x,string k){return Convert.ToString(G(x,k,""));}
 static Dictionary<string,object> Obj(params object[] pairs){var d=new Dictionary<string,object>();for(int i=0;i<pairs.Length;i+=2)d.Add((string)pairs[i],pairs[i+1]);return d;}
 static void Need(bool value,string error){if(!value)throw new Exception(error);}
 static object Read(string p){Need(new FileInfo(p).Length<=1048576,"JSON size limit");return Json.DeserializeObject(File.ReadAllText(p));}
 static void Write(string p,object value){Directory.CreateDirectory(Path.GetDirectoryName(p));string t=p+".tmp";File.WriteAllText(t,Json.Serialize(value),new UTF8Encoding(false));if(File.Exists(p))File.Replace(t,p,null);else File.Move(t,p);}
 static string Hash(string p){using(var s=File.OpenRead(p))using(var h=SHA256.Create())return BitConverter.ToString(h.ComputeHash(s)).Replace("-","").ToLowerInvariant();}
 static string GameExe(){return Path.Combine(Directory.GetParent(Directory.GetParent(ModsRoot).FullName).FullName,"Bladesong-Win64-Shipping.exe");}
 static object Identity(){
  string exe=GameExe();var result=Obj("sha256",Hash(exe),"game",FileVersionInfo.GetVersionInfo(exe).FileVersion,"branch","unknown");
  string dir=Path.GetDirectoryName(exe);for(int i=0;i<5;i++)dir=Path.GetDirectoryName(dir);string acf=Path.Combine(dir,"appmanifest_2305640.acf");
  if(File.Exists(acf)&&Path.GetFullPath(Path.Combine(dir,"common/Bladesong/Bladesong/Binaries/Win64/Bladesong-Win64-Shipping.exe"))==Path.GetFullPath(exe)){
   string raw=File.ReadAllText(acf);var build=Regex.Match(raw,"\"buildid\"\\s+\"(\\d+)\"");if(build.Success){result["game"]="Steam build "+build.Groups[1].Value;result["buildid"]=build.Groups[1].Value;}
   var branch=Regex.Match(raw,"\"BetaKey\"\\s+\"([^\"\\r\\n]+)\"");if(branch.Success){string beta=branch.Groups[1].Value;if(beta=="public")result["branch"]="main";else if(beta=="bleedingedge")result["branch"]="bleedingedge";}
  }Write(Path.Combine(Data,"identity.json"),result);return result;
 }
 static object Run(object request){object args=G(request,"args",Obj());switch(S(request,"operation")){
   case "list-saves":{
    string source=Path.GetFullPath(S(args,"source"));Need(Path.GetFileName(source)=="SaveGames","Expected SaveGames directory");
    Need(Directory.Exists(source),"Save directory unavailable");
    for(string ancestor=source;ancestor!=null;ancestor=Path.GetDirectoryName(ancestor))Need((File.GetAttributes(ancestor)&FileAttributes.ReparsePoint)==0,"Save junction rejected");
    var files=new List<object>();var pending=new Stack<string>();pending.Push(source);int directories=0;
    while(pending.Count>0){string directory=pending.Pop();Need(++directories<=6000,"Save directory count limit");
     foreach(string entry in Directory.EnumerateFileSystemEntries(directory)){
      var attributes=File.GetAttributes(entry);Need((attributes&FileAttributes.ReparsePoint)==0,"Save link rejected");
      if((attributes&FileAttributes.Directory)!=0)pending.Push(entry);
      else if(Path.GetExtension(entry).Equals(".sav",StringComparison.OrdinalIgnoreCase)){Need(files.Count<6000,"Save file count limit");files.Add(Obj("source",entry));}
     }
    }return Obj("status","complete","files",files);
   }
   case "identify":return Obj("status","complete","identity",Identity());
   case "settings":Write(Path.Combine(Data,"settings.json"),G(args,"settings",Obj()));return Obj("status","complete");
   default:throw new Exception("Unsupported runtime operation");
 }}
 [STAThread]static int Main(string[] args){if(args.Length!=1)return 2;string path=Path.GetFullPath(args[0]);try{
  ModRoot=Directory.GetParent(Path.GetDirectoryName(Process.GetCurrentProcess().MainModule.FileName)).FullName;
  Need(Path.GetFileName(ModRoot)=="BladesongModFramework","Invalid runtime root");ModsRoot=Directory.GetParent(ModRoot).FullName;Data=Path.Combine(ModRoot,"Data");Directory.CreateDirectory(Data);
  Write(path+".result.json",Run(Read(path)));return 0;
 }catch(Exception e){try{Write(path+".result.json",Obj("status","failed","error",e.Message));}catch{}return 1;}}
}
