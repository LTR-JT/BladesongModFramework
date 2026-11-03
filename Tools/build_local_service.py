from pathlib import Path
from msvc import build

ROOT = Path(__file__).resolve().parents[1]
build(
    ROOT / "NativeSource/common/local_service.cpp",
    ROOT / "Framework/BladesongModFramework/Scripts/bmf-local-service.dll",
    ROOT / "Build/local-service",
    compiler_flags=["/std:c++17", "/EHsc"],
)
