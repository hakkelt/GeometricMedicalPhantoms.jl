# MATLAB

GeometricMedicalPhantoms provides a MATLAB toolbox at
`lib/matlab/toolbox/GeometricMedicalPhantoms.m`. The wrapper no longer talks to
a C-callable shared library. Instead it uses Mex.jl to start Julia inside
MATLAB and calls the Julia package directly.

## Requirements

- MATLAB R2019b or newer
- Julia installed on the system and available on `PATH`
- The `GeometricMedicalPhantoms` Julia package installed in the active Julia environment
- Mex.jl installed once so MATLAB can call Julia through `jl.mex`

The one-time setup may require MATLAB's MEX toolchain because Mex.jl builds the
`mexjulia` bridge during installation.

## Installation

### From GitHub Releases

Download and install the single platform-independent `.mltbx` from the
[latest release](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest):

```
GeometricMedicalPhantoms-matlab.mltbx
```

The toolbox contains only `.m` and `.jl` files — no compiled binaries are
bundled.  The Julia runtime and packages are installed once on your machine
(see [Installation](#installation) below).

### From source

Run the Julia setup script once to install the Julia-side dependencies:

```bash
julia lib/matlab/setup.jl
```

Then add the toolbox directory to MATLAB's path and create the wrapper:

```matlab
addpath('/path/to/GeometricMedicalPhantoms/lib/matlab/toolbox')
lib = GeometricMedicalPhantoms();
disp(lib.version())   % e.g. "1.0.2"
```

If you are working from a local Julia checkout of the package, you can also
activate that project explicitly:

```matlab
lib = GeometricMedicalPhantoms('/path/to/GeometricMedicalPhantoms');
```

## Loading and setup

The constructor loads `GmpBridge.jl` once per MATLAB session and exposes the
same high-level API as the old wrapper, but without any shared-library path
arguments.

```matlab
lib = GeometricMedicalPhantoms();
disp(lib.version())
```

The wrapper stores MATLAB structs as flat numeric vectors when passing them to
Julia. This keeps the interface stable and avoids MATLAB struct marshaling
issues.

## Basic usage

### Shepp-Logan phantom

```matlab
ti = lib.sheppLoganCtDefault();
phantom = lib.createSheppLoganPhantom3D(128, 128, 128, ti);

figure; imagesc(phantom(:,:,64)); colormap gray; axis image;
title('Shepp-Logan - axial z=64');

ti_mri = lib.sheppLoganMriDefault();
sl2d = lib.createSheppLoganPhantom2D(256, 256, lib.AXIS_AXIAL, 0.0, ti_mri);
```

### Tubes phantom

```matlab
tg = lib.tubesGeometryDefault();
ti = lib.tubesIntensitiesDefault();
ti.tube_fillings = [0.1 0.2 0.4 0.6 0.8 1.0];

tubes = lib.createTubesPhantom3D(256, 256, 128, tg, ti);
```

### Physiological signals

```matlab
phys = lib.respiratoryPhysiologyDefault();
phys.rr_var_amp = 0.05;
[t, sig] = lib.generateRespiratorySignal(60.0, 50.0, 15.0, phys);

cphys = lib.cardiacPhysiologyDefault();
[tc, lv, rv, la, ra] = lib.generateCardiacSignals(10.0, 500.0, 70.0, cphys);
```

### Dynamic torso phantom

```matlab
[~, resp] = lib.generateRespiratorySignal(10.0, 10.0, 15.0);
[~, lv, rv, la, ra] = lib.generateCardiacSignals(10.0, 10.0, 70.0);

torso4d = lib.createTorsoPhantom3D(64, 64, 64, ...
    'resp_signal', resp, ...
    'cardiac_lv', lv, 'cardiac_rv', rv, ...
    'cardiac_la', la, 'cardiac_ra', ra);
```

## Axis constants

| Property | Value | Plane |
|---|---|---|
| `lib.AXIS_AXIAL` | 0 | x / y (slice along z) |
| `lib.AXIS_CORONAL` | 1 | x / z (slice along y) |
| `lib.AXIS_SAGITTAL` | 2 | y / z (slice along x) |

## Data layout

Phantoms are returned as MATLAB `single` arrays. The memory layout is
column-major, which is native to both Julia and MATLAB, so no transposition is
needed.

## Troubleshooting

| Issue | Solution |
|---|---|
| `jl` is undefined in MATLAB | Install Mex.jl and rerun `lib/matlab/setup.jl` |
| `GeometricMedicalPhantoms` cannot be constructed | Ensure Julia is installed and the package is available in the active Julia environment |
| `Pkg.add("Mex")` fails during setup | Check that MATLAB's MEX toolchain is configured and Julia can invoke it |
| Toolbox installed but the class is not found | Add `lib/matlab/toolbox` to the MATLAB path or reinstall the toolbox |

## Notes

- The MATLAB wrapper is a thin adapter around the Julia package and keeps the
  public API close to the previous version for compatibility.
- The old `loadlibrary` / `calllib` workflow is no longer used.

## API reference

All methods belong to the `GeometricMedicalPhantoms` class.  Construct an
instance first:

```matlab
lib = GeometricMedicalPhantoms();
% or, to activate a specific Julia project:
lib = GeometricMedicalPhantoms('/path/to/GeometricMedicalPhantoms');
```

---

### Utility

#### `ver = lib.version()`

Returns the Julia package version as a character vector (e.g. `'1.0.2'`).

#### `n = lib.signalLength(duration, fs)`

Returns the integer number of samples for a signal of `duration` seconds
sampled at `fs` Hz.  Equivalent to `round(duration * fs)`.

---

### Default-value factory methods

Each method returns a MATLAB struct populated with library defaults.
Modify individual fields before passing the struct to a generation function.

#### `phys = lib.respiratoryPhysiologyDefault()`

Returns a struct with the following fields (all `double`):

| Field | Default | Description |
|---|---|---|
| `minL` | 2.4 | Minimum lung volume (L) |
| `maxL` | 3.0 | Maximum lung volume (L) |
| `asym_amp` | 0.2 | Asymmetry harmonic amplitude (fraction) |
| `amp_mod_amp` | 0.15 | Amplitude modulation amplitude (fraction) |
| `amp_mod_freq` | 0.05 | Amplitude modulation frequency (Hz) |
| `rr_var_amp` | 0.03 | RR-rate variability amplitude (fraction) |
| `rr_var_freq` | 0.03 | RR-rate variability frequency (Hz) |

#### `phys = lib.cardiacPhysiologyDefault()`

Returns a struct with the following fields (all `double`):

| Field | Default | Description |
|---|---|---|
| `lv_edv` | 130 | LV end-diastolic volume (mL) |
| `lv_esv` | 55 | LV end-systolic volume (mL) |
| `rv_edv` | 140 | RV end-diastolic volume (mL) |
| `rv_esv` | 65 | RV end-systolic volume (mL) |
| `la_min` | 30 | LA minimum volume (mL) |
| `la_max` | 60 | LA maximum volume (mL) |
| `ra_min` | 30 | RA minimum volume (mL) |
| `ra_max` | 60 | RA maximum volume (mL) |
| `hr_var_amp` | 0.0 | HR variability amplitude (fraction) |
| `hr_var_freq` | 0.1 | HR variability frequency (Hz) |
| `v_amp_amp` | 0.0 | Ventricular amplitude-modulation amplitude |
| `v_amp_freq` | 0.08 | Ventricular amplitude-modulation frequency (Hz) |
| `a_amp_amp` | 0.02 | Atrial amplitude-modulation amplitude |
| `a_amp_freq` | 0.09 | Atrial amplitude-modulation frequency (Hz) |
| `bw_amp` | 0.0 | Baseline wander amplitude (mL) |
| `bw_freq` | 0.03 | Baseline wander frequency (Hz) |
| `s_frac_base` | 0.35 | Base systole fraction (0–1) |
| `lv_kick_amp_frac` | 0.07 | LV atrial kick amplitude fraction |
| `lv_kick_center` | 0.92 | LV atrial kick centre (phase, 0–1) |
| `lv_kick_width` | 0.04 | LV atrial kick width (phase, 0–1) |
| `rv_kick_amp_frac` | 0.06 | RV atrial kick amplitude fraction |
| `rv_kick_center` | 0.92 | RV atrial kick centre |
| `rv_kick_width` | 0.05 | RV atrial kick width |
| `la_contr_amp_frac` | 0.15 | LA contraction amplitude fraction |
| `la_contr_center` | 0.95 | LA contraction centre |
| `la_contr_width` | 0.03 | LA contraction width |
| `ra_contr_amp_frac` | 0.12 | RA contraction amplitude fraction |
| `ra_contr_center` | 0.95 | RA contraction centre |
| `ra_contr_width` | 0.03 | RA contraction width |

#### `ti = lib.tissueIntensitiesDefault()`

Returns a struct for the torso phantom with the following fields:

| Field | Default | Tissue |
|---|---|---|
| `lung` | 0.08 | Lung |
| `heart` | 0.65 | Heart muscle |
| `vessels_blood` | 1.0 | Blood in vessels |
| `bones` | 0.85 | Bone |
| `liver` | 0.55 | Liver |
| `stomach` | 0.9 | Stomach |
| `body` | 0.25 | General body tissue |
| `lv_blood` | 0.98 | LV blood pool |
| `rv_blood` | 0.99 | RV blood pool |
| `la_blood` | 0.97 | LA blood pool |
| `ra_blood` | 0.96 | RA blood pool |

#### `tg = lib.tubesGeometryDefault()`

Returns a struct for the tubes phantom geometry:

| Field | Default | Description |
|---|---|---|
| `outer_radius` | 0.4 | Outer cylinder radius (fraction of FOV) |
| `outer_height` | 0.8 | Outer cylinder height (fraction of FOV) |
| `tubes_height_fraction` | 0.9 | Tube height relative to outer cylinder |
| `tube_wall_thickness` | 0.025 | Tube wall thickness (fraction of FOV) |
| `gap_fraction` | 0.3 | Gap fraction between adjacent tubes |

#### `ti = lib.tubesIntensitiesDefault()`

Returns a struct with fields:

| Field | Default | Description |
|---|---|---|
| `outer_cylinder` | 0.25 | Intensity of the surrounding cylinder |
| `tube_wall` | 0.0 | Intensity of tube walls |
| `tube_fillings` | `[0.1 0.3 0.5 0.7 0.9 1.0]` | Row-vector of per-tube fill intensities |

#### `ti = lib.sheppLoganCtDefault()`

Returns a `SheppLoganIntensities` struct with the original Shepp & Logan (1974)
CT intensity increments for the 12 ellipsoids:
`skull`, `brain`, `right_big`, `left_big`, `top`, `middle_high`,
`bottom_left`, `middle_low`, `bottom_center`, `bottom_right`, `extra_1`, `extra_2`.

#### `ti = lib.sheppLoganMriDefault()`

Same struct layout as `sheppLoganCtDefault()`, but with Toft's MRI-adapted
intensity increments.

---

### Signal generation

#### `[t, signal] = lib.generateRespiratorySignal(duration, fs, rr)`
#### `[t, signal] = lib.generateRespiratorySignal(duration, fs, rr, phys)`

Generates a synthetic respiratory signal.

| Argument | Type | Description |
|---|---|---|
| `duration` | `double` | Total duration (s) |
| `fs` | `double` | Sampling frequency (Hz) |
| `rr` | `double` | Respiratory rate (breaths/min) |
| `phys` | struct (optional) | From `respiratoryPhysiologyDefault()` |

Returns:
- `t` — time vector (s), `1 × n double`
- `signal` — lung volume (L), `1 × n double`

#### `[t, lv, rv, la, ra] = lib.generateCardiacSignals(duration, fs, hr)`
#### `[t, lv, rv, la, ra] = lib.generateCardiacSignals(duration, fs, hr, phys)`

Generates cardiac chamber volume signals.

| Argument | Type | Description |
|---|---|---|
| `duration` | `double` | Total duration (s) |
| `fs` | `double` | Sampling frequency (Hz) |
| `hr` | `double` | Heart rate (beats/min) |
| `phys` | struct (optional) | From `cardiacPhysiologyDefault()` |

Returns `1 × n double` vectors:
- `t` — time (s)
- `lv` — left ventricle volume (mL)
- `rv` — right ventricle volume (mL)
- `la` — left atrium volume (mL)
- `ra` — right atrium volume (mL)

---

### Shepp-Logan phantom

#### `phantom = lib.createSheppLoganPhantom3D(nx, ny, nz)`
#### `phantom = lib.createSheppLoganPhantom3D(nx, ny, nz, ti)`

Creates a 3-D Shepp-Logan phantom.  Returns a `single` array of size `nx × ny × nz`
in column-major order.  `ti` defaults to `sheppLoganCtDefault()`.

#### `slice = lib.createSheppLoganPhantom2D(nx, ny)`
#### `slice = lib.createSheppLoganPhantom2D(nx, ny, axis, slice_pos, ti)`

Creates a 2-D Shepp-Logan slice.  Returns a `single` array of size `nx × ny`.

| Argument | Default | Description |
|---|---|---|
| `axis` | `AXIS_AXIAL` | Slice orientation (see axis constants) |
| `slice_pos` | `0.0` | Slice position along the perpendicular axis (cm) |
| `ti` | CT defaults | Intensity parameters |

---

### Tubes phantom

#### `phantom = lib.createTubesPhantom3D(nx, ny, nz)`
#### `phantom = lib.createTubesPhantom3D(nx, ny, nz, tg, ti)`

Creates a 3-D tubes phantom.  Returns a `single` array of size `nx × ny × nz`.
`tg` defaults to `tubesGeometryDefault()`, `ti` to `tubesIntensitiesDefault()`.

#### `slice = lib.createTubesPhantom2D(nx, ny)`
#### `slice = lib.createTubesPhantom2D(nx, ny, axis, slice_pos, tg, ti)`

Creates a 2-D tubes phantom slice.  Returns a `single` array of size `nx × ny`.
Argument defaults are the same as the 3-D version.

---

### Torso phantom

#### `phantom = lib.createTorsoPhantom3D(nx, ny, nz, Name, Value, ...)`

Creates a 3-D (static) or 4-D (dynamic) torso phantom.

| Name–value pair | Default | Description |
|---|---|---|
| `'tissue'` | `tissueIntensitiesDefault()` | Tissue intensities struct |
| `'resp_signal'` | `[]` | Respiratory signal vector (L); sets number of frames |
| `'cardiac_lv'` | `[]` | LV volume signal (mL) |
| `'cardiac_rv'` | `[]` | RV volume signal (mL) |
| `'cardiac_la'` | `[]` | LA volume signal (mL) |
| `'cardiac_ra'` | `[]` | RA volume signal (mL) |

Returns a `single` array:
- `nx × ny × nz` for a static phantom (no signals provided)
- `nx × ny × nz × n_frames` for a dynamic phantom

#### `phantom = lib.createTorsoPhantom2D(nx, ny, axis, slice_pos, Name, Value, ...)`

Creates a 2-D torso slice, optionally with time.  `axis` defaults to
`AXIS_AXIAL`, `slice_pos` to `0.0`.  Name–value pairs are the same as the 3-D
version.  Returns a `single` array:
- `nx × ny` for a static slice
- `nx × ny × n_frames` for a dynamic slice
