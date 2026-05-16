"""
geometric_medical_phantoms.py
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Pure-ctypes Python bindings for the GeometricMedicalPhantoms shared library.

Usage example::

    from geometric_medical_phantoms import GMPLib
    import numpy as np

    lib = GMPLib("path/to/build/lib/libgeomphantoms.so")  # .dylib / .dll on other platforms

    # Shepp-Logan phantom with CT default intensities
    ti = lib.shepp_logan_ct_default()
    phantom = lib.create_shepp_logan_phantom_3d(128, 128, 128, ti)  # np.ndarray (128,128,128)

    # Respiratory signal
    phys = lib.respiratory_physiology_default()
    t, sig = lib.generate_respiratory_signal(60.0, 50.0, 15.0, phys)

    # Dynamic torso phantom
    ti = lib.tissue_intensities_default()
    torso = lib.create_torso_phantom_3d(64, 64, 64, resp_signal=sig, tissue=ti)

The library data layout uses column-major (Fortran/Julia) order in memory.
numpy arrays returned by this module follow that convention: the first index
varies fastest.  For conventional (C-order) access transpose as needed.
"""

from __future__ import annotations

import ctypes
import os
import platform
import sys
from ctypes import POINTER, c_double, c_float, c_int, c_char_p
from dataclasses import dataclass, field
from typing import Optional, Sequence, Tuple

import numpy as np

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _find_lib(search_dir: Optional[str] = None) -> str:
    """Locate the shared library relative to this file or in search_dir."""
    suffixes = {
        "Linux":   "libgeomphantoms.so",
        "Darwin":  "libgeomphantoms.dylib",
        "Windows": "geomphantoms.dll",
    }
    name = suffixes.get(platform.system(), "libgeomphantoms.so")

    candidates = []
    if search_dir:
        candidates.append(os.path.join(search_dir, name))

    # Bundle layout: lib/python/src/geometric_medical_phantoms/ → lib/build/lib/
    here = os.path.dirname(os.path.abspath(__file__))
    candidates += [
        # Installed binary wheel: libs/ is bundled inside the package directory.
        os.path.join(here, "libs", name),
        # Development layout: lib/python/src/geometric_medical_phantoms/ → lib/build/lib/
        os.path.join(here, "..", "..", "..", "build", "lib", name),
        os.path.join(here, "..", "..", "build", "lib", name),
        name,  # rely on LD_LIBRARY_PATH / PATH
    ]
    for path in candidates:
        if os.path.isfile(path):
            return os.path.abspath(path)
    return name  # let ctypes try its own search


def _preload_bundled_libstdcxx(lib_path: str) -> None:
    """On Linux, ensure the bundled libstdc++ is used by the Julia runtime.

    The compiled Julia runtime ships with a newer libstdc++ than the system may
    provide.  Because Python itself already loads the system libstdc++.so.6 at
    startup (SONAME conflict), a simple ctypes.CDLL call after the fact cannot
    override it.  Instead, when a bundled libstdc++ is found, we re-exec the
    current process with ``LD_PRELOAD`` pointing to the bundled copy so that it
    wins the SONAME race at the very start of the new process.  A sentinel
    environment variable prevents infinite re-exec loops.
    """
    if platform.system() != "Linux":
        return
    if os.environ.get("_GMP_STDC_PRELOADED"):
        return  # already in the re-exec'd process
    # The bundled julia/ directory sits next to the main library file.
    julia_dir = os.path.join(os.path.dirname(os.path.abspath(lib_path)), "julia")
    if not os.path.isdir(julia_dir):
        return
    # Prefer the versioned .so.6.x file so the linker resolves GLIBCXX symbols.
    candidates = sorted(
        (f for f in os.listdir(julia_dir) if f.startswith("libstdc++.so.6.")),
        reverse=True,  # highest version string first
    )
    if not candidates:
        return
    bundled = os.path.join(julia_dir, candidates[0])
    # Re-exec this Python process with the bundled libstdc++ preloaded.
    existing = os.environ.get("LD_PRELOAD", "")
    os.environ["LD_PRELOAD"] = (bundled + ":" + existing) if existing else bundled
    os.environ["_GMP_STDC_PRELOADED"] = "1"
    os.execv(sys.executable, [sys.executable] + sys.argv)
    # execv replaces the current process; the line below is never reached.
    return  # pragma: no cover


# ---------------------------------------------------------------------------
# ctypes struct definitions  (must match geometric_medical_phantoms.h)
# ---------------------------------------------------------------------------

class _RespiratoryPhysiology(ctypes.Structure):
    _fields_ = [
        ("minL",         c_double),
        ("maxL",         c_double),
        ("asym_amp",     c_double),
        ("amp_mod_amp",  c_double),
        ("amp_mod_freq", c_double),
        ("rr_var_amp",   c_double),
        ("rr_var_freq",  c_double),
    ]


class _CardiacPhysiology(ctypes.Structure):
    _fields_ = [
        ("lv_edv",            c_double),
        ("lv_esv",            c_double),
        ("rv_edv",            c_double),
        ("rv_esv",            c_double),
        ("la_min",            c_double),
        ("la_max",            c_double),
        ("ra_min",            c_double),
        ("ra_max",            c_double),
        ("hr_var_amp",        c_double),
        ("hr_var_freq",       c_double),
        ("v_amp_amp",         c_double),
        ("v_amp_freq",        c_double),
        ("a_amp_amp",         c_double),
        ("a_amp_freq",        c_double),
        ("bw_amp",            c_double),
        ("bw_freq",           c_double),
        ("s_frac_base",       c_double),
        ("s_frac_mod_amp",    c_double),
        ("s_frac_mod_freq",   c_double),
        ("ventricular_ejection_power", c_double),
        ("lv_filling_power",  c_double),
        ("rv_filling_power",  c_double),
        ("atrial_fill_power", c_double),
        ("atrial_emptying_power", c_double),
        ("atrial_phase_shift", c_double),
        ("atrial_bw_coupling", c_double),
        ("lv_kick_amp_frac",  c_double),
        ("lv_kick_center",    c_double),
        ("lv_kick_width",     c_double),
        ("rv_kick_amp_frac",  c_double),
        ("rv_kick_center",    c_double),
        ("rv_kick_width",     c_double),
        ("la_contr_amp_frac", c_double),
        ("la_contr_center",   c_double),
        ("la_contr_width",    c_double),
        ("ra_contr_amp_frac", c_double),
        ("ra_contr_center",   c_double),
        ("ra_contr_width",    c_double),
    ]


class _TissueIntensities(ctypes.Structure):
    _fields_ = [
        ("lung",          c_double),
        ("heart",         c_double),
        ("vessels_blood", c_double),
        ("bones",         c_double),
        ("liver",         c_double),
        ("stomach",       c_double),
        ("body",          c_double),
        ("lv_blood",      c_double),
        ("rv_blood",      c_double),
        ("la_blood",      c_double),
        ("ra_blood",      c_double),
    ]


class _TubesGeometry(ctypes.Structure):
    _fields_ = [
        ("outer_radius",          c_double),
        ("outer_height",          c_double),
        ("tubes_height_fraction", c_double),
        ("tube_wall_thickness",   c_double),
        ("gap_fraction",          c_double),
    ]


class _TubesIntensities(ctypes.Structure):
    _fields_ = [
        ("outer_cylinder", c_double),
        ("tube_wall",      c_double),
        ("tube_fillings",  POINTER(c_double)),
        ("n_tubes",        c_int),
    ]


class _SheppLoganIntensities(ctypes.Structure):
    _fields_ = [
        ("skull",         c_double),
        ("brain",         c_double),
        ("right_big",     c_double),
        ("left_big",      c_double),
        ("top",           c_double),
        ("middle_high",   c_double),
        ("bottom_left",   c_double),
        ("middle_low",    c_double),
        ("bottom_center", c_double),
        ("bottom_right",  c_double),
        ("extra_1",       c_double),
        ("extra_2",       c_double),
    ]


# ---------------------------------------------------------------------------
# Public dataclasses (user-facing)
# ---------------------------------------------------------------------------

@dataclass
class RespiratoryPhysiology:
    minL: float = 2.4
    maxL: float = 3.0
    asym_amp: float = 0.2
    amp_mod_amp: float = 0.15
    amp_mod_freq: float = 0.05
    rr_var_amp: float = 0.03
    rr_var_freq: float = 0.03

    def _to_c(self) -> _RespiratoryPhysiology:
        return _RespiratoryPhysiology(
            self.minL, self.maxL, self.asym_amp,
            self.amp_mod_amp, self.amp_mod_freq,
            self.rr_var_amp, self.rr_var_freq,
        )


@dataclass
class CardiacPhysiology:
    lv_edv: float = 130.0
    lv_esv: float = 55.0
    rv_edv: float = 140.0
    rv_esv: float = 65.0
    la_min: float = 30.0
    la_max: float = 60.0
    ra_min: float = 30.0
    ra_max: float = 60.0
    hr_var_amp: float = 0.03
    hr_var_freq: float = 0.1
    v_amp_amp: float = 0.0
    v_amp_freq: float = 0.08
    a_amp_amp: float = 0.02
    a_amp_freq: float = 0.09
    bw_amp: float = 0.0
    bw_freq: float = 0.03
    s_frac_base: float = 0.35
    s_frac_mod_amp: float = 0.08
    s_frac_mod_freq: float = 0.1
    ventricular_ejection_power: float = 3.0
    lv_filling_power: float = 2.2
    rv_filling_power: float = 2.0
    atrial_fill_power: float = 1.5
    atrial_emptying_power: float = 3.0
    atrial_phase_shift: float = 0.7
    atrial_bw_coupling: float = 0.8
    lv_kick_amp_frac: float = 0.07
    lv_kick_center: float = 0.92
    lv_kick_width: float = 0.04
    rv_kick_amp_frac: float = 0.06
    rv_kick_center: float = 0.92
    rv_kick_width: float = 0.05
    la_contr_amp_frac: float = 0.15
    la_contr_center: float = 0.95
    la_contr_width: float = 0.03
    ra_contr_amp_frac: float = 0.12
    ra_contr_center: float = 0.95
    ra_contr_width: float = 0.03

    def _to_c(self) -> _CardiacPhysiology:
        return _CardiacPhysiology(
            self.lv_edv, self.lv_esv, self.rv_edv, self.rv_esv,
            self.la_min, self.la_max, self.ra_min, self.ra_max,
            self.hr_var_amp, self.hr_var_freq,
            self.v_amp_amp, self.v_amp_freq,
            self.a_amp_amp, self.a_amp_freq,
            self.bw_amp, self.bw_freq,
            self.s_frac_base,
            self.s_frac_mod_amp, self.s_frac_mod_freq,
            self.ventricular_ejection_power,
            self.lv_filling_power, self.rv_filling_power,
            self.atrial_fill_power, self.atrial_emptying_power,
            self.atrial_phase_shift, self.atrial_bw_coupling,
            self.lv_kick_amp_frac, self.lv_kick_center, self.lv_kick_width,
            self.rv_kick_amp_frac, self.rv_kick_center, self.rv_kick_width,
            self.la_contr_amp_frac, self.la_contr_center, self.la_contr_width,
            self.ra_contr_amp_frac, self.ra_contr_center, self.ra_contr_width,
        )


@dataclass
class TissueIntensities:
    lung: float = 0.08
    heart: float = 0.65
    vessels_blood: float = 1.0
    bones: float = 0.85
    liver: float = 0.55
    stomach: float = 0.9
    body: float = 0.25
    lv_blood: float = 0.98
    rv_blood: float = 0.99
    la_blood: float = 0.97
    ra_blood: float = 0.96

    def _to_c(self) -> _TissueIntensities:
        return _TissueIntensities(
            self.lung, self.heart, self.vessels_blood, self.bones,
            self.liver, self.stomach, self.body,
            self.lv_blood, self.rv_blood, self.la_blood, self.ra_blood,
        )


@dataclass
class TubesGeometry:
    outer_radius: float = 0.4
    outer_height: float = 0.8
    tubes_height_fraction: float = 0.9
    tube_wall_thickness: float = 0.025
    gap_fraction: float = 0.3

    def _to_c(self) -> _TubesGeometry:
        return _TubesGeometry(
            self.outer_radius, self.outer_height, self.tubes_height_fraction,
            self.tube_wall_thickness, self.gap_fraction,
        )


@dataclass
class TubesIntensities:
    outer_cylinder: float = 0.25
    tube_wall: float = 0.0
    tube_fillings: list = field(default_factory=lambda: [0.1, 0.3, 0.5, 0.7, 0.9, 1.0])

    def _to_c(self):
        """Returns (struct, backing_array) — keep both alive during the call."""
        n = len(self.tube_fillings)
        arr = (c_double * n)(*self.tube_fillings)
        s = _TubesIntensities(
            self.outer_cylinder,
            self.tube_wall,
            arr,
            c_int(n),
        )
        return s, arr


@dataclass
class SheppLoganIntensities:
    skull: float = 0.0
    brain: float = 0.0
    right_big: float = 0.0
    left_big: float = 0.0
    top: float = 0.0
    middle_high: float = 0.0
    bottom_left: float = 0.0
    middle_low: float = 0.0
    bottom_center: float = 0.0
    bottom_right: float = 0.0
    extra_1: float = 0.0
    extra_2: float = 0.0

    def _to_c(self) -> _SheppLoganIntensities:
        return _SheppLoganIntensities(
            self.skull, self.brain, self.right_big, self.left_big,
            self.top, self.middle_high, self.bottom_left, self.middle_low,
            self.bottom_center, self.bottom_right, self.extra_1, self.extra_2,
        )

    @staticmethod
    def ct_default() -> "SheppLoganIntensities":
        """Original CT intensities (Shepp & Logan 1974)."""
        return SheppLoganIntensities(
            skull=2.0, brain=-0.98, right_big=-0.02, left_big=-0.02,
            top=0.01, middle_high=0.01, bottom_left=0.01, middle_low=0.01,
            bottom_center=0.01, bottom_right=0.01, extra_1=0.02, extra_2=-0.02,
        )

    @staticmethod
    def mri_default() -> "SheppLoganIntensities":
        """Toft's MRI-adapted intensities."""
        return SheppLoganIntensities(
            skull=1.0, brain=-0.8, right_big=-0.2, left_big=-0.2,
            top=0.1, middle_high=0.1, bottom_left=0.1, middle_low=0.1,
            bottom_center=0.1, bottom_right=0.1, extra_1=0.2, extra_2=-0.2,
        )


# Axis constants
AXIS_AXIAL    = 0
AXIS_CORONAL  = 1
AXIS_SAGITTAL = 2


# ---------------------------------------------------------------------------
# Main wrapper class
# ---------------------------------------------------------------------------

class GMPLib:
    """
    Python interface to the GeometricMedicalPhantoms shared library.

    Parameters
    ----------
    lib_path : str, optional
        Path to the shared library.  If omitted the library is searched next
        to this file (see _find_lib).
    """

    def __init__(self, lib_path: Optional[str] = None) -> None:
        path = lib_path or _find_lib()
        # On Linux, pre-load the bundled libstdc++ (if present) so the dynamic
        # linker uses the newer version shipped with the Julia runtime rather
        # than the (potentially older) system library.
        _preload_bundled_libstdcxx(path)
        self._lib = ctypes.CDLL(path)
        self._setup_signatures()

    # ------------------------------------------------------------------
    # Private helpers
    # ------------------------------------------------------------------

    def _setup_signatures(self) -> None:
        lib = self._lib

        lib.gmp_version.restype  = c_char_p
        lib.gmp_version.argtypes = []

        lib.gmp_signal_length.restype  = c_int
        lib.gmp_signal_length.argtypes = [c_double, c_double]

        lib.gmp_respiratory_physiology_default.restype  = None
        lib.gmp_respiratory_physiology_default.argtypes = [POINTER(_RespiratoryPhysiology)]

        lib.gmp_cardiac_physiology_default.restype  = None
        lib.gmp_cardiac_physiology_default.argtypes = [POINTER(_CardiacPhysiology)]

        lib.gmp_tissue_intensities_default.restype  = None
        lib.gmp_tissue_intensities_default.argtypes = [POINTER(_TissueIntensities)]

        lib.gmp_tubes_geometry_default.restype  = None
        lib.gmp_tubes_geometry_default.argtypes = [POINTER(_TubesGeometry)]

        lib.gmp_tubes_intensities_default.restype  = None
        lib.gmp_tubes_intensities_default.argtypes = [
            POINTER(_TubesIntensities), POINTER(c_double), c_int
        ]

        lib.gmp_shepp_logan_ct_default.restype  = None
        lib.gmp_shepp_logan_ct_default.argtypes = [POINTER(_SheppLoganIntensities)]

        lib.gmp_shepp_logan_mri_default.restype  = None
        lib.gmp_shepp_logan_mri_default.argtypes = [POINTER(_SheppLoganIntensities)]

        lib.gmp_generate_respiratory_signal.restype  = c_int
        lib.gmp_generate_respiratory_signal.argtypes = [
            c_double, c_double, c_double,
            POINTER(_RespiratoryPhysiology),
            POINTER(c_double), POINTER(c_double), c_int,
        ]

        lib.gmp_generate_cardiac_signals.restype  = c_int
        lib.gmp_generate_cardiac_signals.argtypes = [
            c_double, c_double, c_double,
            POINTER(_CardiacPhysiology),
            POINTER(c_double), POINTER(c_double), POINTER(c_double),
            POINTER(c_double), POINTER(c_double), c_int,
        ]

        lib.gmp_create_shepp_logan_phantom_3d.restype  = c_int
        lib.gmp_create_shepp_logan_phantom_3d.argtypes = [
            c_int, c_int, c_int,
            POINTER(_SheppLoganIntensities), POINTER(c_float),
        ]

        lib.gmp_create_shepp_logan_phantom_2d.restype  = c_int
        lib.gmp_create_shepp_logan_phantom_2d.argtypes = [
            c_int, c_int, c_int, c_double,
            POINTER(_SheppLoganIntensities), POINTER(c_float),
        ]

        lib.gmp_create_tubes_phantom_3d.restype  = c_int
        lib.gmp_create_tubes_phantom_3d.argtypes = [
            c_int, c_int, c_int,
            POINTER(_TubesGeometry), POINTER(_TubesIntensities), POINTER(c_float),
        ]

        lib.gmp_create_tubes_phantom_2d.restype  = c_int
        lib.gmp_create_tubes_phantom_2d.argtypes = [
            c_int, c_int, c_int, c_double,
            POINTER(_TubesGeometry), POINTER(_TubesIntensities), POINTER(c_float),
        ]

        lib.gmp_create_torso_phantom_3d.restype  = c_int
        lib.gmp_create_torso_phantom_3d.argtypes = [
            c_int, c_int, c_int, c_int,
            POINTER(c_double), POINTER(c_double), POINTER(c_double),
            POINTER(c_double), POINTER(c_double),
            POINTER(_TissueIntensities), POINTER(c_float),
        ]

        lib.gmp_create_torso_phantom_2d.restype  = c_int
        lib.gmp_create_torso_phantom_2d.argtypes = [
            c_int, c_int, c_int, c_double, c_int,
            POINTER(c_double), POINTER(c_double), POINTER(c_double),
            POINTER(c_double), POINTER(c_double),
            POINTER(_TissueIntensities), POINTER(c_float),
        ]

    @staticmethod
    def _check(ret: int, name: str) -> None:
        if ret != 0:
            raise RuntimeError(f"{name} returned error code {ret}")

    @staticmethod
    def _to_double_ptr(arr: Optional[np.ndarray]):
        if arr is None:
            return None
        a = np.ascontiguousarray(arr, dtype=np.float64)
        return a.ctypes.data_as(POINTER(c_double)), a  # return array to keep alive

    # ------------------------------------------------------------------
    # Utility
    # ------------------------------------------------------------------

    def version(self) -> str:
        """Return the library version string."""
        return self._lib.gmp_version().decode()

    def signal_length(self, duration: float, fs: float) -> int:
        """Return the number of samples for a signal with given duration/fs."""
        return int(self._lib.gmp_signal_length(c_double(duration), c_double(fs)))

    # ------------------------------------------------------------------
    # Default-filler factory methods
    # ------------------------------------------------------------------

    def respiratory_physiology_default(self) -> RespiratoryPhysiology:
        s = _RespiratoryPhysiology()
        self._lib.gmp_respiratory_physiology_default(ctypes.byref(s))
        return RespiratoryPhysiology(
            s.minL, s.maxL, s.asym_amp, s.amp_mod_amp, s.amp_mod_freq,
            s.rr_var_amp, s.rr_var_freq,
        )

    def cardiac_physiology_default(self) -> CardiacPhysiology:
        s = _CardiacPhysiology()
        self._lib.gmp_cardiac_physiology_default(ctypes.byref(s))
        return CardiacPhysiology(
            s.lv_edv, s.lv_esv, s.rv_edv, s.rv_esv,
            s.la_min, s.la_max, s.ra_min, s.ra_max,
            s.hr_var_amp, s.hr_var_freq,
            s.v_amp_amp, s.v_amp_freq,
            s.a_amp_amp, s.a_amp_freq,
            s.bw_amp, s.bw_freq,
            s.s_frac_base,
            s.s_frac_mod_amp, s.s_frac_mod_freq,
            s.ventricular_ejection_power,
            s.lv_filling_power, s.rv_filling_power,
            s.atrial_fill_power, s.atrial_emptying_power,
            s.atrial_phase_shift, s.atrial_bw_coupling,
            s.lv_kick_amp_frac, s.lv_kick_center, s.lv_kick_width,
            s.rv_kick_amp_frac, s.rv_kick_center, s.rv_kick_width,
            s.la_contr_amp_frac, s.la_contr_center, s.la_contr_width,
            s.ra_contr_amp_frac, s.ra_contr_center, s.ra_contr_width,
        )

    def tissue_intensities_default(self) -> TissueIntensities:
        s = _TissueIntensities()
        self._lib.gmp_tissue_intensities_default(ctypes.byref(s))
        return TissueIntensities(
            s.lung, s.heart, s.vessels_blood, s.bones, s.liver,
            s.stomach, s.body, s.lv_blood, s.rv_blood, s.la_blood, s.ra_blood,
        )

    def tubes_geometry_default(self) -> TubesGeometry:
        s = _TubesGeometry()
        self._lib.gmp_tubes_geometry_default(ctypes.byref(s))
        return TubesGeometry(
            s.outer_radius, s.outer_height, s.tubes_height_fraction,
            s.tube_wall_thickness, s.gap_fraction,
        )

    def tubes_intensities_default(self, n_tubes: int = 6) -> TubesIntensities:
        arr = (c_double * n_tubes)()
        s = _TubesIntensities()
        self._lib.gmp_tubes_intensities_default(
            ctypes.byref(s), arr, c_int(n_tubes)
        )
        return TubesIntensities(s.outer_cylinder, s.tube_wall, list(arr))

    def shepp_logan_ct_default(self) -> SheppLoganIntensities:
        s = _SheppLoganIntensities()
        self._lib.gmp_shepp_logan_ct_default(ctypes.byref(s))
        return SheppLoganIntensities(
            s.skull, s.brain, s.right_big, s.left_big, s.top, s.middle_high,
            s.bottom_left, s.middle_low, s.bottom_center, s.bottom_right,
            s.extra_1, s.extra_2,
        )

    def shepp_logan_mri_default(self) -> SheppLoganIntensities:
        s = _SheppLoganIntensities()
        self._lib.gmp_shepp_logan_mri_default(ctypes.byref(s))
        return SheppLoganIntensities(
            s.skull, s.brain, s.right_big, s.left_big, s.top, s.middle_high,
            s.bottom_left, s.middle_low, s.bottom_center, s.bottom_right,
            s.extra_1, s.extra_2,
        )

    # ------------------------------------------------------------------
    # Signal generation
    # ------------------------------------------------------------------

    def generate_respiratory_signal(
        self,
        duration: float,
        fs: float,
        rr: float,
        physiology: Optional[RespiratoryPhysiology] = None,
    ) -> Tuple[np.ndarray, np.ndarray]:
        """
        Generate a synthetic respiratory signal.

        Returns
        -------
        t : np.ndarray, shape (n,)
            Time vector in seconds.
        signal : np.ndarray, shape (n,)
            Lung volume in liters.
        """
        phys = (physiology or RespiratoryPhysiology())._to_c()
        n = self.signal_length(duration, fs)
        t_buf   = np.empty(n, dtype=np.float64)
        sig_buf = np.empty(n, dtype=np.float64)
        ret = self._lib.gmp_generate_respiratory_signal(
            c_double(duration), c_double(fs), c_double(rr),
            ctypes.byref(phys),
            t_buf.ctypes.data_as(POINTER(c_double)),
            sig_buf.ctypes.data_as(POINTER(c_double)),
            c_int(n),
        )
        self._check(ret, "gmp_generate_respiratory_signal")
        return t_buf, sig_buf

    def generate_cardiac_signals(
        self,
        duration: float,
        fs: float,
        hr: float,
        physiology: Optional[CardiacPhysiology] = None,
    ) -> Tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
        """
        Generate cardiac chamber volume signals.

        Returns
        -------
        t, lv, rv, la, ra : np.ndarray, each shape (n,)
            Time (s) and chamber volumes (mL) for LV, RV, LA, RA.
        """
        phys = (physiology or CardiacPhysiology())._to_c()
        n = self.signal_length(duration, fs)
        bufs = [np.empty(n, dtype=np.float64) for _ in range(5)]
        ptrs = [b.ctypes.data_as(POINTER(c_double)) for b in bufs]
        ret = self._lib.gmp_generate_cardiac_signals(
            c_double(duration), c_double(fs), c_double(hr),
            ctypes.byref(phys),
            *ptrs, c_int(n),
        )
        self._check(ret, "gmp_generate_cardiac_signals")
        return tuple(bufs)  # type: ignore[return-value]

    # ------------------------------------------------------------------
    # Shepp-Logan phantom
    # ------------------------------------------------------------------

    def create_shepp_logan_phantom_3d(
        self,
        nx: int,
        ny: int,
        nz: int,
        intensities: Optional[SheppLoganIntensities] = None,
    ) -> np.ndarray:
        """Create a 3-D Shepp-Logan phantom.  Returns array of shape (nx, ny, nz)."""
        ti = (intensities or SheppLoganIntensities.ct_default())._to_c()
        buf = np.empty(nx * ny * nz, dtype=np.float32)
        ret = self._lib.gmp_create_shepp_logan_phantom_3d(
            c_int(nx), c_int(ny), c_int(nz),
            ctypes.byref(ti),
            buf.ctypes.data_as(POINTER(c_float)),
        )
        self._check(ret, "gmp_create_shepp_logan_phantom_3d")
        return buf.reshape((nx, ny, nz), order="F")

    def create_shepp_logan_phantom_2d(
        self,
        nx: int,
        ny: int,
        axis: int = AXIS_AXIAL,
        slice_position: float = 0.0,
        intensities: Optional[SheppLoganIntensities] = None,
    ) -> np.ndarray:
        """Create a 2-D Shepp-Logan slice.  Returns array of shape (nx, ny)."""
        ti = (intensities or SheppLoganIntensities.ct_default())._to_c()
        buf = np.empty(nx * ny, dtype=np.float32)
        ret = self._lib.gmp_create_shepp_logan_phantom_2d(
            c_int(nx), c_int(ny), c_int(axis), c_double(slice_position),
            ctypes.byref(ti),
            buf.ctypes.data_as(POINTER(c_float)),
        )
        self._check(ret, "gmp_create_shepp_logan_phantom_2d")
        return buf.reshape((nx, ny), order="F")

    # ------------------------------------------------------------------
    # Tubes phantom
    # ------------------------------------------------------------------

    def create_tubes_phantom_3d(
        self,
        nx: int,
        ny: int,
        nz: int,
        geometry: Optional[TubesGeometry] = None,
        intensities: Optional[TubesIntensities] = None,
    ) -> np.ndarray:
        """Create a 3-D tubes phantom.  Returns array of shape (nx, ny, nz)."""
        tg = (geometry or TubesGeometry())._to_c()
        ti, ti_arr = (intensities or TubesIntensities())._to_c()
        buf = np.empty(nx * ny * nz, dtype=np.float32)
        ret = self._lib.gmp_create_tubes_phantom_3d(
            c_int(nx), c_int(ny), c_int(nz),
            ctypes.byref(tg), ctypes.byref(ti),
            buf.ctypes.data_as(POINTER(c_float)),
        )
        self._check(ret, "gmp_create_tubes_phantom_3d")
        return buf.reshape((nx, ny, nz), order="F")

    def create_tubes_phantom_2d(
        self,
        nx: int,
        ny: int,
        axis: int = AXIS_AXIAL,
        slice_position: float = 0.0,
        geometry: Optional[TubesGeometry] = None,
        intensities: Optional[TubesIntensities] = None,
    ) -> np.ndarray:
        """Create a 2-D tubes phantom slice.  Returns array of shape (nx, ny)."""
        tg = (geometry or TubesGeometry())._to_c()
        ti, ti_arr = (intensities or TubesIntensities())._to_c()
        buf = np.empty(nx * ny, dtype=np.float32)
        ret = self._lib.gmp_create_tubes_phantom_2d(
            c_int(nx), c_int(ny), c_int(axis), c_double(slice_position),
            ctypes.byref(tg), ctypes.byref(ti),
            buf.ctypes.data_as(POINTER(c_float)),
        )
        self._check(ret, "gmp_create_tubes_phantom_2d")
        return buf.reshape((nx, ny), order="F")

    # ------------------------------------------------------------------
    # Torso phantom
    # ------------------------------------------------------------------

    def create_torso_phantom_3d(
        self,
        nx: int,
        ny: int,
        nz: int,
        resp_signal: Optional[np.ndarray] = None,
        cardiac_lv: Optional[np.ndarray] = None,
        cardiac_rv: Optional[np.ndarray] = None,
        cardiac_la: Optional[np.ndarray] = None,
        cardiac_ra: Optional[np.ndarray] = None,
        tissue: Optional[TissueIntensities] = None,
    ) -> np.ndarray:
        """
        Create a 3-D (or 4-D) torso phantom.

        If resp_signal / cardiac_* are provided, the output has shape
        (nx, ny, nz, n_frames); otherwise (nx, ny, nz, 1) for a static phantom.
        """
        ti = (tissue or TissueIntensities())._to_c()

        signals = [resp_signal, cardiac_lv, cardiac_rv, cardiac_la, cardiac_ra]
        n_frames = max((len(s) for s in signals if s is not None), default=0)
        nf = max(n_frames, 1)

        def _ptr(arr):
            if arr is None:
                return None, None
            a = np.ascontiguousarray(arr, dtype=np.float64)
            return a.ctypes.data_as(POINTER(c_double)), a

        r_ptr,  r_arr  = _ptr(resp_signal)
        lv_ptr, lv_arr = _ptr(cardiac_lv)
        rv_ptr, rv_arr = _ptr(cardiac_rv)
        la_ptr, la_arr = _ptr(cardiac_la)
        ra_ptr, ra_arr = _ptr(cardiac_ra)

        buf = np.empty(nx * ny * nz * nf, dtype=np.float32)
        ret = self._lib.gmp_create_torso_phantom_3d(
            c_int(nx), c_int(ny), c_int(nz), c_int(nf),
            r_ptr, lv_ptr, rv_ptr, la_ptr, ra_ptr,
            ctypes.byref(ti),
            buf.ctypes.data_as(POINTER(c_float)),
        )
        self._check(ret, "gmp_create_torso_phantom_3d")
        return buf.reshape((nx, ny, nz, nf), order="F")

    def create_torso_phantom_2d(
        self,
        nx: int,
        ny: int,
        axis: int = AXIS_AXIAL,
        slice_position: float = 0.0,
        resp_signal: Optional[np.ndarray] = None,
        cardiac_lv: Optional[np.ndarray] = None,
        cardiac_rv: Optional[np.ndarray] = None,
        cardiac_la: Optional[np.ndarray] = None,
        cardiac_ra: Optional[np.ndarray] = None,
        tissue: Optional[TissueIntensities] = None,
    ) -> np.ndarray:
        """
        Create a 2-D torso phantom slice (or 3-D with time).

        Returns shape (nx, ny, n_frames) where n_frames >= 1.
        """
        ti = (tissue or TissueIntensities())._to_c()

        signals = [resp_signal, cardiac_lv, cardiac_rv, cardiac_la, cardiac_ra]
        n_frames = max((len(s) for s in signals if s is not None), default=0)
        nf = max(n_frames, 1)

        def _ptr(arr):
            if arr is None:
                return None, None
            a = np.ascontiguousarray(arr, dtype=np.float64)
            return a.ctypes.data_as(POINTER(c_double)), a

        r_ptr,  r_arr  = _ptr(resp_signal)
        lv_ptr, lv_arr = _ptr(cardiac_lv)
        rv_ptr, rv_arr = _ptr(cardiac_rv)
        la_ptr, la_arr = _ptr(cardiac_la)
        ra_ptr, ra_arr = _ptr(cardiac_ra)

        buf = np.empty(nx * ny * nf, dtype=np.float32)
        ret = self._lib.gmp_create_torso_phantom_2d(
            c_int(nx), c_int(ny), c_int(axis), c_double(slice_position),
            c_int(nf),
            r_ptr, lv_ptr, rv_ptr, la_ptr, ra_ptr,
            ctypes.byref(ti),
            buf.ctypes.data_as(POINTER(c_float)),
        )
        self._check(ret, "gmp_create_torso_phantom_2d")
        return buf.reshape((nx, ny, nf), order="F")
