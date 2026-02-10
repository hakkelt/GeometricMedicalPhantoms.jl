# GeometricMedicalPhantoms CLI

A command-line interface for generating medical imaging phantoms and physiological signals.

## Installation

### Option 1: Download Pre-built Binary (Recommended)

Download the latest release for your platform from the [Releases page](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases):

- **Linux**: `geomphantoms-linux-x64.zip`
- **macOS**: `geomphantoms-macos-x64.zip`  
- **Windows**: `geomphantoms-windows-x64.zip`

Extract the archive and run the `geomphantoms` executable directly:

```bash
# Linux/macOS
./geomphantoms info

# Windows
geomphantoms.exe info
```

### Option 2: Build from Source

Requires Julia 1.12 or later.

```bash
julia --project=./app -e 'using Pkg; Pkg.instantiate()'
juliac --output-exe geomphantoms --project=./app --bundle app/build --trim=safe app/src/app.jl
```

The executable will be in `app/build/bin/geomphantoms`.

### Option 3: Run with Julia

```bash
cd app
julia --project=. -e 'using GeometricMedicalPhantomsApp; GeometricMedicalPhantomsApp.main(ARGS)' -- info
```

## Usage

### Phantom Generation

Generate 2D or 3D medical imaging phantoms with various intensity presets and output formats.

#### 2D Shepp-Logan Phantom

```bash
geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy
```

Options:
- `--plane`: Slice plane (`axial`, `coronal`, `sagittal`)
- `--slice-position`: Slice position in cm (default: 0.0)
- `--intensity`: Preset (`ct`, `mri`, `default`) or custom JSON
- `--mask`: Mask configuration as JSON

#### 3D Torso Phantom

```bash
geomphantoms phantom torso --size 128,128,128 --out torso.mat
```

Options:
- `--intensity`: Tissue intensities as JSON
- `--mask`: Tissue mask configuration
- `--resp-signal`: Respiratory motion signal (CSV/JSON/NPY file)
- `--cardiac-signal`: Cardiac volume signal (CSV/JSON file)

#### Tubes Phantom

```bash
geomphantoms phantom tubes --size 256,256,256 --out tubes.npy
```

Options:
- `--geometry`: Tube geometry as JSON
- `--intensity`: Tube intensities as JSON
- `--stack`: Array of intensity objects for multiple tubes

### Signal Generation

Generate physiological signals for motion simulation.

#### Respiratory Signal

```bash
geomphantoms signals respiratory --duration 10 --fs 24 --rate 12 --out resp.csv
```

Options:
- `--duration`: Duration in seconds (default: 10.0)
- `--fs`: Sampling rate in Hz (default: 24.0)
- `--rate`: Breathing rate in breaths/min (default: 15.0)
- `--physiology`: Respiratory physiology parameters as JSON

#### Cardiac Signal

```bash
geomphantoms signals cardiac --duration 10 --fs 500 --rate 70 --out cardiac.json
```

Options:
- `--duration`: Duration in seconds (default: 10.0)
- `--fs`: Sampling rate in Hz (default: 24.0)
- `--rate`: Heart rate in beats/min (default: 70.0)
- `--physiology`: Cardiac physiology parameters as JSON

### Output Formats

The CLI supports multiple output formats:

| Format | Extension | Description |
|--------|-----------|-------------|
| NumPy | `.npy` | NumPy array format (default key: `"phantom"` or `"signal"`) |
| MATLAB | `.mat` | MATLAB MAT-file (variable: `"phantom"`) |
| BART | `.cfl`/`.hdr` | BART complex float format (pass base path without extension) |
| NIfTI | `.nii`, `.nii.gz` | Medical imaging format |
| PNG | `.png` | 2D image (grayscale, normalized) |
| CSV | `.csv` | Comma-separated values (signals only) |
| JSON | `.json` | JSON format (signals only) |

If `--format` is omitted, it's inferred from the file extension. For BART output, specify `--format cfl` and provide the base path:

```bash
geomphantoms phantom shepp-logan --size 256,256 --plane axial --format cfl --out ./phantom
# Creates phantom.cfl and phantom.hdr
```

### Metadata

By default, a JSON metadata file is written to `<output>.json` containing:
- Command and parameters
- Package and Julia versions
- Timestamp
- Phantom/signal configuration

Disable metadata output:
```bash
geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy --no-meta
```

Custom metadata path:
```bash
geomphantoms phantom shepp-logan --size 256,256 --plane axial --out shepp.npy --meta metadata.json
```

## Examples

### CT Shepp-Logan Phantom

```bash
geomphantoms phantom shepp-logan \
  --size 512,512 \
  --plane axial \
  --intensity ct \
  --out ct_shepp.npy
```

### MRI Torso with Motion

First generate a respiratory signal:
```bash
geomphantoms signals respiratory \
  --duration 60 \
  --fs 24 \
  --rate 15 \
  --out resp_signal.npy
```

Then use it for the phantom:
```bash
geomphantoms phantom torso \
  --size 128,128,64 \
  --resp-signal resp_signal.npy \
  --out torso_motion.nii.gz
```

### Custom Intensities

```bash
geomphantoms phantom tubes \
  --size 256,256 \
  --plane axial \
  --intensity '{"outer_cylinder":0.3,"tube_fillings":[0.2,0.4,0.6,0.8,1.0]}' \
  --out custom_tubes.png
```

## Development

The CLI is built on top of the GeometricMedicalPhantoms.jl package. For programmatic use and more advanced features, use the Julia package directly:

```julia
using GeometricMedicalPhantoms

# Create phantom in Julia
phantom = create_shepp_logan_phantom(256, 256, :axial)

# Access full API with custom parameters
phantom = create_torso_phantom(
    128, 128, 64;
    respiratory_signal = custom_signal,
    ti = TissueIntensities(muscle=0.5, fat=0.2)
)
```

See the [package documentation](https://hakkelt.github.io/GeometricMedicalPhantoms.jl/) for more details.

### Testing

The CLI includes a comprehensive test suite to ensure functionality across all platforms. Tests are automatically run via GitHub Actions on every push and pull request.

#### Run tests locally

```bash
cd app
julia --project=. -e 'using Pkg; Pkg.test()'
```

#### Continuous Integration

The CLI has two CI workflows:

1. **CLI Tests** (`cli-tests.yml`): Runs on every push/PR affecting the `app/` directory. Tests are run on Ubuntu, macOS, and Windows with Julia 1.12 and latest stable Julia.

2. **Build CLI** (`build-cli.yml`): Builds binary releases on version tags. The build process only proceeds if all CLI tests pass on all platforms.

This ensures that binary releases are only created from fully tested code.

## License

MIT License - see the parent package for details.
