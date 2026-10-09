using Test
using GeometricMedicalPhantoms

# Mean over `s`-wide blocks along every dimension.
function block_mean(A, s)
    out = zeros(eltype(A), size(A) .÷ s)
    for I in CartesianIndices(A)
        J = CartesianIndex(ntuple(d -> (I[d] - 1) ÷ s + 1, ndims(A)))
        out[J] += A[I]
    end
    return out ./ s^ndims(A)
end

@testset "Supersampling" begin
    @testset "supersample = 1 is point sampling" begin
        @test create_shepp_logan_phantom(40, 36, :axial; supersample = 1) == create_shepp_logan_phantom(40, 36, :axial)
        @test create_torso_phantom(40, 36, :axial; supersample = 1) == create_torso_phantom(40, 36, :axial)
        @test create_tubes_phantom(40, 36, :axial; supersample = 1) == create_tubes_phantom(40, 36, :axial)
    end

    # The sub-samples of a voxel are the centres of the voxels of an `s` times finer grid, so the
    # supersampled phantom is the block mean of the point-sampled fine one.
    @testset "Equals the block mean of an s times finer phantom" begin
        for s in (2, 3)
            @test create_shepp_logan_phantom(40, 36, :axial; supersample = s, eltype = Float64) ≈
                block_mean(create_shepp_logan_phantom(40s, 36s, :axial; eltype = Float64), s)
            @test create_shepp_logan_phantom(20, 18, 16; supersample = s, eltype = Float64) ≈
                block_mean(create_shepp_logan_phantom(20s, 18s, 16s; eltype = Float64), s)
            torso = create_torso_phantom(40, 36, :axial; supersample = s, eltype = Float64)
            @test torso[:, :, 1] ≈ block_mean(create_torso_phantom(40s, 36s, :axial; eltype = Float64)[:, :, 1], s)
            torso3 = create_torso_phantom(16, 14, 12; supersample = s, eltype = Float64)
            @test torso3[:, :, :, 1] ≈ block_mean(create_torso_phantom(16s, 14s, 12s; eltype = Float64)[:, :, :, 1], s)
        end
    end

    @testset "Edges get partial-volume values" begin
        point = create_shepp_logan_phantom(64, 64, :axial; ti = MRISheppLoganIntensities())
        area = create_shepp_logan_phantom(64, 64, :axial; ti = MRISheppLoganIntensities(), supersample = 4)
        @test length(unique(area)) > 2 * length(unique(point))
        @test sum(area) ≈ sum(point) rtol = 0.05
        tubes = create_tubes_phantom(32, 32, 8; supersample = 2)
        @test size(tubes) == (32, 32, 8)
        stack = create_tubes_phantom(32, 32, :axial; ti = [TubesIntensities(), TubesIntensities(tube_fillings = [0.2])], supersample = 2)
        @test size(stack) == (32, 32, 2)
    end

    @testset "Argument checks" begin
        @test_throws ArgumentError create_shepp_logan_phantom(16, 16, :axial; supersample = 0)
        @test_throws ArgumentError create_shepp_logan_phantom(16, 16, :axial; ti = SheppLoganMask(skull = true), supersample = 2)
        @test_throws ArgumentError create_torso_phantom(16, 16, :axial; ti = TissueMask(lung = true), supersample = 2)
    end
end
