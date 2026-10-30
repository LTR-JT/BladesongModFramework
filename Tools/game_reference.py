"""Extract interface facts from a local UE4SS CXXHeaderDump; never copy game binaries."""
import argparse, hashlib, json, re
from pathlib import Path

def extract(folder):
    classes, enums = {}, {}
    for path in sorted(Path(folder).glob('*.hpp')):
        text = path.read_text(encoding='utf-8', errors='replace')
        for match in re.finditer(r'(?:class|struct)\s+(\w+)(?:\s*:\s*public\s+(\w+))?\s*\{(.*?)\n\};', text, re.S):
            name, base, body = match.groups()
            functions, properties = [], []
            for line in body.splitlines():
                statement = line.split('//')[0].strip()
                if not statement or not statement.endswith(';'):
                    continue
                if '(' in statement and ')' in statement:
                    functions.append(statement)
                elif re.search(r'\w+\s*;', statement):
                    properties.append(statement)
            classes[name] = dict(base=base, functions=sorted(set(functions)), properties=sorted(set(properties)), evidence='reflected declaration only; behavior not proven', source_header=path.name, source_sha256=hashlib.sha256(path.read_bytes()).hexdigest())
        for match in re.finditer(r'enum(?:\s+class)?\s+(\w+)\s*\{(.*?)\};', text, re.S):
            enums[match[1]] = [line.strip().rstrip(',') for line in match[2].splitlines() if line.strip()]
    return dict(format=1, classes=classes, enums=enums)

def compare(a, b):
    left, right = a['classes'], b['classes']
    changed = {}
    for name in left.keys() & right.keys():
        delta = {}
        for field in ('functions', 'properties'):
            before, after = set(left[name][field]), set(right[name][field])
            if before != after:
                delta[field] = dict(removed=sorted(before-after), added=sorted(after-before))
        if left[name]['base'] != right[name]['base']:
            delta['base'] = [left[name]['base'], right[name]['base']]
        if delta:
            changed[name] = delta
    return dict(added_classes=sorted(right.keys()-left.keys()), removed_classes=sorted(left.keys()-right.keys()), changed=changed, warning='Signature changes suggest potential breakages; reflected declarations do not establish runtime behavior or exact asset-path changes.')

if __name__ == '__main__':
    p = argparse.ArgumentParser(); sub = p.add_subparsers(dest='command', required=True)
    e = sub.add_parser('extract'); e.add_argument('dump'); e.add_argument('output')
    c = sub.add_parser('compare'); c.add_argument('before'); c.add_argument('after'); c.add_argument('output')
    a = p.parse_args()
    result = extract(a.dump) if a.command == 'extract' else compare(json.loads(Path(a.before).read_text()), json.loads(Path(a.after).read_text()))
    Path(a.output).write_text(json.dumps(result, indent=2), encoding='utf-8')
