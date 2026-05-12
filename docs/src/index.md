# GeometricMedicalPhantoms.jl

GeometricMedicalPhantoms provides tools for generating realistic medical imaging phantoms. These synthetic images are essential for testing reconstruction algorithms, validating imaging methods, and developing new acquisition strategies without requiring real patient data.

## Why Use Phantoms?

Phantoms are useful for:

- **Algorithm validation**: Test reconstruction methods with known ground truth
- **Method comparison**: Benchmark different imaging techniques
- **Quality assurance**: Verify scanner performance and image processing pipelines
- **Teaching and learning**: Understand MRI physics and acquisition concepts interactively
- **Research**: Prototype new acquisition strategies and reconstruction approaches

## Available Phantoms

The package provides three distinct phantom types suited to different needs:

| Phantom | Purpose | Dimensions | Features |
|---------|---------|-----------|----------|
| **Shepp-Logan** | Classic test phantom | 2D slices or 3D volume | Multiple intensity options, tissue masking |
| **Torso** | Anatomical realism | 2D slices of 3D anatomy | Heart, lungs, liver, vessels, physiological motion |
| **Tubes** | Validation & QC | 2D or 3D | Geometric precision, customizable configuration |

## Quick Start

Here's a typical workflow:

```@setup imports
using GeometricMedicalPhantoms
using MIRTjim: jim
using Plots
```

```@example imports
# Create a Shepp-Logan phantom (2D axial slice)
phantom_2d = create_shepp_logan_phantom(256, 256, :axial)

# Visualize it
jim(phantom_2d; title="Shepp-Logan Phantom", clim=(0.95, 1.05), yflip=false)
savefig("index_shepp_logan.png"); nothing # hide
```

![index_shepp_logan.png](index_shepp_logan.png)

```@example imports
# Create a Torso phantom animation with respiratory motion
using FileIO

duration = 2.0           # seconds
fs = 12.0                # frames per second
respiration_rate = 12.0  # breaths per minute
heart_rate = 72.0        # beats per minute

_, resp_liters = generate_respiratory_signal(duration, fs, respiration_rate)
_, cardiac_liters = generate_cardiac_signals(duration, fs, heart_rate)

torso_4d = create_torso_phantom(350, 350, :coronal; respiratory_signal=resp_liters, cardiac_volumes=cardiac_liters)
nt = length(resp_liters)
max_val = maximum(abs.(torso_4d))

frames_coronal_temporal = zeros(UInt8, 350, 350, nt)
for i in 1:nt
    slice = reverse(abs.(torso_4d[:, :, i])', dims=1)
    frames_coronal_temporal[:, :, i] = map(x -> UInt8(round(clamp(x / max_val, 0, 1) * 255)), slice)
end

save("index_torso.gif", frames_coronal_temporal, fps=fs)
nothing # hide
```

![index_torso.gif](index_torso.gif)

```@example imports
# Create a validation phantom
tubes = create_tubes_phantom(256, 256, 256)

jim(tubes[:, :, div(end, 2)]; title="Tubes Phantom (Middle Slice)")
savefig("index_tubes.png"); nothing # hide
```

![index_tubes.png](index_tubes.png)

## Next Steps

- Learn about the [Shepp-Logan phantom](phantoms/shepp_logan.md) and its intensity variants
- Explore the [Torso phantom](phantoms/torso.md) with physiological motion
- Use the [Tubes phantom](phantoms/tubes.md) for validation
- Check out standalone [CLI interface](cli.md) for rendering phantoms without installing Julia, or use the [C/C++](bindings/c_cpp.md) interface, [Python bindings](bindings/python.md), and [MATLAB toolbox](bindings/matlab.md).
- Understand [geometry primitives](advanced/primitives.md) for building custom phantoms
- Create your own phantom by following the [custom phantoms guide](advanced/custom_phantoms.md)

## Downloads

Besides the Julia package which can be installed via the Julia package manager, pre-built binaries are published to each
[GitHub release](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest) for all major platforms.  No Julia installation is required to use these.

### CLI app

| Platform | Download |
|---|---|
| Linux x86-64 | [geomphantoms-linux-x86_64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-linux-x86_64.tar.xz) |
| Linux aarch64 | [geomphantoms-linux-aarch64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-linux-aarch64.tar.xz) |
| macOS x86-64 | [geomphantoms-macos-x86_64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-macos-x86_64.tar.xz) |
| macOS aarch64 | [geomphantoms-macos-aarch64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-macos-aarch64.tar.xz) |
| Windows x86-64 | [geomphantoms-windows-x86_64.zip](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-windows-x86_64.zip) |

### Shared library (C / Python)

| Platform | Download |
|---|---|
| Linux x86-64 | [geomphantoms-lib-linux-x86_64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-lib-linux-x86_64.tar.xz) |
| Linux aarch64 | [geomphantoms-lib-linux-aarch64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-lib-linux-aarch64.tar.xz) |
| macOS x86-64 | [geomphantoms-lib-macos-x86_64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-lib-macos-x86_64.tar.xz) |
| macOS aarch64 | [geomphantoms-lib-macos-aarch64.tar.xz](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-lib-macos-aarch64.tar.xz) |
| Windows x86-64 | [geomphantoms-lib-windows-x86_64.zip](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/geomphantoms-lib-windows-x86_64.zip) |

### Python wheels

Binary wheels embed the shared library and its Julia runtime.  Install
directly with pip (see [Python bindings](bindings/python.md) for per-platform
commands), or browse the
[latest release](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest)
for the exact filenames.  A pure-Python stub is also on
[PyPI](https://pypi.org/project/geometric-medical-phantoms/). This provides the same API but requires a separate shared library installation.

### MATLAB toolbox

The MATLAB toolbox uses Julia via Mex.jl and requires Julia to be installed on
the system. It does not depend on the shared library above.

| Platform | Download |
|---|---|
| Linux x86-64 | [GeometricMedicalPhantoms-matlab-glnxa64.mltbx](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/GeometricMedicalPhantoms-matlab-glnxa64.mltbx) |
| macOS Intel | [GeometricMedicalPhantoms-matlab-maci64.mltbx](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/GeometricMedicalPhantoms-matlab-maci64.mltbx) |
| macOS Apple Silicon | [GeometricMedicalPhantoms-matlab-maca64.mltbx](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/GeometricMedicalPhantoms-matlab-maca64.mltbx) |
| Windows x86-64 | [GeometricMedicalPhantoms-matlab-win64.mltbx](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases/latest/download/GeometricMedicalPhantoms-matlab-win64.mltbx) |
