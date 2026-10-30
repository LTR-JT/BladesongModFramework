"""Compile checked-in exact-build adapters; never inspect/patch a running game."""
import argparse
from pathlib import Path
from msvc import build
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--build',choices=['25431485','25940006'],default='25940006');args=p.parse_args()
sources=ROOT/'NativeSource'/args.build;target=ROOT/'Framework/shared/BladesongFramework/native'/args.build
for source in sorted(sources.glob('*.cpp')):
 name=source.stem+('b'if source.stem=='pcl_held_upload_151725'else '')+'.dll'
 build(source,target/name,ROOT/'Build/native'/args.build)
print('Built adapters for Steam build',args.build)
