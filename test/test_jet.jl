using JET
using Test
using GeometricMedicalPhantoms

const GMP = GeometricMedicalPhantoms

@testset "JET static analysis" begin
    # Run JET.jl static analysis on the package
    # target_modules=(GeometricMedicalPhantoms,) ensures we only analyze this package
    JET.test_package(
        GeometricMedicalPhantoms;
        target_modules = (GeometricMedicalPhantoms,)
    )

    @testset "@test_opt" begin
        n = 128

        # Torso phantom — 3D
        @test_opt target_modules = (GMP,) create_torso_phantom(n, n, n)
        @test_opt target_modules = (GMP,) create_torso_phantom(n, n, n; ti = TissueMask(lung = true))

        # Torso phantom — 2D (all orientations)
        @test_opt target_modules = (GMP,) create_torso_phantom(n, n, :axial)
        @test_opt target_modules = (GMP,) create_torso_phantom(n, n, :axial; ti = TissueMask(lung = true))

        # Shepp-Logan — 3D
        @test_opt target_modules = (GMP,) create_shepp_logan_phantom(n, n, n)
        @test_opt target_modules = (GMP,) create_shepp_logan_phantom(n, n, n; ti = SheppLoganMask(skull = true))

        # Shepp-Logan — 2D
        @test_opt target_modules = (GMP,) create_shepp_logan_phantom(n, n, :axial)

        # Tubes — 3D
        @test_opt target_modules = (GMP,) create_tubes_phantom(n, n, n)
        @test_opt target_modules = (GMP,) create_tubes_phantom(n, n, n; tg = TubesGeometry(), ti = TubesMask(tube_wall = true))

        # Tubes — 2D
        @test_opt target_modules = (GMP,) create_tubes_phantom(n, n, :axial)
    end

    @testset "@test_call" begin
        n = 128

        # Torso phantom — 3D
        @test_call target_modules = (GMP,) create_torso_phantom(n, n, n)
        @test_call target_modules = (GMP,) create_torso_phantom(n, n, n; ti = TissueMask(lung = true))

        # Torso phantom — 2D (all orientations)
        @test_call target_modules = (GMP,) create_torso_phantom(n, n, :axial)
        @test_call target_modules = (GMP,) create_torso_phantom(n, n, :axial; ti = TissueMask(lung = true))

        # Shepp-Logan — 3D
        @test_call target_modules = (GMP,) create_shepp_logan_phantom(n, n, n)
        @test_call target_modules = (GMP,) create_shepp_logan_phantom(n, n, n; ti = SheppLoganMask(skull = true))

        # Shepp-Logan — 2D
        @test_call target_modules = (GMP,) create_shepp_logan_phantom(n, n, :axial)

        # Tubes — 3D
        @test_call target_modules = (GMP,) create_tubes_phantom(n, n, n)
        @test_call target_modules = (GMP,) create_tubes_phantom(n, n, n; tg = TubesGeometry(), ti = TubesMask(tube_wall = true))

        # Tubes — 2D
        @test_call target_modules = (GMP,) create_tubes_phantom(n, n, :axial)
    end
end
