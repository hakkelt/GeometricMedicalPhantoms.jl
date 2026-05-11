# C / C++ Usage

GeometricMedicalPhantoms ships a pre-compiled shared library (`libgeomphantoms`) with a
plain-C API that can be called from C, C++, Fortran, or any other language that supports
the platform ABI.  The library is built with [JuliaC.jl](https://github.com/JuliaLang/JuliaC.jl)
and bundles all required Julia runtime dependencies.

## Downloading the library

Pre-built bundles are attached to every
[GitHub release](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases):

| Platform | Archive |
|---|---|
| Linux x86-64  | `geomphantoms-lib-linux-x86_64.tar.xz` |
| Linux aarch64 | `geomphantoms-lib-linux-aarch64.tar.xz` |
| macOS x86-64  | `geomphantoms-lib-macos-x86_64.tar.xz` |
| macOS arm64   | `geomphantoms-lib-macos-aarch64.tar.xz` |
| Windows x86-64| `geomphantoms-lib-windows-x86_64.zip` |

Extract the archive; the top-level layout is:

```
build/
  lib/
    libgeomphantoms.so   # (or .dylib / .dll)
    julia/               # bundled Julia stdlibs
include/
  geometric_medical_phantoms.h
python/
  geometric_medical_phantoms.py
matlab/
  GeometricMedicalPhantoms.m
```

## Building from source

Requires Julia 1.12+ and a C compiler on `PATH`.  From the repository root:

```sh
# Install JuliaC once
julia -e 'using Pkg; Pkg.add("JuliaC")'

# Instantiate the lib sub-project (workspace resolves the path dependency)
julia --project=lib -e 'using Pkg; Pkg.instantiate()'

# Build
julia --project=lib lib/build.jl
```

The library and all Julia runtime deps will be placed under `lib/build/`.

## Including the header

```c
#include "geometric_medical_phantoms.h"
```

In C++ the header wraps all declarations in `extern "C"` automatically.

## Linking

### Linux / macOS

```sh
# Link at compile time
cc -I path/to/include \
   my_program.c \
   -L path/to/build/lib \
   -lgeomphantoms \
   -Wl,-rpath,'$ORIGIN/path/to/build/lib' \
   -o my_program
```

### Windows (MSVC)

JuliaC produces a `geomphantoms.dll` and a matching `geomphantoms.lib` import library.

```bat
cl my_program.c /I path\to\include ^
   /link /LIBPATH:path\to\build\lib geomphantoms.lib
```

Make sure `path\to\build\lib` is on `PATH` at runtime.

## Data layout

All phantom arrays use **column-major (Fortran/Julia) memory order**:

| Phantom type | Buffer size | Index formula (0-based) |
|---|---|---|
| 3-D | `nx × ny × nz` floats | `x + nx*(y + ny*z)` |
| 3-D+time | `nx × ny × nz × nt` floats | `x + nx*(y + ny*(z + nz*t))` |
| 2-D | `nx × ny` floats | `x + nx*y` |
| 2-D+time | `nx × ny × nt` floats | `x + nx*(y + ny*t)` |

The caller allocates all output buffers.  Use [`gmp_signal_length`](#utility) to
pre-size signal buffers.

## Axis constants

```c
#define GMP_AXIS_AXIAL    0   // x/y plane, slice along z
#define GMP_AXIS_CORONAL  1   // x/z plane, slice along y
#define GMP_AXIS_SAGITTAL 2   // y/z plane, slice along x
```

## Error codes

All phantom and signal functions return `int`:

| Code | Meaning |
|---|---|
| `0` | Success |
| `-1` | General error (exception inside Julia) |
| `-2` | Invalid `axis` value |

## Complete C example

```c
#include <stdio.h>
#include <stdlib.h>
#include "geometric_medical_phantoms.h"

int main(void)
{
    printf("Library: %s\n", gmp_version());

    /* ---- Shepp-Logan 3-D phantom ----------------------------------- */
    const int nx = 128, ny = 128, nz = 128;
    float *phantom = malloc(nx * ny * nz * sizeof(float));

    GmpSheppLoganIntensities ti;
    gmp_shepp_logan_ct_default(&ti);

    int ret = gmp_create_shepp_logan_phantom_3d(nx, ny, nz, &ti, phantom);
    if (ret != 0) { fprintf(stderr, "error %d\n", ret); return 1; }

    printf("Centre voxel: %f\n", (double)phantom[nx/2 + nx*(ny/2 + ny*(nz/2))]);
    free(phantom);

    /* ---- Respiratory signal ---------------------------------------- */
    double duration = 60.0, fs = 50.0, rr = 15.0;
    int n = gmp_signal_length(duration, fs);

    double *t   = malloc(n * sizeof(double));
    double *sig = malloc(n * sizeof(double));

    GmpRespiratoryPhysiology phys;
    gmp_respiratory_physiology_default(&phys);
    phys.rr_var_amp = 0.05;   /* increase rate variability */

    ret = gmp_generate_respiratory_signal(duration, fs, rr, &phys, t, sig, n);
    if (ret != 0) { fprintf(stderr, "signal error %d\n", ret); return 1; }

    printf("Signal range: [%.3f, %.3f] L\n",
           sig[0], sig[n - 1]);   /* first and last sample */
    free(t); free(sig);

    /* ---- Torso phantom with respiratory motion --------------------- */
    const int nx2 = 64, ny2 = 64, nz2 = 64, nframes = 50;

    /* Generate signal first */
    double *resp = malloc(nframes * sizeof(double));
    double *t2   = malloc(nframes * sizeof(double));
    GmpRespiratoryPhysiology phys2;
    gmp_respiratory_physiology_default(&phys2);
    /* Reuse only first nframes samples */
    double *full_sig = malloc(n * sizeof(double));
    double *full_t   = malloc(n * sizeof(double));
    gmp_generate_respiratory_signal(duration, fs, rr, &phys2, full_t, full_sig, n);
    for (int i = 0; i < nframes; i++) resp[i] = full_sig[i];
    free(full_sig); free(full_t);

    float *torso = malloc((size_t)nx2 * ny2 * nz2 * nframes * sizeof(float));
    GmpTissueIntensities tti;
    gmp_tissue_intensities_default(&tti);

    ret = gmp_create_torso_phantom_3d(
        nx2, ny2, nz2, nframes,
        resp, NULL, NULL, NULL, NULL,   /* resp only, no cardiac */
        &tti, torso);
    if (ret != 0) { fprintf(stderr, "torso error %d\n", ret); return 1; }

    printf("Torso 4-D: first voxel frame 0 = %f, frame 1 = %f\n",
           (double)torso[0],
           (double)torso[nx2 * ny2 * nz2]);   /* offset by one full volume */

    free(resp); free(t2); free(torso);
    return 0;
}
```

## C++ example

The header is C++-compatible (`extern "C"` is applied automatically).  You can
wrap the raw API in a convenient RAII class:

```cpp
#include <vector>
#include <stdexcept>
#include "geometric_medical_phantoms.h"

class SheppLoganPhantom3D {
public:
    SheppLoganPhantom3D(int nx, int ny, int nz,
                        GmpSheppLoganIntensities ti = defaultCT())
        : nx_(nx), ny_(ny), nz_(nz),
          data_(static_cast<std::size_t>(nx) * ny * nz)
    {
        int ret = gmp_create_shepp_logan_phantom_3d(nx, ny, nz, &ti, data_.data());
        if (ret != 0)
            throw std::runtime_error("gmp_create_shepp_logan_phantom_3d failed: "
                                     + std::to_string(ret));
    }

    float operator()(int x, int y, int z) const {
        return data_[x + nx_ * (y + ny_ * z)];
    }

    static GmpSheppLoganIntensities defaultCT() {
        GmpSheppLoganIntensities ti;
        gmp_shepp_logan_ct_default(&ti);
        return ti;
    }

private:
    int nx_, ny_, nz_;
    std::vector<float> data_;
};
```

## Customising parameters

Every function that takes a parameter struct accepts the caller's values directly.
Use the `gmp_*_default()` helpers to get a filled-in struct, then override individual
fields:

```c
GmpRespiratoryPhysiology phys;
gmp_respiratory_physiology_default(&phys);

/* Override: wider breathing range, faster modulation */
phys.minL         = 2.0;
phys.maxL         = 3.5;
phys.amp_mod_freq = 0.1;

double *t = ..., *sig = ...;
gmp_generate_respiratory_signal(60.0, 50.0, 15.0, &phys, t, sig, n);
```

For `GmpTubesIntensities`, the `tube_fillings` pointer must remain valid for
the duration of the call.  Use the stack-allocated pattern shown in the smoke
test (`lib/test/smoke_test.c`) as a reference.

## API reference

### Structs

---

#### `GmpRespiratoryPhysiology`

```c
typedef struct {
    double min_l;        // Minimum lung volume (L)          default: 2.4
    double max_l;        // Maximum lung volume (L)          default: 3.0
    double asym_amp;     // Asymmetry harmonic amplitude     default: 0.2
    double amp_mod_amp;  // Amplitude modulation amplitude   default: 0.15
    double amp_mod_freq; // Amplitude modulation freq (Hz)   default: 0.05
    double rr_var_amp;   // RR variability amplitude         default: 0.03
    double rr_var_freq;  // RR variability frequency (Hz)    default: 0.03
} GmpRespiratoryPhysiology;
```

---

#### `GmpCardiacPhysiology`

```c
typedef struct {
    double lv_edv;          // LV end-diastolic volume (mL)  default: 130
    double lv_esv;          // LV end-systolic volume (mL)   default: 55
    double rv_edv;          // RV end-diastolic volume (mL)  default: 140
    double rv_esv;          // RV end-systolic volume (mL)   default: 65
    double la_min;          // LA minimum volume (mL)        default: 30
    double la_max;          // LA maximum volume (mL)        default: 60
    double ra_min;          // RA minimum volume (mL)        default: 30
    double ra_max;          // RA maximum volume (mL)        default: 60
    double hr_var_amp;      // HR variability amplitude      default: 0.0
    double hr_var_freq;     // HR variability freq (Hz)      default: 0.1
    double v_amp_amp;       // Ventr. amp-mod amplitude      default: 0.0
    double v_amp_freq;      // Ventr. amp-mod freq (Hz)      default: 0.08
    double a_amp_amp;       // Atrial amp-mod amplitude      default: 0.02
    double a_amp_freq;      // Atrial amp-mod freq (Hz)      default: 0.09
    double bw_amp;          // Baseline wander amplitude     default: 0.0
    double bw_freq;         // Baseline wander freq (Hz)     default: 0.03
    double s_frac_base;     // Systole fraction base (0–1)   default: 0.35
    double lv_kick_amp_frac;// LV atrial kick amplitude      default: 0.07
    double lv_kick_center;  // LV atrial kick centre (0–1)   default: 0.92
    double lv_kick_width;   // LV atrial kick width (0–1)    default: 0.04
    double rv_kick_amp_frac;// RV atrial kick amplitude      default: 0.06
    double rv_kick_center;  // RV atrial kick centre         default: 0.92
    double rv_kick_width;   // RV atrial kick width          default: 0.05
    double la_contr_amp_frac;//LA contraction amplitude      default: 0.15
    double la_contr_center; // LA contraction centre         default: 0.95
    double la_contr_width;  // LA contraction width          default: 0.03
    double ra_contr_amp_frac;//RA contraction amplitude      default: 0.12
    double ra_contr_center; // RA contraction centre         default: 0.95
    double ra_contr_width;  // RA contraction width          default: 0.03
} GmpCardiacPhysiology;
```

---

#### `GmpTissueIntensities`

```c
typedef struct {
    double lung;          // Lung                default: 0.08
    double heart;         // Heart muscle        default: 0.65
    double vessels_blood; // Blood in vessels    default: 1.0
    double bones;         // Bone                default: 0.85
    double liver;         // Liver               default: 0.55
    double stomach;       // Stomach             default: 0.9
    double body;          // Body tissue         default: 0.25
    double lv_blood;      // LV blood pool       default: 0.98
    double rv_blood;      // RV blood pool       default: 0.99
    double la_blood;      // LA blood pool       default: 0.97
    double ra_blood;      // RA blood pool       default: 0.96
} GmpTissueIntensities;
```

---

#### `GmpTubesGeometry`

```c
typedef struct {
    double outer_radius;           // Outer cylinder radius (FOV fraction) default: 0.4
    double outer_height;           // Outer cylinder height (FOV fraction) default: 0.8
    double tubes_height_fraction;  // Tube height / outer height            default: 0.9
    double tube_wall_thickness;    // Wall thickness (FOV fraction)         default: 0.025
    double gap_fraction;           // Gap between tubes (fraction)          default: 0.3
} GmpTubesGeometry;
```

---

#### `GmpTubesIntensities`

```c
typedef struct {
    double  outer_cylinder; // Surrounding cylinder intensity  default: 0.25
    double  tube_wall;      // Tube wall intensity             default: 0.0
    double *tube_fillings;  // Per-tube fill intensities (pointer, caller-owned)
    int     n_tubes;        // Length of tube_fillings array   default: 6
} GmpTubesIntensities;
```

!!! warning "Pointer ownership"
    `tube_fillings` must point to a valid `double` array for the duration of any
    function call that accepts `GmpTubesIntensities`.  The library does not free
    or retain this pointer after the call returns.

---

#### `GmpSheppLoganIntensities`

```c
typedef struct {
    double skull;         // Outer skull boundary  CT:  2.0   MRI: 0.0
    double brain;         // Brain interior        CT: -0.98  MRI: 1.0
    double right_big;     // Large right ellipsoid CT: -0.02  MRI: -0.8
    double left_big;      // Large left ellipsoid  CT: -0.02  MRI: -0.8
    double top;           // Top ellipsoid         CT:  0.01  MRI: 0.4
    double middle_high;   // Upper-middle          CT:  0.01  MRI: 0.2
    double bottom_left;   // Lower-left            CT: -0.01  MRI: -0.2
    double middle_low;    // Lower-middle          CT:  0.01  MRI: 0.2
    double bottom_center; // Bottom-centre         CT:  0.01  MRI: 0.2
    double bottom_right;  // Bottom-right          CT:  0.01  MRI: 0.2
    double extra_1;       // Extra ellipsoid 1     CT: -0.02  MRI: 0.0
    double extra_2;       // Extra ellipsoid 2     CT: -0.02  MRI: 0.0
} GmpSheppLoganIntensities;
```

---

### Utility functions

```c
void        gmp_init(void);
void        gmp_cleanup(void);
const char *gmp_version(void);
int         gmp_signal_length(double duration, double fs);
```

| Function | Description |
|---|---|
| `gmp_init()` | Initialize the Julia runtime.  Called automatically; safe to call multiple times. |
| `gmp_cleanup()` | Shut down the Julia runtime.  Call once at program exit (optional). |
| `gmp_version()` | Returns a null-terminated string with the package version, e.g. `"1.0.2"`. |
| `gmp_signal_length(duration, fs)` | Returns `round(duration × fs)` — the number of samples for a signal. |

---

### Default-value functions

Each function fills a caller-provided struct with default values.

```c
void gmp_respiratory_physiology_default(GmpRespiratoryPhysiology *out);
void gmp_cardiac_physiology_default    (GmpCardiacPhysiology     *out);
void gmp_tissue_intensities_default    (GmpTissueIntensities     *out);
void gmp_tubes_geometry_default        (GmpTubesGeometry         *out);
void gmp_tubes_intensities_default     (GmpTubesIntensities      *out,
                                        double                   *fillings_out,
                                        int                       n_tubes);
void gmp_shepp_logan_ct_default        (GmpSheppLoganIntensities *out);
void gmp_shepp_logan_mri_default       (GmpSheppLoganIntensities *out);
```

For `gmp_tubes_intensities_default`, `fillings_out` must point to an array of
at least `n_tubes` doubles.  The function sets `out->tube_fillings = fillings_out`
and writes `n_tubes` evenly-spaced intensities into it.

---

### Signal generation

```c
int gmp_generate_respiratory_signal(
    double                         duration,
    double                         fs,
    double                         rr,
    const GmpRespiratoryPhysiology *phys,
    double                         *t_out,
    double                         *signal_out,
    int                             n);
```

| Parameter | Description |
|---|---|
| `duration` | Signal duration (s) |
| `fs` | Sampling frequency (Hz) |
| `rr` | Respiratory rate (breaths/min) |
| `phys` | Physiology parameters; pass `NULL` to use defaults |
| `t_out` | Output time vector; caller-allocated, length `n` |
| `signal_out` | Output lung-volume signal (L); caller-allocated, length `n` |
| `n` | Buffer length; should equal `gmp_signal_length(duration, fs)` |

Returns `0` on success, `−1` on error.

---

```c
int gmp_generate_cardiac_signals(
    double                     duration,
    double                     fs,
    double                     hr,
    const GmpCardiacPhysiology *phys,
    double                     *t_out,
    double                     *lv_out,
    double                     *rv_out,
    double                     *la_out,
    double                     *ra_out,
    int                         n);
```

| Parameter | Description |
|---|---|
| `duration` | Signal duration (s) |
| `fs` | Sampling frequency (Hz) |
| `hr` | Heart rate (beats/min) |
| `phys` | Physiology parameters; pass `NULL` to use defaults |
| `t_out` | Output time vector |
| `lv_out` | LV volume signal (mL) |
| `rv_out` | RV volume signal (mL) |
| `la_out` | LA volume signal (mL) |
| `ra_out` | RA volume signal (mL) |
| `n` | Buffer length |

Returns `0` on success, `−1` on error.

---

### Shepp-Logan phantom

```c
int gmp_create_shepp_logan_phantom_3d(
    int                             nx, int ny, int nz,
    const GmpSheppLoganIntensities *intensities,
    float                          *out);

int gmp_create_shepp_logan_phantom_2d(
    int                             nx, int ny,
    int                             axis,
    double                          slice_position,
    const GmpSheppLoganIntensities *intensities,
    float                          *out);
```

`out` must point to `nx × ny × nz` (or `nx × ny`) `float` values in
column-major order.  `intensities` may be `NULL` to use CT defaults.
Returns `0` on success.

---

### Tubes phantom

```c
int gmp_create_tubes_phantom_3d(
    int                        nx, int ny, int nz,
    const GmpTubesGeometry    *geometry,
    const GmpTubesIntensities *intensities,
    float                     *out);

int gmp_create_tubes_phantom_2d(
    int                        nx, int ny,
    int                        axis,
    double                     slice_position,
    const GmpTubesGeometry    *geometry,
    const GmpTubesIntensities *intensities,
    float                     *out);
```

`geometry` and `intensities` may be `NULL` to use defaults.
Returns `0` on success.

---

### Torso phantom

```c
int gmp_create_torso_phantom_3d(
    int                       nx, int ny, int nz,
    int                       n_frames,
    const double             *resp_signal,    // length n_frames; NULL for static
    const double             *cardiac_lv,    // length n_frames; NULL to omit
    const double             *cardiac_rv,    // length n_frames; NULL to omit
    const double             *cardiac_la,    // length n_frames; NULL to omit
    const double             *cardiac_ra,    // length n_frames; NULL to omit
    const GmpTissueIntensities *tissue,      // NULL to use defaults
    float                    *out);          // nx × ny × nz × n_frames floats

int gmp_create_torso_phantom_2d(
    int                       nx, int ny,
    int                       axis,
    double                    slice_position,
    int                       n_frames,
    const double             *resp_signal,
    const double             *cardiac_lv,
    const double             *cardiac_rv,
    const double             *cardiac_la,
    const double             *cardiac_ra,
    const GmpTissueIntensities *tissue,
    float                    *out);          // nx × ny × n_frames floats
```

When `n_frames == 1` and all signal pointers are `NULL`, a static phantom is
produced.  Returns `0` on success, `−1` on error.
