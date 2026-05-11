"""
hatch_build.py — custom Hatchling build hook for binary wheel creation.

When the environment variable GMP_LIB_DIR is set (or build/lib/ exists relative
to the repository root), this hook:
  1. Copies the entire build/lib/ tree into src/geometric_medical_phantoms/libs/.
  2. Marks the wheel as platform-specific (pure_python=False, infer_tag=True).

Without GMP_LIB_DIR the hook is a no-op and a pure-Python sdist / wheel is
produced instead (useful for the PyPI stub package).
"""

from __future__ import annotations

import os
import platform
import shutil
import sys
from pathlib import Path

from hatchling.builders.hooks.plugin.interface import BuildHookInterface


class CustomBuildHook(BuildHookInterface):
    PLUGIN_NAME = "custom"

    def initialize(self, version: str, build_data: dict) -> None:
        if self.target_name != "wheel":
            return

        lib_dir = self._find_lib_dir()
        if lib_dir is None:
            # No binary available — build a pure-Python stub wheel.
            return

        # Copy the entire lib directory (libgeomphantoms + Julia runtime) into
        # the package so it is self-contained inside the installed wheel.
        dest = Path(self.root) / "src" / "geometric_medical_phantoms" / "libs"
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(lib_dir, dest, symlinks=True)

        # The libs/ directory is inside the declared package
        # (src/geometric_medical_phantoms/), so Hatchling picks it up
        # automatically via packages = ["src/geometric_medical_phantoms"].
        # We only need to mark the wheel as platform-specific.
        build_data["pure_python"] = False
        build_data["infer_tag"] = True

    def finalize(self, version: str, build_data: dict, artifact_path: str) -> None:
        # Clean up the temporary libs/ copy so it doesn't linger in the source tree.
        dest = Path(self.root) / "src" / "geometric_medical_phantoms" / "libs"
        if dest.exists():
            shutil.rmtree(dest)

    # ------------------------------------------------------------------
    def _find_lib_dir(self) -> Path | None:
        """Return the path to build/lib/ containing the compiled library."""
        # 1. Explicit override via environment variable.
        env = os.environ.get("GMP_LIB_DIR", "")
        if env and Path(env).is_dir():
            return Path(env)

        # 2. Default: <repo-root>/lib/build/lib/  (two levels up from this file).
        here = Path(__file__).parent          # lib/python/
        candidates = [
            here.parent / "build" / "lib",   # lib/build/lib/
        ]
        for c in candidates:
            lib_name = _lib_name()
            if (c / lib_name).exists():
                return c
        return None


def _lib_name() -> str:
    system = platform.system()
    if system == "Darwin":
        return "libgeomphantoms.dylib"
    if system == "Windows":
        return "geomphantoms.dll"
    return "libgeomphantoms.so"
