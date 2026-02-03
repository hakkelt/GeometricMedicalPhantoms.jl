using GeometricMedicalPhantoms
using Test
using Statistics
import Aqua

include("utils.jl")

@testset "GeometricMedicalPhantoms.jl" begin
    include("test_generate_respiratory_signal.jl")
    include("test_generate_cardiac_signals.jl")
    include("test_superellipsoid.jl")
    include("test_rotated_ellipsoid.jl")
    include("test_shepp_logan.jl")
    include("test_create_torso_phantom_2D.jl")
    include("test_create_torso_phantom_3D.jl")

    @testset "Aqua" begin
        Aqua.test_all(GeometricMedicalPhantoms)
    end

    include("test_jet.jl")
end

