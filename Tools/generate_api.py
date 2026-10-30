import json, re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
contract=json.loads((ROOT/'SDK/api-contract.json').read_text(encoding='utf-8'))
source=(ROOT/'Framework/shared/BladesongFramework/api.lua').read_text(encoding='utf-8')
implemented={n for n in re.findall(r'function F\.(\w+)\(',source)}
assert implemented=={x['name'] for x in contract},'Public contract and implementation drifted'
annotations=['---@meta','---@class BladesongFramework','local Framework = {}']
docs=['# Framework API','Generated from the implementation-checked public contract. Types refer to UE4SS proxies, not transferable cross-state objects.']
for item in contract:
    annotations += ['---'+item['description']]+['---@param '+p+' '+item.get('parameter_types',{}).get(p,'any')for p in item['parameters']]+['---@return '+item['returns'], 'function Framework.'+item['name']+'('+', '.join(item['parameters'])+') end']
    docs += ['## '+item['name'],item['description'],'Parameters: '+(', '.join(item['parameters'])or 'none')+'.','Returns: `'+item['returns']+'`.','Errors: '+item['errors']+'.','Since API '+item['since']+'. '+item['builds'],'```lua',item['example'],'```',item['limitations']]
(ROOT/'SDK/framework.d.lua').write_text('\n'.join(annotations)+'\nreturn Framework\n',encoding='utf-8')
(ROOT/'Documentation/framework-api.md').write_text('\n\n'.join(docs)+'\n',encoding='utf-8')
print(f'{len(contract)} public APIs documented and annotated')
