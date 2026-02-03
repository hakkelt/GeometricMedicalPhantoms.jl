# Benchmarks for GeometricMedicalPhantoms

This directory contains performance benchmarks for the GeometricMedicalPhantoms package.

## Running Benchmarks

### Run all benchmarks
```julia
using PkgBenchmark
results = benchmarkpkg("GeometricMedicalPhantoms")
```

### Run specific benchmark groups
```julia
include("benchmark/benchmarks.jl")
using BenchmarkTools

# Run all 2D phantom benchmarks
tune!(SUITE["2D Torso"])
results = run(SUITE["2D Torso"])
```

### Quick individual benchmarks
```julia
using BenchmarkTools
using GeometricMedicalPhantoms

# Benchmark 2D axial slice
@benchmark create_torso_phantom(128, 128, :axial)

# Benchmark 3D volume
@benchmark create_torso_phantom(128, 128, 128)
```

## Benchmark Categories

### Signal Generation
- `generate_respiratory_signal`: Respiratory signal generation (60s, 50Hz, 15 bpm)
- `generate_cardiac_signals`: Cardiac signal generation (10s, 500Hz, 70 bpm)

### 3D Phantom Generation
- `3D Torso/generate_torso_phantom`: Full 3D volume (128³)
- `3D Torso/generate_torso_phantom_small`: Smaller 64³ volume
- `3D Torso/generate_torso_phantom_time_varying`: Time-varying 3D phantom with motion

### 2D Phantom Generation
- `2D Torso/axial_128x128`: Axial slice at default position
- `2D Torso/coronal_128x128`: Coronal slice at default position
- `2D Torso/sagittal_128x128`: Sagittal slice at default position
- `2D Torso/axial_64x64`: Smaller 64×64 axial slice
- `2D Torso/axial_256x256`: Larger 256×256 axial slice
- `2D Torso/axial_slice_position`: Axial slice at custom position (z=5cm)
- `2D Torso/axial_time_varying`: Time-varying 2D phantom with motion

### Performance Comparison
- `2D vs 3D/2D_slice_128x128`: Single 2D slice (128×128)
- `2D vs 3D/3D_volume_128x128x128`: Full 3D volume (128³)

## Expected Performance

Typical performance on a modern workstation:

- **2D Phantom (128×128)**: ~20 ms, ~33 MiB memory
- **3D Phantom (128³)**: ~360 ms, ~49 MiB memory
- **Speedup**: ~18× faster for 2D vs 3D

Performance will vary based on:
- CPU speed and number of cores (threaded operations)
- Available memory
- System load
- Slice orientation (axial typically slightly slower than coronal/sagittal)

### Shepp-Logan Phantom Generation
- `Shepp-Logan Phantom/3D volume 128³`: Full 3D volume rendered with the default CT intensities
- `Shepp-Logan Phantom/3D MRI intensities`: Same volume using MRI-derived intensities
- `Shepp-Logan Phantom/3D mask (skull)`: Mask-only rendering of the skull ellipsoid to track boolean performance
- `Shepp-Logan Phantom/2D axial 256x256`: Higher-resolution axial slice at the center plane
- `Shepp-Logan Phantom/2D coronal 256x256`: Coronal slice rendering for a complementary orientation
- `Shepp-Logan Phantom/2D sagittal 256x256`: Sagittal slice rendering for the left-right plane
- `Shepp-Logan Phantom/2D axial MRI intensities`: Axial slice rendered with MRI intensity presets
- `Shepp-Logan Phantom/2D axial mask (skull)`: Axial mask slice to capture boolean-workload timings

Use `tune!(SUITE["Shepp-Logan Phantom"])` before `run` to calibrate the new group, or run individual entries directly via `run(SUITE["Shepp-Logan Phantom"]["2D axial 256x256"])`.

### Tubes Phantom Generation
- `Tubes Phantom/3D default (64³)`: Baseline 3D cube with the default six-tube arrangement
- `Tubes Phantom/3D larger geometry`: Phantom rendered with an expanded outer cylinder (larger radius/height)
- `Tubes Phantom/3D custom intensities`: Single-tube intensities to focus on interior fill performance
- `Tubes Phantom/3D boolean mask`: Boolean mask generation so memory-bound draws can be profiled
- `Tubes Phantom/2D axial 256x256`: Axial slice at higher resolution to stress 2D draw routines
- `Tubes Phantom/2D coronal 256x256`: Coronal slice for cross-sectional orientation comparison
- `Tubes Phantom/2D sagittal 256x256`: Sagittal slice showcasing left-right rendering cost
- `Tubes Phantom/2D axial slice position 5cm`: Slices away from center to cover off-center axial draws
- `Tubes Phantom/2D mask slice (axial)`: Axial mask slice that exercises boolean intensity paths
- `Tubes Phantom/3D multi-intensity stack`: Render multiple 3D volumes with different intensity presets at once
- `Tubes Phantom/2D multi-intensity stack`: Stack several axial slices rendered with distinct intensity parameters

Tune and run this group the same way as others: `tune!(SUITE["Tubes Phantom"])` and `run(SUITE["Tubes Phantom"])`, or run just the entries of interest (e.g., `run(SUITE["Tubes Phantom"]["3D custom intensities"])`).
