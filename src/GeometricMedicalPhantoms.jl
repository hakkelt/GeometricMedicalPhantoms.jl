module GeometricMedicalPhantoms

using Base.Threads

# Export physiological signal generation functions and structs
export generate_respiratory_signal, RespiratoryPhysiology
export generate_cardiac_signals, CardiacPhysiology

# Export torso phantom functions and structs
export create_torso_phantom, TissueIntensities, TissueMask, AbstractTissueParameters

# Export utility functions
export count_voxels, calculate_volume

include("geometries/superellipsoid.jl")
include("torso_phantom/physiological_signals.jl")
include("torso_phantom/tissue_intensities.jl")
include("torso_phantom/create_torso_phantom.jl")
include("torso_phantom/validation.jl")

end
