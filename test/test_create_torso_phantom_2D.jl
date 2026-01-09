using Test
using GeometricMedicalPhantoms
using Statistics

@testset "2D Phantom Tests" begin
    @testset "Static Generation" begin
        @testset "2D phantom - Basic generation" begin
            # Test axial slice
            phantom_axial = create_torso_phantom(128, 128, :axial)
            @test size(phantom_axial) == (128, 128, 1)
            @test eltype(phantom_axial) == Float32
            @test count(x -> x != 0, phantom_axial) > 0

            # Test coronal slice
            phantom_coronal = create_torso_phantom(128, 128, :coronal)
            @test size(phantom_coronal) == (128, 128, 1)
            @test eltype(phantom_coronal) == Float32
            @test count(x -> x != 0, phantom_coronal) > 0

            # Test sagittal slice
            phantom_sagittal = create_torso_phantom(128, 128, :sagittal)
            @test size(phantom_sagittal) == (128, 128, 1)
            @test eltype(phantom_sagittal) == Float32
            @test count(x -> x != 0, phantom_sagittal) > 0

            # Test that different orientations produce different content
            @test !all(phantom_axial .== phantom_coronal)
            @test !all(phantom_axial .== phantom_sagittal)
            @test !all(phantom_coronal .== phantom_sagittal)
        end

        @testset "2D phantom - Custom dimensions" begin
            # Test various sizes
            for (nx, ny) in [(64, 64), (96, 96), (128, 64), (64, 128)]
                phantom = create_torso_phantom(nx, ny, :axial)
                @test size(phantom) == (nx, ny, 1)
                @test eltype(phantom) == Float32
            end
        end

        @testset "2D phantom - Custom FOV" begin
            # Test with custom FOV
            phantom_small = create_torso_phantom(64, 64, :axial; fovs=(20, 20))
            phantom_large = create_torso_phantom(64, 64, :axial; fovs=(40, 40))

            @test size(phantom_small) == (64, 64, 1)
            @test size(phantom_large) == (64, 64, 1)

            # Both should have non-zero content (different views of the phantom)
            @test count(x -> x != 0, phantom_small[:, :, 1]) > 0
            @test count(x -> x != 0, phantom_large[:, :, 1]) > 0
        end

        @testset "2D phantom - Slice position" begin
            # Test different slice positions
            phantom_z0 = create_torso_phantom(64, 64, :axial; slice_position=0.0)
            phantom_z5 = create_torso_phantom(64, 64, :axial; slice_position=5.0)
            phantom_z_neg5 = create_torso_phantom(64, 64, :axial; slice_position=-5.0)

            @test size(phantom_z0) == (64, 64, 1)
            @test size(phantom_z5) == (64, 64, 1)
            @test size(phantom_z_neg5) == (64, 64, 1)

            # Different positions should produce different content
            @test !all(phantom_z0 .== phantom_z5)
            @test !all(phantom_z0 .== phantom_z_neg5)

            # Slice at very extreme position should be mostly empty
            phantom_extreme = create_torso_phantom(64, 64, :axial; slice_position=20.0)
            @test count(x -> x != 0, phantom_extreme) <
                count(x -> x != 0, phantom_z0) / 2
        end
    end  # Static Generation

    @testset "Dynamic Generation (Time-Varying)" begin
        @testset "2D phantom - Time-varying (respiratory)" begin
            duration = 2.0
            fs = 12.0
            rr = 15.0
            t, resp = generate_respiratory_signal(duration, fs, rr)

            phantom = create_torso_phantom(64, 64, :axial; respiratory_signal=resp)
            @test size(phantom) == (64, 64, length(resp))
            @test eltype(phantom) == Float32

            # Different frames should have different content
            @test !all(phantom[:, :, 1] .== phantom[:, :, div(length(resp), 2)])
            @test !all(phantom[:, :, 1] .== phantom[:, :, end])
        end

        @testset "2D phantom - Time-varying (cardiac)" begin
            duration = 2.0
            fs = 12.0
            hr = 70.0
            t, vols = generate_cardiac_signals(duration, fs, hr)

            phantom = create_torso_phantom(64, 64, :axial; cardiac_volumes=vols)
            @test size(phantom) == (64, 64, length(vols.lv))
            @test eltype(phantom) == Float32

            # Different frames should have different content
            @test !all(phantom[:, :, 1] .== phantom[:, :, div(length(vols.lv), 2)])
        end

        @testset "2D phantom - Time-varying (both)" begin
            duration = 2.0
            fs = 12.0
            rr = 15.0
            hr = 70.0
            t_resp, resp = generate_respiratory_signal(duration, fs, rr)
            t_card, vols = generate_cardiac_signals(duration, fs, hr)

            phantom = create_torso_phantom(
                64, 64, :axial; respiratory_signal=resp, cardiac_volumes=vols
            )
            @test size(phantom) == (64, 64, length(resp))
            @test eltype(phantom) == Float32

            # Test variation over time
            frame_diffs = [
                sum(abs.(phantom[:, :, i + 1] .- phantom[:, :, i])) for
                i in 1:(size(phantom, 3) - 1)
            ]
            @test all(frame_diffs .> 0)  # All frames should be different
        end
    end  # Dynamic Generation

    @testset "Integration Tests" begin
        @testset "2D phantom - Consistency with 3D" begin
            # Create 3D phantom
            phantom_3d = create_torso_phantom(64, 64, 64)

            # Create 2D slices at center positions
            phantom_2d_axial = create_torso_phantom(64, 64, :axial; slice_position=0.0)
            phantom_2d_coronal = create_torso_phantom(
                64, 64, :coronal; slice_position=0.0
            )
            phantom_2d_sagittal = create_torso_phantom(
                64, 64, :sagittal; slice_position=0.0
            )

            # Extract center slices from 3D
            center_idx = 33
            slice_3d_axial = phantom_3d[:, :, center_idx, 1]
            slice_3d_coronal = phantom_3d[:, center_idx, :, 1]
            slice_3d_sagittal = phantom_3d[center_idx, :, :, 1]

            # Check that non-zero counts are similar (within 10% due to discretization)
            nz_2d_axial = count(x -> x != 0, phantom_2d_axial[:, :, 1])
            nz_3d_axial = count(x -> x != 0, slice_3d_axial)
            @test abs(nz_2d_axial - nz_3d_axial) / max(nz_2d_axial, nz_3d_axial) < 0.10

            nz_2d_coronal = count(x -> x != 0, phantom_2d_coronal[:, :, 1])
            nz_3d_coronal = count(x -> x != 0, slice_3d_coronal)
            @test abs(nz_2d_coronal - nz_3d_coronal) /
                    max(nz_2d_coronal, nz_3d_coronal) < 0.10

            nz_2d_sagittal = count(x -> x != 0, phantom_2d_sagittal[:, :, 1])
            nz_3d_sagittal = count(x -> x != 0, slice_3d_sagittal)
            @test abs(nz_2d_sagittal - nz_3d_sagittal) /
                    max(nz_2d_sagittal, nz_3d_sagittal) < 0.10
        end

        @testset "2D phantom - TissueMask" begin
            # Test with lung mask
            lung_mask = TissueMask(lung=true)
            phantom_lung = create_torso_phantom(64, 64, :axial; ti=lung_mask)
            @test phantom_lung isa BitArray
            @test size(phantom_lung) == (64, 64, 1)
            @test any(phantom_lung)

            # Test with heart mask
            heart_mask = TissueMask(heart=true)
            phantom_heart = create_torso_phantom(64, 64, :coronal; ti=heart_mask)
            @test phantom_heart isa BitArray
            @test size(phantom_heart) == (64, 64, 1)
            @test any(phantom_heart)

            # Test with body mask
            body_mask = TissueMask(body=true)
            phantom_body = create_torso_phantom(64, 64, :sagittal; ti=body_mask)
            @test phantom_body isa BitArray
            @test size(phantom_body) == (64, 64, 1)
            @test any(phantom_body)
        end

        @testset "2D phantom - Different element types" begin
            # Test Float32 (default)
            phantom_f32 = create_torso_phantom(64, 64, :axial)
            @test eltype(phantom_f32) == Float32

            # Test Float64
            phantom_f64 = create_torso_phantom(64, 64, :axial; eltype=Float64)
            @test eltype(phantom_f64) == Float64
            @test phantom_f32 ≈ phantom_f64

            # Test ComplexF32
            phantom_c32 = create_torso_phantom(64, 64, :axial; eltype=ComplexF32)
            @test eltype(phantom_c32) == ComplexF32
            @test real(phantom_c32) ≈ phantom_f32

            # Test ComplexF64
            phantom_c64 = create_torso_phantom(64, 64, :axial; eltype=ComplexF64)
            @test eltype(phantom_c64) == ComplexF64
            @test real(phantom_c64) ≈ phantom_f64
        end

        @testset "2D phantom - Custom tissue intensities" begin
            ti_custom = TissueIntensities(lung=0.10, heart=0.70, body=0.30)
            phantom = create_torso_phantom(64, 64, :axial; ti=ti_custom)

            unique_vals = unique(phantom[:])
            @test any(x -> abs(x - 0.10f0) < 1e-5, unique_vals)  # Lung
            @test any(x -> abs(x - 0.70f0) < 1e-5, unique_vals)  # Heart
            @test any(x -> abs(x - 0.30f0) < 1e-5, unique_vals)  # Body
        end

        @testset "2D phantom - Error handling" begin
            # Test invalid axis
            @test_throws ArgumentError create_torso_phantom(64, 64, :invalid_axis)

            # Test wrong fovs size
            @test_throws ArgumentError create_torso_phantom(
                64, 64, :axial; fovs=(30, 30, 30)
            )

            # Test invalid dimensions
            @test_throws ArgumentError create_torso_phantom(-1, 64, :axial)
            @test_throws ArgumentError create_torso_phantom(64, 0, :axial)

            # Test signal length mismatch
            resp = [2.0, 3.0, 4.0]
            vols_short = (
                lv=[120.0, 140.0], rv=[120.0, 140.0], la=[50.0, 60.0], ra=[50.0, 60.0]
            )
            @test_throws ArgumentError create_torso_phantom(
                64, 64, :axial; respiratory_signal=resp, cardiac_volumes=vols_short
            )

            # Test missing cardiac volume fields
            vols_invalid = (lv=[140.0], rv=[140.0])
            @test_throws ArgumentError create_torso_phantom(
                64, 64, :axial; cardiac_volumes=vols_invalid
            )
        end

        @testset "2D phantom - Contains tissue types" begin
            phantom = create_torso_phantom(96, 96, :axial)
            ti = TissueIntensities()
            unique_vals = Set(real(phantom[:]))

            # Check for major tissue types (some may not appear in all slices)
            @test any(x -> abs(x - ti.lung) < 1e-6, unique_vals) ||
                any(x -> abs(x - ti.heart) < 1e-6, unique_vals) ||
                any(x -> abs(x - ti.body) < 1e-6, unique_vals)
        end

        @testset "2D phantom - All orientations with motion" begin
            # Generate motion signals
            duration = 1.0
            fs = 12.0
            rr = 15.0
            hr = 70.0
            t_resp, resp = generate_respiratory_signal(duration, fs, rr)
            t_card, vols = generate_cardiac_signals(duration, fs, hr)

            # Test all three orientations with both motion types
            for axis in [:axial, :coronal, :sagittal]
                phantom = create_torso_phantom(
                    64, 64, axis; respiratory_signal=resp, cardiac_volumes=vols
                )
                @test size(phantom) == (64, 64, length(resp))
                @test eltype(phantom) == Float32

                # Check for temporal variation
                @test !all(phantom[:, :, 1] .== phantom[:, :, end])
            end
        end
    end  # Integration Tests
end  # 2D Phantom Tests
