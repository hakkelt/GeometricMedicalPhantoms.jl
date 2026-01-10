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
tune!(SUITE["2D Phantoms"])
results = run(SUITE["2D Phantoms"])
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
- `generate_torso_phantom`: 128³ phantom (default size)
- `generate_torso_phantom_small`: 64³ phantom (smaller, faster)

### 2D Phantom Generation
- `2D Phantoms/axial_128x128`: Axial slice at default position
- `2D Phantoms/coronal_128x128`: Coronal slice at default position
- `2D Phantoms/sagittal_128x128`: Sagittal slice at default position
- `2D Phantoms/axial_64x64`: Smaller 64×64 axial slice
- `2D Phantoms/axial_256x256`: Larger 256×256 axial slice
- `2D Phantoms/axial_slice_position`: Axial slice at custom position (z=5cm)
- `2D Phantoms/axial_time_varying`: Time-varying 2D phantom with motion

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
