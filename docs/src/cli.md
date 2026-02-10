# CLI

GeometricMedicalPhantoms includes a command-line interface for generating phantoms and signals without writing Julia code. While the preferred method is to use the package within Julia programs for maximum flexibility, the CLI provides a convenient way to generate phantoms quickly.

## Installation

### Download Pre-built Binary (Recommended for CLI Usage)

Download the latest release for your platform from the [Releases page](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases):

- **Linux**: `geomphantoms-linux-x64.zip`
- **macOS**: `geomphantoms-macos-x64.zip`
- **Windows**: `geomphantoms-windows-x64.zip`

Extract and run directly:

```bash
# Linux/macOS
./geomphantoms info

# Windows
geomphantoms.exe info
```

## Building from Source (Requires Julia 1.12+)

The CLI is shipped as a separate app in `app/` to avoid adding dependencies to the core package. To build it yourself, install [JuliaC.jl](https://github.com/JuliaLang/JuliaC.jl) Julia app and run:

```bash
julia --project=./app -e 'using Pkg; Pkg.instantiate()'
juliac --output-exe geomphantoms --project=./app --bundle app/build --trim=safe app/src/app.jl
```

The executable will be in `app/build/bin/geomphantoms`.

## Basic Usage

```bash
geomphantoms info
geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy
```

## Phantom Generation

```bash
# 2D Shepp-Logan slice
geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy

# 3D Torso volume
geomphantoms phantom torso --size 128,128,128 --out torso.mat

# Tubes with custom intensities
geomphantoms phantom tubes --size 256,256,256 \
  --intensity '{"outer_cylinder":0.3,"tube_fillings":[0.2,0.4,0.6,0.8,1.0]}' \
  --out tubes.npy
```

## Output Formats

Supported outputs:

- `npy`
- `mat`
- `cfl/hdr` (BART): use a base path without extension, e.g. `--out ./phantom`
- `nifti` (`.nii` or `.nii.gz`)
- `png` (2D only)

If `--format` is omitted, it is inferred from the `--out` extension. For BART output, always pass the base path and set `--format cfl`.

## Signals

```bash
# Respiratory signal
geomphantoms signals respiratory --duration 10 --fs 24 --rate 12 --out resp.csv

# Cardiac signal
geomphantoms signals cardiac --duration 10 --fs 100 --rate 70 --out cardiac.json
```

## Metadata

By default, a JSON sidecar is written to `<out>.json`. Disable it with `--no-meta` or specify a custom path with `--meta`.

## Advanced Usage

For complete documentation and examples, see the [CLI README](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/tree/master/app).

To use the package programmatically with full Julia API access:

```julia
using GeometricMedicalPhantoms

# Full control over phantom parameters
phantom = create_shepp_logan_phantom(
    256, 256, :axial;
    slice_position = 0.5,
    ti = MRISheppLoganIntensities()
)

# Advanced features not available in CLI
phantom_series = [create_torso_phantom(128, 128, 64; respiratory_signal=sig[t]) for t in 1:100]
```

---

## API Reference

This section provides a complete reference for all CLI commands, arguments, and options.

### Global Commands

#### `info`

Display version and system information.

```bash
geomphantoms info
```

**Output:**
- Package version
- Julia version

**Exit Code:** 0

---

### `phantom` Command

Generate phantom images.

```bash
geomphantoms phantom <type> --size <dimensions> --out <path> [options]
```

#### Phantom Types

- **`shepp-logan`** - Classic Shepp-Logan head phantom for testing imaging algorithms
- **`torso`** - Anatomical torso phantom with heart, lungs, liver, kidneys, and spine
- **`tubes`** - Cylindrical tubes phantom for resolution testing

#### Required Arguments

| Argument | Description | Format |
|----------|-------------|--------|
| `<type>` | Phantom type | One of: `shepp-logan`, `torso`, `tubes` |
| `--size` | Voxel dimensions | Comma-separated integers: `nx,ny` (2D) or `nx,ny,nz` (3D) |
| `--out` | Output file path | File path with extension |

#### Optional Arguments

| Option | Description | Type | Default | Notes |
|--------|-------------|------|---------|-------|
| `--plane` | Slice plane for 2D output | String | Required for 2D | One of: `axial`, `coronal`, `sagittal` |
| `--slice-position` | Slice position in cm | Float | `0.0` | Position along the slice axis |
| `--format` | Output format | String | Inferred from extension | One of: `npy`, `mat`, `cfl`, `nifti`, `png`, `tiff` |
| `--meta` | Metadata JSON path | String | `<out>.json` | Custom location for metadata |
| `--no-meta` | Disable metadata output | Flag | `false` | Skips JSON sidecar creation |
| `--intensity` | Intensity specification | String/JSON | Default preset | See [Intensity Specification](#intensity-specification) |
| `--mask` | Mask specification | String/JSON | No masking | See [Mask Specification](#mask-specification) |
| `--geometry` | Geometry specification | String/JSON | Default geometry | See [Geometry Specification](#geometry-specification) |
| `--stack` | Stack of intensity sets | String/JSON | Single intensity | See [Stack Specification](#stack-specification) |
| `--resp-signal` | Respiratory signal file | File path | No motion | CSV, JSON, or NPY file |
| `--cardiac-signal` | Cardiac volumes file | File path | No motion | CSV or JSON file |

#### Output Formats

| Format | Extension | Dimensions | Description |
|--------|-----------|------------|-------------|
| `npy` | `.npy` | 2D, 3D, 4D | NumPy format (default) |
| `mat` | `.mat` | 2D, 3D, 4D | MATLAB format |
| `cfl`/`hdr` | `.cfl` + `.hdr` | 2D, 3D, 4D | BART format (use base path without extension) |
| `nifti` | `.nii`, `.nii.gz` | 2D, 3D, 4D | NIfTI format (compressed supported) |
| `png` | `.png` | 2D only | PNG image (auto-scaled to 8-bit) |
| `tiff` | `.tif`, `.tiff` | 2D, 3D, 4D | TIFF format (multi-page for 3D/4D) |

**Format Inference:** If `--format` is omitted, the format is inferred from the `--out` extension.

**BART Format Special Case:** For BART output, provide the base path without extension:
```bash
geomphantoms phantom torso --size 128,128,128 --format cfl --out ./phantom
# Creates: ./phantom.cfl and ./phantom.hdr
```

#### Intensity Specification

The `--intensity` option controls tissue intensities. It accepts:

1. **Preset names** (case-insensitive):
   - `ct`, `mri`, `default` (for Shepp-Logan)
   - Presets vary by phantom type

2. **JSON string**:
   ```bash
   --intensity '{"outer_cylinder":0.3,"tube_fillings":[0.2,0.4,0.6,0.8,1.0]}'
   ```

3. **JSON file path**:
   ```bash
   --intensity /path/to/intensity.json
   ```

**Format:** JSON object with phantom-specific keys. See phantom-specific documentation for available keys.

#### Mask Specification

The `--mask` option applies masking to the phantom. It accepts:

1. **JSON string**:
   ```bash
   --mask '{"lv":true,"rv":false}'
   ```

2. **JSON file path**:
   ```bash
   --mask /path/to/mask.json
   ```

**Format:** JSON object with boolean values for each phantom component.

#### Geometry Specification

The `--geometry` option (tubes phantom only) customizes geometric parameters:

1. **JSON string**:
   ```bash
   --geometry '{"outer_radius":10.0,"tube_radius":1.5}'
   ```

2. **JSON file path**:
   ```bash
   --geometry /path/to/geometry.json
   ```

**Format:** JSON object with geometry parameters specific to the phantom type.

#### Stack Specification

The `--stack` option (tubes phantom only) provides a stack of intensity sets:

1. **JSON array string**:
   ```bash
   --stack '[{"outer_cylinder":0.3},{"outer_cylinder":0.5}]'
   ```

2. **JSON file path**:
   ```bash
   --stack /path/to/stack.json
   ```

**Format:** JSON array of intensity objects.

#### Signal File Formats

**Respiratory Signal:**
- **CSV**: Single column of signal values (optional header)
- **JSON**: `{"signal": [values]}` or `{"t": [times], "signal": [values]}`
- **NPY**: 1D NumPy array

**Cardiac Signal:**
- **CSV**: Four columns (lv, rv, la, ra) with optional header
- **JSON**: `{"lv": [values], "rv": [values], "la": [values], "ra": [values]}`

**Important:** Respiratory and cardiac signals must have the same length when both are provided.

---

### `signals` Command

Generate physiological signals (respiratory or cardiac).

```bash
geomphantoms signals <type> --out <path> [options]
```

#### Signal Types

- **`respiratory`** - Respiratory motion signal
- **`cardiac`** - Cardiac volumetric signals (LV, RV, LA, RA)

#### Required Arguments

| Argument | Description | Format |
|----------|-------------|--------|
| `<type>` | Signal type | One of: `respiratory`, `cardiac` |
| `--out` | Output file path | File path with extension |

#### Optional Arguments

| Option | Description | Type | Default | Notes |
|--------|-------------|------|---------|-------|
| `--duration` | Duration in seconds | Float | `10.0` | Total signal length |
| `--fs` | Sampling frequency in Hz | Float | `24.0` | Samples per second |
| `--rate` | Physiological rate | Float | `15.0` (resp) / `70.0` (cardiac) | Breaths/min or beats/min |
| `--physiology` | Physiology parameters | String/JSON | Default physiology | See [Physiology Specification](#physiology-specification) |
| `--format` | Output format | String | Inferred from extension | One of: `csv`, `json`, `npy` |

#### Signal Output Formats

| Format | Extension | Content |
|--------|-----------|---------|
| `csv` | `.csv` | Time series with headers |
| `json` | `.json` | JSON object with named fields |
| `npy` | `.npy` | NumPy array (respiratory only) |

**Respiratory CSV Output:**
```csv
t,signal
0.0,0.0
0.041667,0.123
...
```

**Cardiac CSV Output:**
```csv
lv,rv,la,ra
85.0,70.0,55.0,45.0
87.3,71.2,56.1,46.0
...
```

**Respiratory JSON Output:**
```json
{
  "t": [0.0, 0.041667, ...],
  "signal": [0.0, 0.123, ...]
}
```

**Cardiac JSON Output:**
```json
{
  "t": [0.0, 0.01, ...],
  "lv": [85.0, 87.3, ...],
  "rv": [70.0, 71.2, ...],
  "la": [55.0, 56.1, ...],
  "ra": [45.0, 46.0, ...]
}
```

#### Physiology Specification

The `--physiology` option customizes physiological parameters:

1. **JSON string**:
   ```bash
   --physiology '{"amplitude":1.5,"baseline":0.0}'
   ```

2. **JSON file path**:
   ```bash
   --physiology /path/to/physiology.json
   ```

**Respiratory Physiology Keys:**
- `amplitude` - Signal amplitude
- `baseline` - Baseline offset
- Additional model-specific parameters

**Cardiac Physiology Keys:**
- `lv_systolic`, `lv_diastolic` - Left ventricle volumes
- `rv_systolic`, `rv_diastolic` - Right ventricle volumes
- `la_systolic`, `la_diastolic` - Left atrium volumes
- `ra_systolic`, `ra_diastolic` - Right atrium volumes
- Additional timing parameters

---

### Metadata JSON Format

When metadata is enabled (default), a JSON sidecar file is created with the following structure:

```json
{
  "command": "phantom",
  "type": "torso",
  "size": [128, 128, 128],
  "plane": null,
  "slice_position": 0.0,
  "format": "nifti",
  "output": "/path/to/output.nii.gz",
  "timestamp": "2026-02-10T15:30:45.123",
  "package_version": "1.0.0",
  "julia_version": "1.12.4"
}
```

**Fields:**
- `command` - CLI command used (`phantom` or `signals`)
- `type` - Phantom or signal type
- `size` - Array dimensions (phantom command only)
- `plane` - Slice plane (`null` for 3D)
- `slice_position` - Slice position in cm
- `format` - Output format
- `output` - Output file path
- `timestamp` - ISO 8601 timestamp
- `package_version` - GeometricMedicalPhantoms version
- `julia_version` - Julia version used

---

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Error (invalid arguments, unsupported format, file I/O error, etc.) |

---

### Examples

#### Basic Phantom Generation

```bash
# 2D axial Shepp-Logan (256×256)
geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy

# 3D torso (128×128×128)
geomphantoms phantom torso --size 128,128,128 --out torso.mat

# Coronal slice of tubes
geomphantoms phantom tubes --size 256,256 --plane coronal --out tubes.png
```

#### Custom Intensities

```bash
# Shepp-Logan with CT intensities
geomphantoms phantom shepp-logan --size 256,256 --plane axial \
  --intensity ct --out shepp_ct.npy

# Tubes with custom filling intensities
geomphantoms phantom tubes --size 256,256,256 \
  --intensity '{"outer_cylinder":0.3,"tube_fillings":[0.2,0.4,0.6,0.8,1.0]}' \
  --out tubes.npy
```

#### Multiple Output Formats

```bash
# NIfTI with compression
geomphantoms phantom torso --size 128,128,128 --out torso.nii.gz

# BART format
geomphantoms phantom torso --size 128,128,128 --format cfl --out phantom_base

# Multi-page TIFF (all slices in one file)
geomphantoms phantom torso --size 128,128,128 --out torso.tiff
```

#### Dynamic Phantoms with Motion

```bash
# Generate respiratory signal
geomphantoms signals respiratory --duration 10 --fs 24 --rate 15 --out resp.csv

# Generate cardiac signal
geomphantoms signals cardiac --duration 10 --fs 100 --rate 70 --out cardiac.json

# Create torso with respiratory motion
geomphantoms phantom torso --size 128,128,128 \
  --resp-signal resp.csv --out torso_resp.npy

# Create torso with both respiratory and cardiac motion
geomphantoms phantom torso --size 128,128,128 \
  --resp-signal resp.csv --cardiac-signal cardiac.json \
  --out torso_dynamic.npy
```

#### Signal Generation

```bash
# Respiratory signal, 30 seconds at 24 Hz, 12 breaths/min
geomphantoms signals respiratory --duration 30 --fs 24 --rate 12 --out resp.csv

# Cardiac signal, 10 seconds at 100 Hz, 75 beats/min
geomphantoms signals cardiac --duration 10 --fs 100 --rate 75 --out cardiac.json

# Respiratory signal with custom physiology
geomphantoms signals respiratory --duration 10 --fs 24 \
  --physiology '{"amplitude":1.5,"baseline":0.5}' --out resp.csv
```

#### Metadata Control

```bash
# Disable metadata
geomphantoms phantom shepp-logan --size 256,256 --plane axial \
  --out shepp.npy --no-meta

# Custom metadata path
geomphantoms phantom torso --size 128,128,128 --out torso.mat \
  --meta ./metadata/torso_info.json
```

---

### Tips and Best Practices

1. **Format Inference:** Let the CLI infer the format from the file extension when possible:
   ```bash
   geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy
   # Format is inferred as 'npy'
   ```

2. **BART Format:** Always provide the base path without extension when using BART format:
   ```bash
   geomphantoms phantom torso --size 128,128,128 --format cfl --out phantom
   # Creates phantom.cfl and phantom.hdr
   ```

3. **2D vs 3D:** For 2D output, specify `--plane`:
   ```bash
   # 2D requires --plane
   geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy
   
   # 3D does not use --plane
   geomphantoms phantom torso --size 128,128,128 --out torso.npy
   ```

4. **Signal Length Matching:** When using both respiratory and cardiac signals, ensure they have the same number of samples:
   ```bash
   # Both 10 seconds at different sampling rates is OK if they end up with same length
   geomphantoms signals respiratory --duration 10 --fs 24 --out resp.csv
   geomphantoms signals cardiac --duration 10 --fs 24 --out cardiac.csv
   ```

5. **Large Volumes:** For large 3D volumes, use compressed formats:
   ```bash
   geomphantoms phantom torso --size 512,512,512 --out torso.nii.gz
   ```

6. **Multi-page TIFF:** For 3D data that needs to be opened in standard image viewers:
   ```bash
   geomphantoms phantom torso --size 256,256,256 --out torso.tiff
   # Creates multi-page TIFF with all slices
   ```

7. **Version Information:** Check the version before reporting issues:
   ```bash
   geomphantoms info
   ```
