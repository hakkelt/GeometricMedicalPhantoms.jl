#!/usr/bin/env python3
"""
smoke_test_python.py — minimal smoke test for the GeometricMedicalPhantoms Python wrapper.

Usage:
    python smoke_test_python.py [/path/to/build/lib]

The optional argument overrides the default library search path.
"""

import sys
import os

# Allow running directly from lib/test/ without installing the package.
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python", "src"))

from geometric_medical_phantoms import (
    GMPLib, AXIS_AXIAL, SheppLoganIntensities, TubesGeometry, TubesIntensities,
    _find_lib,
)

PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"
_failures = []


def check(condition, name, detail=""):
    if condition:
        print(f"[{PASS}] {name}")
    else:
        msg = f"[{FAIL}] {name}" + (f": {detail}" if detail else "")
        print(msg, file=sys.stderr)
        _failures.append(name)


lib_path = _find_lib(sys.argv[1] if len(sys.argv) > 1 else None)
lib = GMPLib(lib_path)

# --- version ---
ver = lib.version()
print(f"[version] {ver}")
check(isinstance(ver, str) and len(ver) > 0, "version returns a non-empty string")

# --- Shepp-Logan 3-D ---
phantom = lib.create_shepp_logan_phantom_3d(16, 16, 16)
nonzero = int((phantom != 0).sum())
print(f"[shepp_logan_3d] {nonzero} / {phantom.size} non-zero voxels")
check(phantom.shape == (16, 16, 16), "shepp_logan_3d shape", f"got {phantom.shape}")
check(nonzero > 0, "shepp_logan_3d has non-zero voxels")

# --- Shepp-Logan 2-D ---
sl2d = lib.create_shepp_logan_phantom_2d(32, 32, axis=AXIS_AXIAL)
check(sl2d.shape == (32, 32), "shepp_logan_2d shape", f"got {sl2d.shape}")
print(f"[shepp_logan_2d] first value: {sl2d[0, 0]:.6f}")

# --- Tubes 3-D ---
tg = lib.tubes_geometry_default()
ti = lib.tubes_intensities_default()
tubes = lib.create_tubes_phantom_3d(16, 16, 16, geometry=tg, intensities=ti)
nonzero_t = int((tubes != 0).sum())
print(f"[tubes_3d] {nonzero_t} / {tubes.size} non-zero voxels")
check(tubes.shape == (16, 16, 16), "tubes_3d shape", f"got {tubes.shape}")
check(nonzero_t > 0, "tubes_3d has non-zero voxels")

# --- Signal length ---
n = lib.signal_length(10.0, 50.0)
print(f"[signal_length] 10 s @ 50 Hz -> {n} samples")
check(n == 500, "signal_length", f"expected 500, got {n}")

# --- Respiratory signal ---
t, sig = lib.generate_respiratory_signal(10.0, 50.0, 15.0)
sig_min, sig_max = float(sig.min()), float(sig.max())
print(f"[respiratory] range [{sig_min:.3f}, {sig_max:.3f}] L")
check(len(t) == n and len(sig) == n, "respiratory signal length")
check(1.0 <= sig_min and sig_max <= 5.0, "respiratory signal in expected range [1, 5] L",
      f"got [{sig_min:.3f}, {sig_max:.3f}]")

# --- Cardiac signals ---
tc, lv, rv, la, ra = lib.generate_cardiac_signals(5.0, 200.0, 70.0)
print(f"[cardiac] lv[0]={lv[0]:.1f} mL, rv[0]={rv[0]:.1f} mL, "
      f"la[0]={la[0]:.1f} mL, ra[0]={ra[0]:.1f} mL")
check(10.0 <= lv[0] <= 300.0, "cardiac LV volume in range", f"lv[0]={lv[0]:.1f}")

# --- Static torso 3-D ---
tissue = lib.tissue_intensities_default()
torso = lib.create_torso_phantom_3d(16, 16, 16, tissue=tissue)
nonzero_tor = int((torso != 0).sum())
print(f"[torso_3d] {nonzero_tor} / {torso[..., 0].size} non-zero voxels (1 frame)")
check(torso.shape[:-1] == (16, 16, 16), "torso_3d spatial shape", f"got {torso.shape}")
check(nonzero_tor > 0, "torso_3d has non-zero voxels")

# --- Result ---
if _failures:
    print(f"\n=== {len(_failures)} smoke test(s) FAILED ===", file=sys.stderr)
    sys.exit(1)
else:
    print("\n=== All Python smoke tests passed ===")
