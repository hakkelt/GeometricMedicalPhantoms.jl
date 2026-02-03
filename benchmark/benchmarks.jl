using BenchmarkTools
using GeometricMedicalPhantoms

# Define benchmark suite
const SUITE = BenchmarkGroup()

# Benchmark generate_respiratory_signal with default parameters
SUITE["generate_respiratory_signal"] = @benchmarkable generate_respiratory_signal(60.0, 50.0, 15.0)

# Benchmark generate_cardiac_signals with default parameters
SUITE["generate_cardiac_signals"] = @benchmarkable generate_cardiac_signals(10.0, 500.0, 70.0)

# 3D Phantom Benchmarks
SUITE["3D Torso"] = BenchmarkGroup()

# Benchmark create_torso_phantom with default parameters (128x128x128)
SUITE["3D Torso"]["generate_torso_phantom"] = @benchmarkable create_torso_phantom(128, 128, 128)

# Benchmark create_torso_phantom with smaller size (64x64x64)
SUITE["3D Torso"]["generate_torso_phantom_small"] = @benchmarkable create_torso_phantom(64, 64, 64)

# Benchmark with time-varying respiratory and cardiac signals
resp_signal = generate_respiratory_signal(2.0, 12.0, 15.0)[2]
cardiac_vols = generate_cardiac_signals(2.0, 12.0, 70.0)[2]
SUITE["3D Torso"]["generate_torso_phantom_time_varying"] = @benchmarkable create_torso_phantom(128, 128, 128; respiratory_signal=resp_signal, cardiac_volumes=cardiac_vols)

# 2D Phantom Benchmarks
SUITE["2D Torso"] = BenchmarkGroup()

# Benchmark 2D phantom generation - axial slice
SUITE["2D Torso"]["axial_128x128"] = @benchmarkable create_torso_phantom(128, 128, :axial)

# Benchmark 2D phantom generation - coronal slice
SUITE["2D Torso"]["coronal_128x128"] = @benchmarkable create_torso_phantom(128, 128, :coronal)

# Benchmark 2D phantom generation - sagittal slice
SUITE["2D Torso"]["sagittal_128x128"] = @benchmarkable create_torso_phantom(128, 128, :sagittal)

# Benchmark 2D phantom with different sizes
SUITE["2D Torso"]["axial_64x64"] = @benchmarkable create_torso_phantom(64, 64, :axial)
SUITE["2D Torso"]["axial_256x256"] = @benchmarkable create_torso_phantom(256, 256, :axial)

# Benchmark 2D phantom with custom slice position
SUITE["2D Torso"]["axial_slice_position"] = @benchmarkable create_torso_phantom(128, 128, :axial; slice_position=5.0)

# Benchmark 2D phantom with time-varying motion
resp_signal = generate_respiratory_signal(2.0, 12.0, 15.0)[2]
cardiac_vols = generate_cardiac_signals(2.0, 12.0, 70.0)[2]
SUITE["2D Torso"]["axial_time_varying"] = @benchmarkable create_torso_phantom(64, 64, :axial; respiratory_signal=$resp_signal, cardiac_volumes=$cardiac_vols)

# Shepp-Logan Phantom Benchmarks
SUITE["Shepp-Logan Phantom"] = BenchmarkGroup()

SUITE["Shepp-Logan Phantom"]["3D volume 128³"] = @benchmarkable create_shepp_logan_phantom(128, 128, 128)
SUITE["Shepp-Logan Phantom"]["3D MRI intensities"] = @benchmarkable create_shepp_logan_phantom(128, 128, 128; ti=MRISheppLoganIntensities())
SUITE["Shepp-Logan Phantom"]["3D mask (skull)"] = @benchmarkable create_shepp_logan_phantom(128, 128, 128; ti=SheppLoganMask(skull=true))

SUITE["Shepp-Logan Phantom"]["2D axial 256x256"] = @benchmarkable create_shepp_logan_phantom(256, 256, :axial)
SUITE["Shepp-Logan Phantom"]["2D coronal 256x256"] = @benchmarkable create_shepp_logan_phantom(256, 256, :coronal)
SUITE["Shepp-Logan Phantom"]["2D sagittal 256x256"] = @benchmarkable create_shepp_logan_phantom(256, 256, :sagittal)
SUITE["Shepp-Logan Phantom"]["2D axial MRI intensities"] = @benchmarkable create_shepp_logan_phantom(256, 256, :axial; ti=MRISheppLoganIntensities())
SUITE["Shepp-Logan Phantom"]["2D axial mask (skull)"] = @benchmarkable create_shepp_logan_phantom(256, 256, :axial; ti=SheppLoganMask(skull=true))

# Tubes Phantom Benchmarks
SUITE["Tubes Phantom"] = BenchmarkGroup()

const TUBES_LARGE_GEO = TubesGeometry(outer_radius=0.6, outer_height=1.2)
const TUBES_SINGLE_TUBE = TubesIntensities(outer_cylinder=0.25, tube_wall=0.0, tube_fillings=[0.5])
const TUBES_MASK = TubesMask(outer_cylinder=true, tube_wall=false, tube_fillings=fill(true, 6))
const TUBES_MULTI_INTENSITIES = [
	TubesIntensities(outer_cylinder=0.2, tube_fillings=[0.1]),
	TubesIntensities(outer_cylinder=0.5, tube_fillings=[0.4]),
	TubesIntensities(outer_cylinder=0.9, tube_fillings=[0.8])
]

SUITE["Tubes Phantom"]["3D default (64³)"] = @benchmarkable create_tubes_phantom(64, 64, 64)
SUITE["Tubes Phantom"]["3D larger geometry"] = @benchmarkable create_tubes_phantom(64, 64, 64; tg=TUBES_LARGE_GEO)
SUITE["Tubes Phantom"]["3D custom intensities"] = @benchmarkable create_tubes_phantom(64, 64, 64; ti=TUBES_SINGLE_TUBE)
SUITE["Tubes Phantom"]["3D boolean mask"] = @benchmarkable create_tubes_phantom(64, 64, 64; ti=TUBES_MASK)
SUITE["Tubes Phantom"]["3D multi-intensity stack"] = @benchmarkable create_tubes_phantom(64, 64, 64; ti=TUBES_MULTI_INTENSITIES)

SUITE["Tubes Phantom"]["2D axial 256x256"] = @benchmarkable create_tubes_phantom(256, 256, :axial)
SUITE["Tubes Phantom"]["2D coronal 256x256"] = @benchmarkable create_tubes_phantom(256, 256, :coronal)
SUITE["Tubes Phantom"]["2D sagittal 256x256"] = @benchmarkable create_tubes_phantom(256, 256, :sagittal)
SUITE["Tubes Phantom"]["2D axial slice position 5cm"] = @benchmarkable create_tubes_phantom(256, 256, :axial; slice_position=5.0)
SUITE["Tubes Phantom"]["2D mask slice (axial)"] = @benchmarkable create_tubes_phantom(256, 256, :axial; ti=TUBES_MASK)
SUITE["Tubes Phantom"]["2D multi-intensity stack"] = @benchmarkable create_tubes_phantom(256, 256, :axial; ti=TUBES_MULTI_INTENSITIES)
