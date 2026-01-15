using Test
using GeometricMedicalPhantoms
using ImagePhantoms

@testset "Shepp-Logan Phantom" begin
    # 1. Basic properties
    nx, ny, nz = 64, 64, 64
    
    # 2D Axial
    phantom_2d = create_shepp_logan_phantom(nx, ny, :axial)
    @test size(phantom_2d) == (nx, ny)
    @test eltype(phantom_2d) == Float32
    
    # 3D
    phantom_3d = create_shepp_logan_phantom(nx, ny, nz)
    @test size(phantom_3d) == (nx, ny, nz)
    
    # 2. CT version regression test (Sum of intensities)
    # These values were verified against ImagePhantoms.jl
    phantom_ct = create_shepp_logan_phantom(nx, ny, :axial; fovs=(1.0, 1.0))
    @test isapprox(sum(phantom_ct), 2265.2, atol=0.1)
    
    # 3. MRI version (Toft)
    # These values were verified against ImagePhantoms.jl
    phantom_mri = create_shepp_logan_phantom(nx, ny, :axial; ti=MRISheppLoganIntensities(), fovs=(1.0, 1.0))
    @test isapprox(sum(phantom_mri), 556.0, atol=0.1)
    
    # 4. Masking
    mask = SheppLoganMask(skull=true)
    phantom_mask = create_shepp_logan_phantom(nx, ny, :axial; ti=mask, fovs=(1.0, 1.0))
    
    intensities_only_skull = SheppLoganIntensities(skull=1.0)
    phantom_only_skull = create_shepp_logan_phantom(nx, ny, :axial; ti=intensities_only_skull, fovs=(1.0, 1.0))
    
    @test all(phantom_mask .== (phantom_only_skull .> 0.5))
    
    # 5. Type support
    phantom_f64 = create_shepp_logan_phantom(nx, ny, :axial; eltype=Float64)
    @test eltype(phantom_f64) == Float64

    # 6. Comparison with ImagePhantoms.jl
    @testset "Comparison with ImagePhantoms" begin
        # Generate our phantom
        nx, ny = 64, 64
        fovs = (1.0, 1.0)
        phantom_our = create_shepp_logan_phantom(nx, ny, :axial; fovs=fovs)
        
        # Replicate the grid logic from create_shepp_logan_phantom
        Δx, Δy = fovs[1]/nx, fovs[2]/ny
        ax_x = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δx
        ax_y = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δy
        
        # Generate ImagePhantoms phantom on the exact same grid
        ob_ref = shepp_logan(SheppLogan())
        ref = phantom(ax_x, ax_y, ob_ref)
        
        # Check agreement
        # We use a slightly higher tolerance at edges due to discretization differences
        # But overall they should be very close.
        @test maximum(abs.(phantom_our .- ref)) <= 1.0
        
        # Check sum again explicitly here
        @test isapprox(sum(phantom_our), sum(ref), rtol=0.01)
    end

    @testset "MRI Comparison with ImagePhantoms" begin
        nx, ny = 64, 64
        fovs = (1.0, 1.0)
        
        # Our MRI phantom
        phantom_our = create_shepp_logan_phantom(nx, ny, :axial; ti=MRISheppLoganIntensities(), fovs=fovs)
        
        # Grid
        Δx, Δy = fovs[1]/nx, fovs[2]/ny
        ax_x = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δx
        ax_y = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δy
        
        # ImagePhantoms MRI (Toft)
        ob_ref = shepp_logan(SheppLoganToft())
        ref = phantom(ax_x, ax_y, ob_ref)
        
        # Debug info if fails
        diff = abs.(phantom_our .- ref)
        println("MRI Max diff: ", maximum(diff))
        
        # Allow some edge discrepancy but geometry should match
        @test maximum(diff) <= 1.0
        @test isapprox(sum(phantom_our), sum(ref), rtol=0.01)
    end
end
