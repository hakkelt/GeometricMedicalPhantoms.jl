using BenchmarkTools
using GeometricMedicalPhantoms

# Define benchmark suite
const SUITE = BenchmarkGroup()

# Benchmark generate_respiratory_signal with default parameters
SUITE["generate_respiratory_signal"] = @benchmarkable generate_respiratory_signal(60.0, 50.0, 15.0)

# Benchmark generate_cardiac_signals with default parameters
SUITE["generate_cardiac_signals"] = @benchmarkable generate_cardiac_signals(10.0, 500.0, 70.0)

# 3D Phantom Benchmarks
SUITE["3D Phantoms"] = BenchmarkGroup()

# Benchmark create_torso_phantom with default parameters (128x128x128)
SUITE["3D Phantoms"]["generate_torso_phantom"] = @benchmarkable create_torso_phantom(128, 128, 128)

# Benchmark create_torso_phantom with smaller size (64x64x64)
SUITE["3D Phantoms"]["generate_torso_phantom_small"] = @benchmarkable create_torso_phantom(64, 64, 64)

# Benchmark with time-varying respiratory and cardiac signals
resp_signal = generate_respiratory_signal(2.0, 12.0, 15.0)[2]
cardiac_vols = generate_cardiac_signals(2.0, 12.0, 70.0)[2]
SUITE["3D Phantoms"]["generate_torso_phantom_time_varying"] = @benchmarkable create_torso_phantom(128, 128, 128; respiratory_signal=resp_signal, cardiac_volumes=cardiac_vols)

# 2D Phantom Benchmarks
SUITE["2D Phantoms"] = BenchmarkGroup()

# Benchmark 2D phantom generation - axial slice
SUITE["2D Phantoms"]["axial_128x128"] = @benchmarkable create_torso_phantom(128, 128, :axial)

# Benchmark 2D phantom generation - coronal slice
SUITE["2D Phantoms"]["coronal_128x128"] = @benchmarkable create_torso_phantom(128, 128, :coronal)

# Benchmark 2D phantom generation - sagittal slice
SUITE["2D Phantoms"]["sagittal_128x128"] = @benchmarkable create_torso_phantom(128, 128, :sagittal)

# Benchmark 2D phantom with different sizes
SUITE["2D Phantoms"]["axial_64x64"] = @benchmarkable create_torso_phantom(64, 64, :axial)
SUITE["2D Phantoms"]["axial_256x256"] = @benchmarkable create_torso_phantom(256, 256, :axial)

# Benchmark 2D phantom with custom slice position
SUITE["2D Phantoms"]["axial_slice_position"] = @benchmarkable create_torso_phantom(128, 128, :axial; slice_position=5.0)

# Benchmark 2D phantom with time-varying motion
resp_signal = generate_respiratory_signal(2.0, 12.0, 15.0)[2]
cardiac_vols = generate_cardiac_signals(2.0, 12.0, 70.0)[2]
SUITE["2D Phantoms"]["axial_time_varying"] = @benchmarkable create_torso_phantom(64, 64, :axial; respiratory_signal=$resp_signal, cardiac_volumes=$cardiac_vols)
