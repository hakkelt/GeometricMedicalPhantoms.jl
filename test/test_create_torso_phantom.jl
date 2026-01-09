using Test
using GeometricMedicalPhantoms
using Statistics

@testset "create_torso_phantom" begin
    @testset "Basic 3D phantom generation" begin
        # Test default parameters (static 3D phantom)
        phantom = create_torso_phantom()
        @test size(phantom) == (128, 128, 128, 1)
        @test eltype(phantom) == Float32
        
        # Test custom dimensions
        phantom = create_torso_phantom(64, 64, 64)
        @test size(phantom) == (64, 64, 64, 1)
        
        # Test that phantom contains expected intensity values
        phantom = create_torso_phantom(64, 64, 64)
        unique_vals = unique(phantom[:])
        @test 0.0f0 in unique_vals  # Background
        @test any(x -> 0.07f0 < x < 0.12f0, unique_vals)  # Lung tissue
    end
    
    @testset "3D phantom with custom FOV" begin
        # 64^3 with FOV (20, 20, 20) should equal center of 128^3 with FOV (40, 40, 40)
        # Both have same voxel size: 20/64 = 40/128 = 0.3125 cm/voxel
        phantom_small = create_torso_phantom(64, 64, 64; fovs=(20, 20, 20))
        phantom_large = create_torso_phantom(128, 128, 128; fovs=(40, 40, 40))
        
        @test size(phantom_small) == (64, 64, 64, 1)
        @test size(phantom_large) == (128, 128, 128, 1)
        
        # Extract center 64x64x64 from the 128x128x128 phantom
        center_start = 33  # (128 - 64) / 2 + 1
        center_end = 96    # center_start + 64 - 1
        phantom_large_center = phantom_large[center_start:center_end, center_start:center_end, center_start:center_end, 1]
        
        # The two should be identical (or very close due to numerical precision)
        @test size(phantom_large_center) == (64, 64, 64)
        @test phantom_small[:, :, :, 1] ≈ phantom_large_center
    end
    
    @testset "3D phantom with custom tissue intensities" begin
        # Test custom intensities with masking
        ti_custom = TissueIntensities(lung=0.10, heart=0.70, body=0.30, lv_blood=0.95)
        phantom_custom = create_torso_phantom(64, 64, 64; ti=ti_custom)
        @test size(phantom_custom) == (64, 64, 64, 1)
        
        # Test each tissue type with binary mask
        tissue_types = [:lung, :heart, :body, :lv_blood]
        
        for tissue in tissue_types
            # Create binary mask for this tissue type using TissueMask
            mask_kwargs = Dict{Symbol, Bool}()
            for f in fieldnames(TissueMask)
                mask_kwargs[f] = (f == tissue)
            end
            ti_mask = TissueMask(; mask_kwargs...)
            phantom_mask = create_torso_phantom(64, 64, 64; ti=ti_mask)
            
            # Get the mask (where this tissue exists) - phantom_mask is now BitArray
            mask = phantom_mask[:, :, :, 1]
            
            # Get the custom intensity value for this tissue
            custom_intensity = getfield(ti_custom, tissue)
            
            # Check that the custom intensity appears only where the mask indicates
            frame_custom = phantom_custom[:, :, :, 1]
            
            # All voxels with the mask should have the custom intensity (with tolerance)
            if any(mask)
                masked_values = frame_custom[mask]
                @test all(x -> abs(x - custom_intensity) < 1e-5, masked_values)
            end
            
            # All voxels with the custom intensity should be in the mask
            intensity_positions = abs.(frame_custom .- custom_intensity) .< 1e-5
            if any(intensity_positions)
                @test all(intensity_positions .== mask)
            end
        end
    end
    
    @testset "4D phantom with respiratory signal" begin
        duration = 2.0
        fs = 12.0
        rr = 15.0
        t, resp = generate_respiratory_signal(duration, fs, rr)
        
        phantom = create_torso_phantom(64, 64, 64; respiratory_signal=resp)
        @test size(phantom, 4) == length(resp)
        @test size(phantom)[1:3] == (64, 64, 64)
        @test eltype(phantom) == Float32
        
        # Test that different frames have different content (due to breathing)
        frame1 = phantom[:, :, :, 1]
        frame_mid = phantom[:, :, :, div(length(resp), 2)]
        @test !all(frame1 .== frame_mid)
    end
    
    @testset "4D phantom with cardiac volumes" begin
        duration = 2.0
        fs = 12.0
        hr = 70.0
        t, vols = generate_cardiac_signals(duration, fs, hr)
        
        phantom = create_torso_phantom(64, 64, 64; cardiac_volumes=vols)
        @test size(phantom, 4) == length(vols.lv)
        @test size(phantom)[1:3] == (64, 64, 64)
        @test eltype(phantom) == Float32
        
        # Test that different frames have different content (due to cardiac motion)
        frame1 = phantom[:, :, :, 1]
        frame_mid = phantom[:, :, :, div(length(vols.lv), 2)]
        @test !all(frame1 .== frame_mid)
    end
    
    @testset "4D phantom with both respiratory and cardiac signals" begin
        duration = 2.0
        fs = 12.0
        rr = 15.0
        hr = 70.0
        t_resp, resp = generate_respiratory_signal(duration, fs, rr)
        t_card, vols = generate_cardiac_signals(duration, fs, hr)
        
        @test length(resp) == length(vols.lv)
        
        phantom = create_torso_phantom(64, 64, 64; respiratory_signal=resp, cardiac_volumes=vols)
        @test size(phantom, 4) == length(resp)
        @test size(phantom)[1:3] == (64, 64, 64)
        @test eltype(phantom) == Float32
    end
    
    @testset "Lung volume validation - realistic signal" begin
        # Generate respiratory signal with known range
        duration = 4.0
        fs = 24.0
        rr = 15.0
        t, resp = generate_respiratory_signal(duration, fs, rr)
        
        # Create phantom with moderate resolution for faster computation
        nx, ny, nz = 128, 128, 128
        fov = (30, 30, 30)
        phantom = create_torso_phantom(nx, ny, nz; respiratory_signal=resp)
        
        lung_vol_L = zeros(Float64, length(resp))
        
        # Calculate lung volumes using utility function
        for m in 1:length(resp)
            frame = phantom[:, :, :, m]
            lung_vol_L[m] = calculate_volume(frame, (0.075f0, 0.11f0), fov)
        end
        
        @test all(lung_vol_L .> 0)
        @test minimum(lung_vol_L) < maximum(lung_vol_L)
        
        # Test correlation between lung volume and respiratory signal
        function corr(x, y)
            xm = mean(x)
            ym = mean(y)
            num = sum((x .- xm) .* (y .- ym))
            den = sqrt(sum((x .- xm).^2) * sum((y .- ym).^2))
            return num / den
        end
        
        correlation = corr(lung_vol_L, Float64.(resp))
        @test correlation > 0.999  # Strong positive correlation
        
        # Test that lung volumes are in reasonable range relative to respiratory signal
        # Strict error threshold for realistic signal (physiologically plausible breathing)
        realistic_signal_median_threshold = 0.0052
        realistic_signal_max_threshold = 0.01
        
        rel_errors = abs.(lung_vol_L .- resp) ./ resp
        median_error = median(rel_errors)
        max_error = maximum(rel_errors)
        
        @test median_error < realistic_signal_median_threshold
        @test max_error < realistic_signal_max_threshold
    end
    
    @testset "Lung volume validation - full range" begin
        # Test over entire physiological range (1.2L to 6.0L)
        # Sample the full range with multiple volume levels
        volume_levels = range(1.2, 6.0, length=25)
        nt = length(volume_levels)
        resp_full_range = collect(volume_levels)
        
        # Create phantom
        nx, ny, nz = 96, 96, 96
        fov = (30, 30, 30)
        phantom = create_torso_phantom(nx, ny, nz; respiratory_signal=resp_full_range)
        
        lung_vol_L = zeros(Float64, nt)
        
        # Calculate lung volumes using utility function
        for m in 1:nt
            frame = phantom[:, :, :, m]
            lung_vol_L[m] = calculate_volume(frame, (0.075f0, 0.11f0), fov)
        end
        
        @test all(lung_vol_L .> 0)
        @test minimum(lung_vol_L) < maximum(lung_vol_L)
        
        # Test correlation - should be very high for full range
        correlation = cor(lung_vol_L, resp_full_range)
        @test correlation > 0.998  # Strong correlation over full range
        
        # Test error thresholds for full range
        # Full range has more extreme volumes so allow slightly higher errors
        full_range_median_threshold = 0.025
        full_range_max_threshold = 0.051
        
        rel_errors = abs.(lung_vol_L .- resp_full_range) ./ resp_full_range
        median_error = median(rel_errors)
        max_error = maximum(rel_errors)
        
        @test median_error < full_range_median_threshold
        @test max_error < full_range_max_threshold
    end
    
    @testset "Cardiac chamber volume validation" begin
        # Generate cardiac signals with known volumes
        duration = 3.0
        fs = 24.0
        hr = 70.0
        t, vols = generate_cardiac_signals(duration, fs, hr)
        
        # Create phantom
        nx, ny, nz = 96, 96, 96
        phantom = create_torso_phantom(nx, ny, nz; cardiac_volumes=vols)
        
        ti = TissueIntensities()
        nt = length(vols.lv)
        
        # Helper to count voxels with specific intensity
        function count_intensity(frame, val)
            return count(x -> abs(real(x) - val) < 1f-6, frame)
        end
        
        lv_meas_mL = zeros(Float64, nt)
        rv_meas_mL = zeros(Float64, nt)
        la_meas_mL = zeros(Float64, nt)
        ra_meas_mL = zeros(Float64, nt)
        
        voxel_vol_mL = (30/nx) * (30/ny) * (30/nz)
        
        for m in 1:nt
            frame = phantom[:, :, :, m]
            lv_meas_mL[m] = count_intensity(frame, ti.lv_blood) * voxel_vol_mL
            rv_meas_mL[m] = count_intensity(frame, ti.rv_blood) * voxel_vol_mL
            la_meas_mL[m] = count_intensity(frame, ti.la_blood) * voxel_vol_mL
            ra_meas_mL[m] = count_intensity(frame, ti.ra_blood) * voxel_vol_mL
        end
        
        # Test that all chambers have non-zero volumes
        @test all(lv_meas_mL .> 0)
        @test all(rv_meas_mL .> 0)
        @test all(la_meas_mL .> 0)
        @test all(ra_meas_mL .> 0)
        
        # Test that volumes vary over time (cardiac motion)
        @test std(lv_meas_mL) > 0
        @test std(rv_meas_mL) > 0
        @test std(la_meas_mL) > 0
        @test std(ra_meas_mL) > 0
        
        # Test that measured volumes track expected volumes with high accuracy
        lv_err = abs.(lv_meas_mL .- vols.lv) ./ maximum(vols.lv)
        rv_err = abs.(rv_meas_mL .- vols.rv) ./ maximum(vols.rv)
        la_err = abs.(la_meas_mL .- vols.la) ./ maximum(vols.la)
        ra_err = abs.(ra_meas_mL .- vols.ra) ./ maximum(vols.ra)
        
        # Test that all frames have excellent accuracy (< 5% error)
        @test count(<(0.05), lv_err) == nt  # All frames under 5%
        @test count(<(0.05), rv_err) == nt
        @test count(<(0.05), la_err) == nt
        @test count(<(0.05), ra_err) == nt
        
        # Test that maximum errors are tightly bounded
        @test maximum(lv_err) < 0.04   # Measured: 3.64%
        @test maximum(rv_err) < 0.02   # Measured: 1.76%
        @test maximum(la_err) < 0.04   # Measured: 3.67%
        @test maximum(ra_err) < 0.03   # Measured: 2.57%
    end
    
    @testset "Signal length mismatch handling" begin
        duration = 2.0
        fs = 12.0
        t_resp, resp = generate_respiratory_signal(duration, fs, 15.0)
        t_card, vols = generate_cardiac_signals(duration, fs, 70.0)
        
        # Modify cardiac volumes to have different length
        vols_short = (lv=vols.lv[1:end-2], rv=vols.rv[1:end-2], 
                      la=vols.la[1:end-2], ra=vols.ra[1:end-2])
        
        @test_throws ArgumentError create_torso_phantom(64, 64, 64; 
            respiratory_signal=resp, cardiac_volumes=vols_short)
    end
    
    @testset "Missing cardiac volume fields" begin
        duration = 2.0
        fs = 12.0
        t, resp = generate_respiratory_signal(duration, fs, 15.0)
        
        # Create invalid cardiac volumes (missing fields)
        vols_invalid = (lv=fill(140.0, length(resp)), rv=fill(140.0, length(resp)))
        
        @test_throws ArgumentError create_torso_phantom(64, 64, 64; 
            respiratory_signal=resp, cardiac_volumes=vols_invalid)
    end
    
    @testset "Phantom contains all tissue types" begin
        phantom = create_torso_phantom(96, 96, 96)
        ti = TissueIntensities()
        frame = phantom[:, :, :, 1]
        unique_vals = Set(real(frame[:]))
        
        # Check for presence of major tissue types
        @test any(x -> abs(x - ti.lung) < 1e-6, unique_vals)        # Lung
        @test any(x -> abs(x - ti.heart) < 1e-6, unique_vals)       # Heart
        @test any(x -> abs(x - ti.body) < 1e-6, unique_vals)        # Body
        @test any(x -> abs(x - ti.bones) < 1e-6, unique_vals)       # Bones
        @test any(x -> abs(x - ti.lv_blood) < 1e-6, unique_vals)    # LV blood
        @test any(x -> abs(x - ti.rv_blood) < 1e-6, unique_vals)    # RV blood
        @test any(x -> abs(x - ti.la_blood) < 1e-6, unique_vals)    # LA blood
        @test any(x -> abs(x - ti.ra_blood) < 1e-6, unique_vals)    # RA blood
        @test any(x -> abs(x - ti.liver) < 1e-6, unique_vals)       # Liver
        @test any(x -> abs(x - ti.stomach) < 1e-6, unique_vals)     # Stomach
    end
    
    @testset "TissueMask" begin
        # Test that TissueMask can be created
        lung_mask = TissueMask(lung=true)
        @test lung_mask.lung == true
        @test lung_mask.heart == false
        
        # Test that phantoms created with TissueMask are BitArrays
        phantom_mask = create_torso_phantom(64, 64, 64; ti=lung_mask)
        @test phantom_mask isa BitArray
        @test size(phantom_mask) == (64, 64, 64, 1)
        
        # Test that mask contains only true/false
        @test all(x -> x in (true, false), phantom_mask)
        @test any(phantom_mask)  # Should have some true values
    end
    
    @testset "eltype parameter - Float32 (default)" begin
        # Test default eltype is Float32
        phantom = create_torso_phantom(64, 64, 64)
        @test eltype(phantom) == Float32
        @test size(phantom) == (64, 64, 64, 1)
        
        # Test explicit Float32
        phantom_f32 = create_torso_phantom(64, 64, 64; eltype=Float32)
        @test eltype(phantom_f32) == Float32
        @test size(phantom_f32) == (64, 64, 64, 1)
        
        # Results should be identical
        @test phantom ≈ phantom_f32
    end
    
    @testset "eltype parameter - Float64" begin
        # Test Float64 eltype
        phantom_f64 = create_torso_phantom(64, 64, 64; eltype=Float64)
        @test eltype(phantom_f64) == Float64
        @test size(phantom_f64) == (64, 64, 64, 1)
        
        # Test that phantom contains expected intensity values (Float64 precision)
        unique_vals = unique(phantom_f64[:])
        @test 0.0 in unique_vals  # Background
        @test any(x -> 0.07 < x < 0.12, unique_vals)  # Lung tissue
        
        # Test that Float64 and Float32 phantoms have similar (but not identical) values
        phantom_f32 = create_torso_phantom(64, 64, 64; eltype=Float32)
        @test phantom_f32 ≈ phantom_f64
        
        # Verify they are different types
        @test eltype(phantom_f32) != eltype(phantom_f64)
    end
    
    @testset "eltype parameter - ComplexF32" begin
        # Test ComplexF32 eltype
        phantom_complex = create_torso_phantom(64, 64, 64; eltype=ComplexF32)
        @test eltype(phantom_complex) == ComplexF32
        @test size(phantom_complex) == (64, 64, 64, 1)
        
        # Test that phantom contains expected intensity values
        unique_vals = unique(real(phantom_complex[:]))
        @test 0.0f0 in unique_vals  # Background
        @test any(x -> 0.07f0 < x < 0.12f0, unique_vals)  # Lung tissue
    end
    
    @testset "eltype parameter - ComplexF64" begin
        # Test ComplexF64 eltype
        phantom_complex_f64 = create_torso_phantom(64, 64, 64; eltype=ComplexF64)
        @test eltype(phantom_complex_f64) == ComplexF64
        @test size(phantom_complex_f64) == (64, 64, 64, 1)
        
        # Test that phantom contains expected intensity values
        unique_vals = unique(real(phantom_complex_f64[:]))
        @test 0.0 in unique_vals  # Background
        @test any(x -> 0.07 < x < 0.12, unique_vals)  # Lung tissue
    end
    
    @testset "eltype parameter - 4D phantom with Float64" begin
        duration = 2.0
        fs = 12.0
        rr = 15.0
        t, resp = generate_respiratory_signal(duration, fs, rr)
        
        phantom_f64 = create_torso_phantom(64, 64, 64; respiratory_signal=resp, eltype=Float64)
        @test eltype(phantom_f64) == Float64
        @test size(phantom_f64, 4) == length(resp)
        @test size(phantom_f64)[1:3] == (64, 64, 64)
        
        # Test that different frames have different content (due to breathing)
        frame1 = phantom_f64[:, :, :, 1]
        frame_mid = phantom_f64[:, :, :, div(length(resp), 2)]
        @test !all(frame1 .== frame_mid)
    end
    
    @testset "eltype parameter - custom tissue intensities with Float64" begin
        # Test that Float64 custom intensities work with Float64 eltype
        ti_custom = TissueIntensities(lung=0.10, heart=0.70, body=0.30, lv_blood=0.95)
        phantom_f64 = create_torso_phantom(64, 64, 64; ti=ti_custom, eltype=Float64)
        @test eltype(phantom_f64) == Float64
        
        # Test each tissue type with binary mask
        tissue_types = [:lung, :heart, :body, :lv_blood]
        
        for tissue in tissue_types
            # Create binary mask for this tissue type using TissueMask
            mask_kwargs = Dict{Symbol, Bool}()
            for f in fieldnames(TissueMask)
                mask_kwargs[f] = (f == tissue)
            end
            ti_mask = TissueMask(; mask_kwargs...)
            phantom_mask = create_torso_phantom(64, 64, 64; ti=ti_mask)
            
            # Get the mask (where this tissue exists) - phantom_mask is now BitArray
            mask = phantom_mask[:, :, :, 1]
            
            # Get the custom intensity value for this tissue
            custom_intensity = getfield(ti_custom, tissue)
            
            # Check that the custom intensity appears only where the mask indicates
            frame_custom = phantom_f64[:, :, :, 1]
            
            # All voxels with the mask should have the custom intensity (with tolerance)
            if any(mask)
                masked_values = frame_custom[mask]
                @test all(x -> abs(x - custom_intensity) < 1e-5, masked_values)
            end
            
            # All voxels with the custom intensity should be in the mask
            intensity_positions = abs.(frame_custom .- custom_intensity) .< 1e-5
            if any(intensity_positions)
                @test all(intensity_positions .== mask)
            end
        end
    end
end
