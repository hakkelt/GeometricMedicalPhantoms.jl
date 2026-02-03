using Test
using GeometricMedicalPhantoms
using ImagePhantoms

@testset "Shepp-Logan Phantom" begin
    @testset "Basic Properties" begin
        nx, ny, nz = 64, 64, 64
        
        # 2D Axial
        phantom_2d = create_shepp_logan_phantom(nx, ny, :axial)
        @test size(phantom_2d) == (nx, ny)
        @test eltype(phantom_2d) == Float32
        @test sum(phantom_2d) ≈ 1347.1504f0 # Regression test: verify sum is consistent
        
        # 3D
        phantom_3d = create_shepp_logan_phantom(nx, ny, nz)
        @test size(phantom_3d) == (nx, ny, nz)
        @test sum(phantom_3d) ≈ 45097.31f0 # Regression test: verify sum is consistent
        
        # Type support
        phantom_f64 = create_shepp_logan_phantom(nx, ny, :axial; eltype=Float64)
        @test eltype(phantom_f64) == Float64

        # MRI Intensities
        phantom_mri = create_shepp_logan_phantom(nx, ny, :axial; ti=MRISheppLoganIntensities())
        @test sum(phantom_mri) ≈ 307.49997f0 # Regression test: verify sum is consistent
    end
    
    @testset "Masking" begin
        nx, ny = 64, 64
        mask = SheppLoganMask(skull=true)
        phantom_mask = create_shepp_logan_phantom(nx, ny, :axial; ti=mask)
        phantom_only_skull = create_shepp_logan_phantom(nx, ny, :axial)
        @test all(phantom_mask .== (phantom_only_skull .> 1.5))
    end

    @testset "CT Comparison with ImagePhantoms" begin
        nx, ny = 64, 64
        fovs = (16.0, 16.0)
        phantom_our = create_shepp_logan_phantom(nx, ny, :axial; fovs=fovs)
        
        Δx, Δy = fovs[1]/nx, fovs[2]/ny
        ax_x = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δx
        ax_y = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δy
        ax_z = [-2.0]
        params = ellipsoid_parameters()
        ob_ref = ellipsoid(params)
        ref = phantom(ax_x ./ 16, ax_y ./ 16, ax_z ./ 16, ob_ref)

        @test phantom_our ≈ ref
    end

    @testset "FOV Scaling and Cropping" begin
        # Test that rendering with fov=(10,10,10) and size (64,64,64) equals
        # cropping the center of a rendered phantom with fov=(20,20,20) and size (128,128,128)
        phantom_small = create_shepp_logan_phantom(64, 64, 64; fovs=(10, 10, 10))
        phantom_large = create_shepp_logan_phantom(128, 128, 128; fovs=(20, 20, 20))
        
        # Extract center of the large phantom
        center_crop = phantom_large[33:96, 33:96, 33:96] # 33 = (128 - 64) / 2 + 1, 96 = 33 + 64 - 1
        
        @test phantom_small ≈ center_crop atol=1e-6
    end

    @testset "2D Slicing Consistency - Axial" begin
        # Test that rendering a 3D volume slice by slice in axial plane
        # gives the same output as rendering the 3D phantom
        nx, ny, nz = 64, 64, 64
        fovs = (20, 20, 20)
        
        # Render full 3D phantom
        phantom_3d = create_shepp_logan_phantom(nx, ny, nz; fovs=fovs)
        
        # Render each axial slice individually
        phantom_2d_slices = Array{Float32,3}(undef, nx, ny, nz)
        for k in 1:nz
            slice_pos = (k - 1 - (nz-1)/2) * (fovs[3] / nz)
            slice_2d = create_shepp_logan_phantom(nx, ny, :axial; fovs=(fovs[1], fovs[2]), slice_position=slice_pos)
            phantom_2d_slices[:, :, k] = slice_2d
        end
        @test phantom_2d_slices ≈ phantom_3d atol=1e-6
    end

    @testset "2D Slicing Consistency - Coronal" begin
        # Test that rendering a 3D volume slice by slice in coronal plane
        # gives the same output as rendering the 3D phantom
        nx, ny, nz = 64, 64, 64
        fovs = (20, 20, 20)
        
        # Render full 3D phantom
        phantom_3d = create_shepp_logan_phantom(nx, ny, nz; fovs=fovs)
        
        # Render each coronal slice individually
        phantom_2d_slices = Array{Float32,3}(undef, nx, ny, nz)
        for j in 1:ny
            slice_pos = (j - 1 - (ny-1)/2) * (fovs[2] / ny)
            slice_2d = create_shepp_logan_phantom(nx, nz, :coronal; fovs=(fovs[1], fovs[3]), slice_position=slice_pos)
            phantom_2d_slices[:, j, :] = slice_2d
        end
        @test phantom_2d_slices ≈ phantom_3d atol=1e-6
    end

    @testset "2D Slicing Consistency - Sagittal" begin
        # Test that rendering a 3D volume slice by slice in sagittal plane
        # gives the same output as rendering the 3D phantom
        nx, ny, nz = 64, 64, 64
        fovs = (20, 20, 20)
        
        # Render full 3D phantom
        phantom_3d = create_shepp_logan_phantom(nx, ny, nz; fovs=fovs)
        
        # Render each sagittal slice individually
        phantom_2d_slices = Array{Float32,3}(undef, nx, ny, nz)
        for i in 1:nx
            slice_pos = (i - 1 - (nx-1)/2) * (fovs[1] / nx)
            slice_2d = create_shepp_logan_phantom(ny, nz, :sagittal; fovs=(fovs[2], fovs[3]), slice_position=slice_pos)
            phantom_2d_slices[i, :, :] = slice_2d
        end
        @test phantom_2d_slices ≈ phantom_3d atol=1e-6
    end

    @testset "Intensity Changes Reflected in Rendering" begin
        # Test that changing intensities is reflected in the rendered image
        nx, ny, nz = 64, 64, 64
        fovs = (20, 20, 20)
        
        # Create custom intensity based on MRI but with different "top" value
        mri_intensities = MRISheppLoganIntensities()
        custom_intensities = SheppLoganIntensities(
            skull = mri_intensities.skull,
            brain = mri_intensities.brain,
            right_big = mri_intensities.right_big,
            left_big = mri_intensities.left_big,
            top = 0.5,  # Changed from 0.1
            middle_high = mri_intensities.middle_high,
            bottom_left = mri_intensities.bottom_left,
            middle_low = mri_intensities.middle_low,
            bottom_center = mri_intensities.bottom_center,
            bottom_right = mri_intensities.bottom_right,
            extra_1 = mri_intensities.extra_1,
            extra_2 = mri_intensities.extra_2
        )
        
        # Render with MRI intensities
        phantom_mri = create_shepp_logan_phantom(nx, ny, nz; fovs=fovs, ti=mri_intensities)
        
        # Render with custom intensities
        phantom_custom = create_shepp_logan_phantom(nx, ny, nz; fovs=fovs, ti=custom_intensities)

        # Render mask that selects only the "top" ellipsoid
        mask = create_shepp_logan_phantom(nx, ny, nz; fovs=fovs, ti=SheppLoganMask(top=true))
        
        # They should be different
        expected_intensity_diff = 0.5 - mri_intensities.top
        @test all(phantom_custom[mask] .- phantom_mri[mask] .≈ expected_intensity_diff)
        
        # Test 2D axial as well
        phantom_mri_2d = create_shepp_logan_phantom(nx, ny, :axial; fovs=(fovs[1], fovs[2]), ti=mri_intensities);
        phantom_custom_2d = create_shepp_logan_phantom(nx, ny, :axial; fovs=(fovs[1], fovs[2]), ti=custom_intensities);
        
        @test all(phantom_custom_2d[mask[:, :, div(nz,2)]] .- phantom_mri_2d[mask[:, :, div(nz,2)]] .≈ expected_intensity_diff)
        
        # Test 2D coronal as well
        phantom_mri_2d = create_shepp_logan_phantom(nx, ny, :coronal; fovs=(fovs[1], fovs[3]), ti=mri_intensities)
        phantom_custom_2d = create_shepp_logan_phantom(nx, ny, :coronal; fovs=(fovs[1], fovs[3]), ti=custom_intensities)

        @test all(phantom_custom_2d[mask[:, div(ny,2), :]] .- phantom_mri_2d[mask[:, div(ny,2), :]] .≈ expected_intensity_diff)
        
        # Test 2D sagittal as well
        phantom_mri_2d = create_shepp_logan_phantom(nx, ny, :sagittal; fovs=(fovs[2], fovs[3]), ti=mri_intensities)
        phantom_custom_2d = create_shepp_logan_phantom(nx, ny, :sagittal; fovs=(fovs[2], fovs[3]), ti=custom_intensities)

        @test all(phantom_custom_2d[mask[div(nx,2), :, :]] .- phantom_mri_2d[mask[div(nx,2), :, :]] .≈ expected_intensity_diff)
    end
end
