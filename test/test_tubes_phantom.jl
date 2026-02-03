using Test
using GeometricMedicalPhantoms

@testset "Tubes Phantom" begin
    
    @testset "3D phantom generation - default" begin
        # Test basic 3D phantom creation with default parameters
        phantom = create_tubes_phantom(64, 64, 64)
        @test size(phantom) == (64, 64, 64)
        @test eltype(phantom) == Float32
        @test all(phantom .>= 0.0)
        @test all(phantom .<= 1.0)
        # Default has 6 tubes arranged in outer cylinder
        @test maximum(phantom) > 0.0
    end
    
    @testset "3D phantom generation - custom FOV" begin
        # Test with custom FOV
        phantom = create_tubes_phantom(64, 64, 64; fovs=(20.0, 20.0, 20.0))
        @test size(phantom) == (64, 64, 64)
        @test eltype(phantom) == Float32
    end
    
    @testset "3D phantom generation - single tube" begin
        # Test with single tube (always feasible)
        ti = TubesIntensities(outer_cylinder=0.25, tube_wall=0.0, tube_fillings=[0.5])
        phantom = create_tubes_phantom(64, 64, 64; ti=ti)
        @test size(phantom) == (64, 64, 64)
        # Maximum should be at least 0.25 (outer cylinder) or 0.5 (tube filling)
        @test maximum(phantom) >= 0.2
    end
    
    @testset "3D phantom generation - three tubes" begin
        # Test with 3 tubes (feasible with default geometry)
        ti = TubesIntensities(outer_cylinder=0.25, tube_wall=0.0, tube_fillings=[0.2, 0.5, 0.9])
        phantom = create_tubes_phantom(64, 64, 64; ti=ti)
        @test size(phantom) == (64, 64, 64)
        @test maximum(phantom) >= 0.8
    end
    
    @testset "3D phantom - larger geometry" begin
        # Test with larger outer_radius and outer_height
        tg = TubesGeometry(outer_radius=0.6, outer_height=1.2)
        ti = TubesIntensities(outer_cylinder=0.25, tube_wall=0.0, tube_fillings=[0.5])
        phantom = create_tubes_phantom(64, 64, 64; tg=tg, ti=ti)
        @test size(phantom) == (64, 64, 64)
    end
    
    @testset "2D phantom - axial slice" begin
        # Test axial slice generation
        phantom_2d = create_tubes_phantom(64, 64, :axial)
        @test size(phantom_2d) == (64, 64)
        @test eltype(phantom_2d) == Float32
        @test all(phantom_2d .>= 0.0)
        @test all(phantom_2d .<= 1.0)
    end
    
    @testset "2D phantom - coronal slice" begin
        # Test coronal slice generation
        phantom_2d = create_tubes_phantom(64, 64, :coronal)
        @test size(phantom_2d) == (64, 64)
        @test eltype(phantom_2d) == Float32
    end
    
    @testset "2D phantom - sagittal slice" begin
        # Test sagittal slice generation
        phantom_2d = create_tubes_phantom(64, 64, :sagittal)
        @test size(phantom_2d) == (64, 64)
        @test eltype(phantom_2d) == Float32
    end
    
    @testset "2D phantom - slice position" begin
        # Test with different slice positions
        phantom_at_0 = create_tubes_phantom(64, 64, :axial; slice_position=0.0)
        phantom_at_2 = create_tubes_phantom(64, 64, :axial; slice_position=2.0)
        
        @test size(phantom_at_0) == (64, 64)
        @test size(phantom_at_2) == (64, 64)
    end
    
    @testset "Small geometry configuration" begin
        # Test that phantom works even with very small geometry
        tg = TubesGeometry(outer_radius=0.1, outer_height=0.2)
        ti = TubesIntensities(outer_cylinder=0.25, tube_wall=0.0, 
                              tube_fillings=collect(0.1:0.1:1.0))  # 10 tubes
        
        phantom = create_tubes_phantom(64, 64, 64; tg=tg, ti=ti)
        @test size(phantom) == (64, 64, 64)
        @test maximum(phantom) > 0.0
    end
    
    @testset "Intensity variations" begin
        # Test that different intensities produce different results
        ti_low = TubesIntensities(outer_cylinder=0.1, tube_wall=0.0, tube_fillings=[0.2])
        ti_high = TubesIntensities(outer_cylinder=0.9, tube_wall=0.0, tube_fillings=[1.0])
        
        phantom_low = create_tubes_phantom(64, 64, 64; ti=ti_low)
        phantom_high = create_tubes_phantom(64, 64, 64; ti=ti_high)
        
        @test maximum(phantom_low) < maximum(phantom_high)
    end
    
    @testset "Custom gap fraction" begin
        # Test different gap fractions (with single tube to ensure feasibility)
        ti = TubesIntensities(tube_fillings=[0.5])
        
        tg_small = TubesGeometry(gap_fraction=0.05)
        phantom_small = create_tubes_phantom(64, 64, 64; tg=tg_small, ti=ti)
        
        tg_large = TubesGeometry(gap_fraction=0.25)
        phantom_large = create_tubes_phantom(64, 64, 64; tg=tg_large, ti=ti)
        
        @test size(phantom_small) == (64, 64, 64)
        @test size(phantom_large) == (64, 64, 64)
    end

    @testset "3D phantom multi-intensities" begin
        ti_list = [
            TubesIntensities(outer_cylinder=0.2, tube_fillings=[0.1]),
            TubesIntensities(outer_cylinder=0.7, tube_fillings=[0.3]),
            TubesIntensities(outer_cylinder=0.9, tube_fillings=[0.8])
        ]
        phantom_stack = create_tubes_phantom(32, 32, 32; ti=ti_list)
        @test size(phantom_stack) == (32, 32, 32, length(ti_list))
        for (idx, ti) in enumerate(ti_list)
            single = create_tubes_phantom(32, 32, 32; ti=ti)
            @test phantom_stack[:, :, :, idx] ≈ single
        end
    end

    @testset "2D phantom multi-intensities" begin
        ti_list = [
            TubesIntensities(outer_cylinder=0.3, tube_fillings=[0.2]),
            TubesIntensities(outer_cylinder=0.6, tube_fillings=[0.4])
        ]
        phantom_stack = create_tubes_phantom(64, 64, :axial; ti=ti_list)
        @test size(phantom_stack) == (64, 64, length(ti_list))
        for (idx, ti) in enumerate(ti_list)
            single = create_tubes_phantom(64, 64, :axial; ti=ti)
            @test phantom_stack[:, :, idx] ≈ single
        end
    end
    
    @testset "Data type support - Float64" begin
        # Test generation with Float64 output
        phantom_f64 = create_tubes_phantom(32, 32, 32; eltype=Float64)
        @test eltype(phantom_f64) == Float64
        @test all(phantom_f64 .>= 0.0)
    end
    
    @testset "Data type support - Bool" begin
        # Boolean masks require special setup - using draw_pixel! with Bool arrays
        # For now, we test that eltype parameter works correctly
        phantom_f32 = create_tubes_phantom(32, 32, 32; eltype=Float32)
        phantom_f64 = create_tubes_phantom(32, 32, 32; eltype=Float64)
        
        @test eltype(phantom_f32) == Float32
        @test eltype(phantom_f64) == Float64
        # Values should be in same range
        @test maximum(phantom_f32) == Float32(maximum(phantom_f64))
    end
    
    @testset "Consistency - 2D from 3D" begin
        # Verify that 2D slices relate to 3D phantom
        tg = TubesGeometry(outer_radius=0.4, outer_height=0.8)
        ti = TubesIntensities(tube_fillings=[0.5])
        
        phantom_3d = create_tubes_phantom(64, 64, 64; tg=tg, ti=ti)
        phantom_2d = create_tubes_phantom(64, 64, :axial; tg=tg, ti=ti, slice_position=0.0)
        
        @test size(phantom_2d) == (64, 64)
        
        # Middle z slice of 3D should be non-zero (cylinder extends through)
        mid_z = div(size(phantom_3d, 3), 2)
        @test any(phantom_3d[:, :, mid_z] .> 0.0)
    end
    
    @testset "Parameter ranges" begin
        # Test with various parameter combinations
        phantom1 = create_tubes_phantom(32, 32, 32; fovs=(5.0, 5.0, 5.0))
        @test size(phantom1) == (32, 32, 32)
        
        phantom2 = create_tubes_phantom(32, 32, 32; fovs=(15.0, 15.0, 15.0))
        @test size(phantom2) == (32, 32, 32)
        
        phantom3 = create_tubes_phantom(32, 32, :axial; fovs=(10.0, 10.0))
        @test size(phantom3) == (32, 32)
    end
    
end
