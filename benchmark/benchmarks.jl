using BenchmarkTools
using GeometricMedicalPhantoms

# Define benchmark suite
const SUITE = BenchmarkGroup()

# Benchmark generate_respiratory_signal with default parameters
SUITE["generate_respiratory_signal"] = @benchmarkable generate_respiratory_signal(60.0, 50.0, 15.0)

# Benchmark generate_cardiac_signals with default parameters
SUITE["generate_cardiac_signals"] = @benchmarkable generate_cardiac_signals(10.0, 500.0, 70.0)

# Benchmark create_torso_phantom with default parameters (128x128x128)
SUITE["generate_torso_phantom"] = @benchmarkable create_torso_phantom(128, 128, 128)

# Benchmark create_torso_phantom with smaller size (64x64x64)
SUITE["generate_torso_phantom_small"] = @benchmarkable create_torso_phantom(64, 64, 64)

