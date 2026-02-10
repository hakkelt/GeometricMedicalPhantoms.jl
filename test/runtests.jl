using Test

@testset "GeometricMedicalPhantoms.jl" begin
    # Unit tests for geometries
    include("test_cylinder.jl")
    include("test_superellipsoid.jl")
    include("test_rotated_ellipsoid.jl")

    # Tests for phantoms
    include("test_shepp_logan.jl")
    include("test_tubes_phantom.jl")
    include("test_generate_respiratory_signal.jl")
    include("test_generate_cardiac_signals.jl")
    include("test_create_torso_phantom_2D.jl")
    include("test_create_torso_phantom_3D.jl")

    # Quality assurance tests
    include("test_aqua.jl")
    include("test_jet.jl")
end
