module GeometricMedicalPhantoms

using Base.Threads

# Export cylinder geometry types
export CylinderZ, CylinderY, CylinderX, Cylinder

# Export drawing functions
export draw!

# Export physiological signal generation functions and structs
export generate_respiratory_signal, RespiratoryPhysiology
export generate_cardiac_signals, CardiacPhysiology

# Export torso phantom functions and structs
export create_torso_phantom, TissueIntensities, TissueMask

# Export Shepp-Logan phantom functions and structs
export create_shepp_logan_phantom, SheppLoganIntensities, SheppLoganMask, CTSheppLoganIntensities, MRISheppLoganIntensities

# Export tubes phantom functions and structs
export create_tubes_phantom, TubesGeometry, TubesIntensities, TubesMask

include("geometries/utils.jl")
include("geometries/ellipsoid.jl")
include("geometries/superellipsoid.jl")
include("geometries/rotated_ellipsoid.jl")
include("geometries/cylinder.jl")
include("physiological_signals/respiratory_signals.jl")
include("physiological_signals/cardiac_signals.jl")
include("torso_phantom/tissue_intensities.jl")
include("torso_phantom/geometry_definitions.jl")
include("torso_phantom/motion_calculations.jl")
include("torso_phantom/create_2D_torso_phantom.jl")
include("torso_phantom/create_3D_torso_phantom.jl")
include("torso_phantom/validation.jl")
include("shepp_logan/intensities.jl")
include("shepp_logan/geometry_definitions.jl")
include("shepp_logan/create_phantom.jl")
include("tubes_phantom/intensities.jl")
include("tubes_phantom/geometry_definitions.jl")
include("tubes_phantom/create_phantom.jl")

include("precompile.jl")

end
