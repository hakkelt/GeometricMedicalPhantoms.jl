# Python

A pure-[`ctypes`](https://docs.python.org/3/library/ctypes.html) wrapper is
provided by the `geometric-medical-phantoms` PyPI package.  It requires
**Python ≥ 3.9** and [NumPy](https://numpy.org/).  No compilation step is needed.

## Installation

### Platform-specific binary wheel (recommended)

Pre-built wheels containing the compiled shared library are published to each
[GitHub release](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest).
Install the wheel for your platform directly with `pip`: `pip install "<path of *.whl>"`.

### Pure-Python stub from PyPI

A lightweight source distribution is published on
[PyPI](https://pypi.org/project/geometric-medical-phantoms/).
It contains only the Python wrapper; the compiled library must be provided
separately (e.g. from the binary wheel or built from source).

```bash
pip install geometric-medical-phantoms
```

### From source

```bash
git clone https://github.com/hakkelt/GeometricMedicalPhantoms.jl
cd GeometricMedicalPhantoms.jl/lib
julia --project=. build.jl         # builds lib/build/lib/libgeomphantoms.so
pip install python/                 # installs the wrapper
```

## Quick start

```python
from geometric_medical_phantoms import GMPLib

# Binary wheel installation — library is found automatically:
lib = GMPLib()

# Or pass an explicit path to the shared library:
lib = GMPLib("path/to/build/lib/libgeomphantoms.so")

print(lib.version())  # e.g. "1.0.2"
```

## Shepp-Logan phantom

```python
import numpy as np

# 3-D phantom with CT defaults
ti = lib.shepp_logan_ct_default()
phantom = lib.create_shepp_logan_phantom_3d(128, 128, 128, ti)
# phantom.shape == (128, 128, 128), dtype float32, column-major (Fortran) order

# Custom intensities
from geometric_medical_phantoms import SheppLoganIntensities
ti = SheppLoganIntensities.ct_default()
ti.brain = -0.90   # increase brain contrast
phantom  = lib.create_shepp_logan_phantom_3d(256, 256, 256, ti)

# 2-D axial slice
from geometric_medical_phantoms import AXIS_AXIAL
sl2d = lib.create_shepp_logan_phantom_2d(256, 256, axis=AXIS_AXIAL)
# sl2d.shape == (256, 256)
```

## Tubes phantom

```python
from geometric_medical_phantoms import TubesGeometry, TubesIntensities

tg = lib.tubes_geometry_default()
ti = TubesIntensities(
    outer_cylinder=0.3,
    tube_wall=0.0,
    tube_fillings=[0.1, 0.2, 0.4, 0.6, 0.8, 1.0],
)
tubes = lib.create_tubes_phantom_3d(256, 256, 128, geometry=tg, intensities=ti)
```

## Torso phantom (static)

```python
ti = lib.tissue_intensities_default()
torso = lib.create_torso_phantom_3d(128, 128, 128, tissue=ti)
# torso.shape == (128, 128, 128, 1)  — one static frame
```

## Physiological signals

```python
# Respiratory signal — 60 s at 50 Hz, 15 breaths/min
phys = lib.respiratory_physiology_default()
phys.rr_var_amp = 0.05   # increase variability

t, sig = lib.generate_respiratory_signal(60.0, 50.0, 15.0, phys)
# t.shape == sig.shape == (3000,)

# Cardiac signals — 10 s at 500 Hz, 70 bpm
cphys = lib.cardiac_physiology_default()
tc, lv, rv, la, ra = lib.generate_cardiac_signals(10.0, 500.0, 70.0, cphys)
```

## Dynamic torso phantom

Combine pre-generated signals with phantom creation to produce a 4-D cine array:

```python
# Generate respiratory signal (resampled to desired frame count)
t_resp, resp_signal = lib.generate_respiratory_signal(10.0, 10.0, 15.0)
# t_resp has 100 samples — one frame per 0.1 s

# Generate cardiac signals at the same frame rate
tc, lv, rv, la, ra = lib.generate_cardiac_signals(10.0, 10.0, 70.0)

# 4-D torso with combined respiratory + cardiac motion
torso = lib.create_torso_phantom_3d(
    64, 64, 64,
    resp_signal=resp_signal,
    cardiac_lv=lv, cardiac_rv=rv,
    cardiac_la=la, cardiac_ra=ra,
    tissue=lib.tissue_intensities_default(),
)
# torso.shape == (64, 64, 64, 100)
```

For 2-D cine slices:

```python
from geometric_medical_phantoms import AXIS_CORONAL

slice_cine = lib.create_torso_phantom_2d(
    128, 128,
    axis=AXIS_CORONAL,
    slice_position=0.0,
    resp_signal=resp_signal,
)
# slice_cine.shape == (128, 128, 100)
```

## Working with the Fortran-order arrays

The library returns arrays in column-major (Fortran/Julia) order, which is the
native memory layout of Julia.  NumPy defaults to C-order, so be aware when
indexing or passing arrays to C-order libraries:

```python
# Transpose for C-order visualisation
import matplotlib.pyplot as plt
plt.imshow(phantom[:, :, 64].T, cmap="gray")   # axial slice

# Convert to C-order copy if needed
phantom_c = np.ascontiguousarray(phantom)
```

## Signal length helper

Use `lib.signal_length()` to pre-compute buffer sizes without generating the
signal:

```python
n = lib.signal_length(60.0, 500.0)  # 60 s at 500 Hz → 30000
```

## Axis constants

```python
from geometric_medical_phantoms import AXIS_AXIAL, AXIS_CORONAL, AXIS_SAGITTAL
```

| Constant | Value | Plane |
|---|---|---|
| `AXIS_AXIAL` | 0 | x / y (slice along z) |
| `AXIS_CORONAL` | 1 | x / z (slice along y) |
| `AXIS_SAGITTAL` | 2 | y / z (slice along x) |

## Full runnable example

A complete demonstration script is provided at `lib/python/example.py`.  Run it
after building the library:

```sh
python lib/python/example.py lib/build/lib/libgeomphantoms.so
```

It saves several PNG images to the working directory showcasing each phantom type
and both signal generators.

## API reference

### Data classes

All data classes are `dataclass`-like objects whose fields can be read and
written as regular Python attributes.

---

#### `RespiratoryPhysiology`

| Field | Type | Default | Description |
|---|---|---|---|
| `minL` | `float` | 2.4 | Minimum lung volume (L) |
| `maxL` | `float` | 3.0 | Maximum lung volume (L) |
| `asym_amp` | `float` | 0.2 | Asymmetry harmonic amplitude |
| `amp_mod_amp` | `float` | 0.15 | Amplitude modulation amplitude |
| `amp_mod_freq` | `float` | 0.05 | Amplitude modulation frequency (Hz) |
| `rr_var_amp` | `float` | 0.03 | RR-rate variability amplitude |
| `rr_var_freq` | `float` | 0.03 | RR-rate variability frequency (Hz) |

---

#### `CardiacPhysiology`

| Field | Type | Default | Description |
|---|---|---|---|
| `lv_edv` | `float` | 130 | LV end-diastolic volume (mL) |
| `lv_esv` | `float` | 55 | LV end-systolic volume (mL) |
| `rv_edv` | `float` | 140 | RV end-diastolic volume (mL) |
| `rv_esv` | `float` | 65 | RV end-systolic volume (mL) |
| `la_min` | `float` | 30 | LA minimum volume (mL) |
| `la_max` | `float` | 60 | LA maximum volume (mL) |
| `ra_min` | `float` | 30 | RA minimum volume (mL) |
| `ra_max` | `float` | 60 | RA maximum volume (mL) |
| `hr_var_amp` | `float` | 0.03 | HR variability amplitude |
| `hr_var_freq` | `float` | 0.1 | HR variability frequency (Hz) |
| `v_amp_amp` | `float` | 0.0 | Ventricular amplitude-modulation amplitude |
| `v_amp_freq` | `float` | 0.08 | Ventricular amplitude-modulation frequency (Hz) |
| `a_amp_amp` | `float` | 0.02 | Atrial amplitude-modulation amplitude |
| `a_amp_freq` | `float` | 0.09 | Atrial amplitude-modulation frequency (Hz) |
| `bw_amp` | `float` | 0.0 | Baseline wander amplitude (mL) |
| `bw_freq` | `float` | 0.03 | Baseline wander frequency (Hz) |
| `s_frac_base` | `float` | 0.35 | Base systole fraction (0–1) |
| `s_frac_mod_amp` | `float` | 0.08 | Systole-fraction modulation amplitude |
| `s_frac_mod_freq` | `float` | 0.1 | Systole-fraction modulation frequency (Hz) |
| `ventricular_ejection_power` | `float` | 3.0 | Ventricular emptying sharpness |
| `lv_filling_power` | `float` | 2.2 | LV filling sharpness |
| `rv_filling_power` | `float` | 2.0 | RV filling sharpness |
| `atrial_fill_power` | `float` | 1.5 | Atrial filling sharpness |
| `atrial_emptying_power` | `float` | 3.0 | Atrial emptying sharpness |
| `atrial_phase_shift` | `float` | 0.7 | Atrial phase shift relative to ventricles |
| `atrial_bw_coupling` | `float` | 0.8 | Atrial baseline-wander coupling |
| `lv_kick_amp_frac` | `float` | 0.07 | LV atrial kick amplitude fraction |
| `lv_kick_center` | `float` | 0.92 | LV atrial kick centre (phase, 0–1) |
| `lv_kick_width` | `float` | 0.04 | LV atrial kick width |
| `rv_kick_amp_frac` | `float` | 0.06 | RV atrial kick amplitude fraction |
| `rv_kick_center` | `float` | 0.92 | RV atrial kick centre |
| `rv_kick_width` | `float` | 0.05 | RV atrial kick width |
| `la_contr_amp_frac` | `float` | 0.15 | LA contraction amplitude fraction |
| `la_contr_center` | `float` | 0.95 | LA contraction centre |
| `la_contr_width` | `float` | 0.03 | LA contraction width |
| `ra_contr_amp_frac` | `float` | 0.12 | RA contraction amplitude fraction |
| `ra_contr_center` | `float` | 0.95 | RA contraction centre |
| `ra_contr_width` | `float` | 0.03 | RA contraction width |

---

#### `TissueIntensities`

| Field | Type | Default | Tissue |
|---|---|---|---|
| `lung` | `float` | 0.08 | Lung |
| `heart` | `float` | 0.65 | Heart muscle |
| `vessels_blood` | `float` | 1.0 | Blood in vessels |
| `bones` | `float` | 0.85 | Bone |
| `liver` | `float` | 0.55 | Liver |
| `stomach` | `float` | 0.9 | Stomach |
| `body` | `float` | 0.25 | General body tissue |
| `lv_blood` | `float` | 0.98 | LV blood pool |
| `rv_blood` | `float` | 0.99 | RV blood pool |
| `la_blood` | `float` | 0.97 | LA blood pool |
| `ra_blood` | `float` | 0.96 | RA blood pool |

---

#### `TubesGeometry`

| Field | Type | Default | Description |
|---|---|---|---|
| `outer_radius` | `float` | 0.4 | Outer cylinder radius (fraction of FOV) |
| `outer_height` | `float` | 0.8 | Outer cylinder height (fraction of FOV) |
| `tubes_height_fraction` | `float` | 0.9 | Tube height / outer height |
| `tube_wall_thickness` | `float` | 0.025 | Wall thickness (fraction of FOV) |
| `gap_fraction` | `float` | 0.3 | Gap fraction between tubes |

---

#### `TubesIntensities`

| Field | Type | Default | Description |
|---|---|---|---|
| `outer_cylinder` | `float` | 0.25 | Surrounding cylinder intensity |
| `tube_wall` | `float` | 0.0 | Tube wall intensity |
| `tube_fillings` | `list[float]` | `[0.1, 0.3, 0.5, 0.7, 0.9, 1.0]` | Per-tube fill intensities |

---

#### `SheppLoganIntensities`

| Field | Type | CT default | MRI default | Ellipsoid |
|---|---|---|---|---|
| `skull` | `float` | 2.0 | 0.0 | Outer skull boundary |
| `brain` | `float` | -0.98 | 1.0 | Brain interior |
| `right_big` | `float` | -0.02 | -0.8 | Large right ellipsoid |
| `left_big` | `float` | -0.02 | -0.8 | Large left ellipsoid |
| `top` | `float` | 0.01 | 0.4 | Top ellipsoid |
| `middle_high` | `float` | 0.01 | 0.2 | Upper-middle ellipsoid |
| `bottom_left` | `float` | -0.01 | -0.2 | Lower-left ellipsoid |
| `middle_low` | `float` | 0.01 | 0.2 | Lower-middle ellipsoid |
| `bottom_center` | `float` | 0.01 | 0.2 | Bottom-centre ellipsoid |
| `bottom_right` | `float` | 0.01 | 0.2 | Bottom-right ellipsoid |
| `extra_1` | `float` | -0.02 | 0.0 | Extra ellipsoid 1 |
| `extra_2` | `float` | -0.02 | 0.0 | Extra ellipsoid 2 |

Class methods:
- `SheppLoganIntensities.ct_default()` — returns the CT intensity struct
- `SheppLoganIntensities.mri_default()` — returns the MRI intensity struct

---

### `GMPLib`

#### Constructor

```python
GMPLib(lib_path: str | None = None)
```

Loads the shared library.  If `lib_path` is `None`, the library bundled with
the wheel is used.

---

#### Utility

```python
lib.version() -> str
```
Returns the package version string (e.g. `"1.0.2"`).

```python
lib.signal_length(duration: float, fs: float) -> int
```
Returns the number of samples for a signal of `duration` seconds at `fs` Hz.

---

#### Default-value factories

```python
lib.respiratory_physiology_default() -> RespiratoryPhysiology
lib.cardiac_physiology_default()     -> CardiacPhysiology
lib.tissue_intensities_default()     -> TissueIntensities
lib.tubes_geometry_default()         -> TubesGeometry
lib.tubes_intensities_default(n_tubes: int = 6) -> TubesIntensities
lib.shepp_logan_ct_default()         -> SheppLoganIntensities
lib.shepp_logan_mri_default()        -> SheppLoganIntensities
```

---

#### Signal generation

```python
lib.generate_respiratory_signal(
    duration: float,
    fs: float,
    rr: float,
    physiology: RespiratoryPhysiology | None = None,
) -> tuple[np.ndarray, np.ndarray]
```
Returns `(t, signal)` — both `float64` arrays of length `signal_length(duration, fs)`.

```python
lib.generate_cardiac_signals(
    duration: float,
    fs: float,
    hr: float,
    physiology: CardiacPhysiology | None = None,
) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray, np.ndarray]
```
Returns `(t, lv, rv, la, ra)` — all `float64` arrays of length
`signal_length(duration, fs)`.

---

#### Shepp-Logan phantom

```python
lib.create_shepp_logan_phantom_3d(
    nx: int, ny: int, nz: int,
    intensities: SheppLoganIntensities | None = None,
) -> np.ndarray   # float32, shape (nx, ny, nz), Fortran order
```

```python
lib.create_shepp_logan_phantom_2d(
    nx: int, ny: int,
    axis: int = AXIS_AXIAL,
    slice_position: float = 0.0,
    intensities: SheppLoganIntensities | None = None,
) -> np.ndarray   # float32, shape (nx, ny)
```

---

#### Tubes phantom

```python
lib.create_tubes_phantom_3d(
    nx: int, ny: int, nz: int,
    geometry: TubesGeometry | None = None,
    intensities: TubesIntensities | None = None,
) -> np.ndarray   # float32, shape (nx, ny, nz), Fortran order
```

```python
lib.create_tubes_phantom_2d(
    nx: int, ny: int,
    axis: int = AXIS_AXIAL,
    slice_position: float = 0.0,
    geometry: TubesGeometry | None = None,
    intensities: TubesIntensities | None = None,
) -> np.ndarray   # float32, shape (nx, ny)
```

---

#### Torso phantom

```python
lib.create_torso_phantom_3d(
    nx: int, ny: int, nz: int,
    resp_signal: np.ndarray | None = None,
    cardiac_lv: np.ndarray | None = None,
    cardiac_rv: np.ndarray | None = None,
    cardiac_la: np.ndarray | None = None,
    cardiac_ra: np.ndarray | None = None,
    tissue: TissueIntensities | None = None,
) -> np.ndarray   # float32, shape (nx, ny, nz) or (nx, ny, nz, n_frames)
```

```python
lib.create_torso_phantom_2d(
    nx: int, ny: int,
    axis: int = AXIS_AXIAL,
    slice_position: float = 0.0,
    resp_signal: np.ndarray | None = None,
    cardiac_lv: np.ndarray | None = None,
    cardiac_rv: np.ndarray | None = None,
    cardiac_la: np.ndarray | None = None,
    cardiac_ra: np.ndarray | None = None,
    tissue: TissueIntensities | None = None,
) -> np.ndarray   # float32, shape (nx, ny) or (nx, ny, n_frames)
```

When any signal vector is provided, `n_frames` equals the length of that
vector and a 4-D (3-D) array is returned.  All provided signal vectors must
have the same length.
