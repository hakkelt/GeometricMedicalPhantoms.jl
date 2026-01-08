@testset "generate_respiratory_signal" begin
    # Test basic parameters: duration and fs
    @testset "Time vector length and sampling" begin
        duration = 10.0
        fs = 100.0
        rr = 15.0
        
        t, resp_L = generate_respiratory_signal(duration, fs, rr)
        
        expected_length = Int(duration * fs)
        @test length(t) == expected_length
        @test length(resp_L) == expected_length
        
        # Check time vector starts at 0 and has correct spacing
        @test t[1] ≈ 0.0
        @test t[end] ≈ duration - 1/fs
        @test all(diff(t) .≈ 1/fs)
    end
    
    # Test respiratory rate (rr)
    @testset "Respiratory rate" begin
        duration = 60.0  # 1 minute
        fs = 100.0
        rr = 15.0  # 15 breaths per minute
        
        t, resp_L = generate_respiratory_signal(duration, fs, rr)
        
        # Count number of peaks (breaths) using zero-crossings of derivative
        num_peaks = count_peaks(resp_L)
        
        # Allow some tolerance due to modulation and harmonics
        # Should be approximately rr breaths in 1 minute
        @test num_peaks >= rr - 2
        @test num_peaks <= rr + 2
    end
    
    # Test minL/maxL from RespiratoryPhysiology
    @testset "Volume range from RespiratoryPhysiology" begin
        duration = 10.0
        fs = 100.0
        rr = 15.0
        
        # Test with default physiology
        phys_default = RespiratoryPhysiology()
        t, resp_L = generate_respiratory_signal(duration, fs, rr; physiology=phys_default)
        
        @test minimum(resp_L) >= phys_default.minL
        @test maximum(resp_L) <= phys_default.maxL
        @test minimum(resp_L) ≈ phys_default.minL atol=0.01
        @test maximum(resp_L) ≈ phys_default.maxL atol=0.01
        
        # Test with custom physiology
        phys_custom = RespiratoryPhysiology(minL=1.5, maxL=4.5)
        t2, resp_L2 = generate_respiratory_signal(duration, fs, rr; physiology=phys_custom)
        
        @test minimum(resp_L2) >= phys_custom.minL
        @test maximum(resp_L2) <= phys_custom.maxL
        @test minimum(resp_L2) ≈ phys_custom.minL atol=0.01
        @test maximum(resp_L2) ≈ phys_custom.maxL atol=0.01
        
        # Verify custom range is different from default
        @test !isapprox(minimum(resp_L2), minimum(resp_L), atol=0.1)
        @test !isapprox(maximum(resp_L2), maximum(resp_L), atol=0.1)
    end
    
    # Test with different respiratory rates
    @testset "Different respiratory rates" begin
        duration = 30.0
        fs = 100.0
        
        # Test slow breathing
        rr_slow = 10.0
        t_slow, resp_slow = generate_respiratory_signal(duration, fs, rr_slow)
        
        # Test fast breathing
        rr_fast = 20.0
        t_fast, resp_fast = generate_respiratory_signal(duration, fs, rr_fast)
        
        # Both should have same length based on duration and fs
        @test length(resp_slow) == length(resp_fast)
        
        # Fast breathing should have more zero-crossings
        crossings_slow = count_zero_crossings(resp_slow)
        crossings_fast = count_zero_crossings(resp_fast)
        @test crossings_fast == crossings_slow * 2
    end
    
    # Test signal properties
    @testset "Signal properties" begin
        duration = 20.0
        fs = 100.0
        rr = 15.0
        
        t, resp_L = generate_respiratory_signal(duration, fs, rr)
        
        # Signal should be continuous (no NaN or Inf)
        @test all(isfinite.(resp_L))
        
        # Signal should vary (not constant)
        std_resp = std(resp_L)
        @test std_resp > 0.0
        
        # Signal should be smooth (no abrupt jumps)
        @test maximum(abs.(diff(resp_L))) < 0.5  # No jump larger than 0.5L per sample
    end
    
    # Test default arguments
    @testset "Default arguments" begin
        # Should work with all defaults
        t, resp_L = generate_respiratory_signal()
        @test length(t) == 60.0 * 50.0
        @test all(isfinite.(resp_L))
    end
end
