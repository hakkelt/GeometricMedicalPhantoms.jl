module GeometricMedicalPhantoms

using Base.Threads

# Export physiological signal generation functions and structs
export generate_respiratory_signal, RespiratoryPhysiology
export generate_cardiac_signals, CardiacPhysiology

# Export torso phantom functions and structs
export create_torso_phantom, TissueIntensities, TissueMask, AbstractTissueParameters

# Export utility functions
export count_voxels, calculate_volume

include("geometries/utils.jl")
include("geometries/ellipsoid.jl")
include("geometries/superellipsoid.jl")
include("physiological_signals/respiratory_signals.jl")
include("physiological_signals/cardiac_signals.jl")
include("torso_phantom/tissue_intensities.jl")
include("torso_phantom/geometry_definitions.jl")
include("torso_phantom/motion_calculations.jl")
include("torso_phantom/create_2D_torso_phantom.jl")
include("torso_phantom/create_3D_torso_phantom.jl")
include("torso_phantom/validation.jl")
include("precompile.jl")

end
