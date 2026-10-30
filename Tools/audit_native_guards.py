"""Read-only PE audit of existing PCL fixed-RVA byte guards; does not patch binaries."""
import argparse, hashlib, json, re, struct
from pathlib import Path

def audit(executable, sources):
    data=Path(executable).read_bytes()
    pe=struct.unpack_from('<I',data,0x3c)[0]
    assert data[:2]==b'MZ' and data[pe:pe+4]==b'PE\0\0'
    count=struct.unpack_from('<H',data,pe+6)[0]
    optional=struct.unpack_from('<H',data,pe+20)[0]
    sections=[]
    for i in range(count):
        off=pe+24+optional+i*40
        virtual_size,rva,size,raw=struct.unpack_from('<IIII',data,off+8)
        sections.append((rva,virtual_size,size,raw))
    def at(rva,length):
        for start,virtual,size,raw in sections:
            if start<=rva and rva+length<=start+size:
                return data[raw+rva-start:raw+rva-start+length]
        return b''
    def source(path,seen):
        path=Path(path).resolve()
        if path in seen:return ''
        seen.add(path);text=path.read_text(encoding='utf-8')
        return '\n'.join(source(path.parent/name,seen) for name in re.findall(r'#include\s+"([^"]+)"',text))+text
    result=[]
    for path in sources:
        text=source(path,set())
        arrays={name:bytes(int(x,16) for x in re.findall(r'0x([0-9a-fA-F]+)',body))
                for name,body in re.findall(r'(?:static\s+)?const\s+u8\s+(\w+)\[\]\s*=\s*\{([^}]+)\}',text)}
        checks=[]
        for rva,name in re.findall(r'same\(image\s*\+\s*0x([0-9a-fA-F]+)\s*,\s*(\w+)\s*,\s*sizeof\(\w+\)',text):
            expected=arrays.get(name)
            if expected is None:continue
            actual=at(int(rva,16),len(expected))
            checks.append(dict(name=name,rva='0x'+rva,expected=expected.hex(),actual=actual.hex(),match=actual==expected))
        result.append(dict(source=Path(path).name,checks=checks,all_recorded_guards_match=bool(checks)and all(c['match'] for c in checks)))
    return dict(format=1,sha256=hashlib.sha256(data).hexdigest(),image_size=hex(struct.unpack_from('<I',data,pe+24+56)[0]),sources=result,
                limitation='Matching prologues alone do not establish ABI, object offsets, function semantics, or runtime compatibility. This audit never enables native code.')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('executable');p.add_argument('output');p.add_argument('sources',nargs='+');a=p.parse_args()
    Path(a.output).write_text(json.dumps(audit(a.executable,a.sources),indent=2),encoding='utf-8')
