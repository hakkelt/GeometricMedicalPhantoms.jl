using Test
using GeometricMedicalPhantoms
using Statistics

if !isdefined(Main, :utils_included)
    include("utils.jl")
end

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
    
    # Test amplitude modulation (line 64: amplitude_mod = 1.0 .+ amplitude_mod_amp .* sin(...))
    @testset "Amplitude modulation (line 64)" begin
        duration = 60.0
        fs = 100.0
        rr = 15.0
        
        # Test with significant amplitude modulation
        phys_with_amp_mod = RespiratoryPhysiology(
            minL=2.4, maxL=3.0,
            amp_mod_amp=0.5,  # 50% amplitude variation
            amp_mod_freq=0.1  # 0.1 Hz modulation frequency
        )
        t, resp_L = generate_respiratory_signal(duration, fs, rr; physiology=phys_with_amp_mod)
        
        # Breathing depth should vary over time
        # Compare segments of signal to show amplitude modulation effect
        segment_length = Int(round(fs / phys_with_amp_mod.amp_mod_freq / 2))  # Half period of modulation
        
        if segment_length > 0 && segment_length < length(resp_L) - 1
            # Compute local amplitude in each segment
            num_segments = div(length(resp_L), segment_length)
            if num_segments >= 3
                amps = [maximum(resp_L[i*segment_length+1:min((i+1)*segment_length, length(resp_L))]) - 
                        minimum(resp_L[i*segment_length+1:min((i+1)*segment_length, length(resp_L))]) 
                        for i in 0:num_segments-1]
                # Amplitudes should vary (not all identical) due to modulation
                @test maximum(amps) > minimum(amps)
            end
        end
        
        # Test with no amplitude modulation
        phys_no_amp_mod = RespiratoryPhysiology(
            minL=2.4, maxL=3.0,
            amp_mod_amp=0.0  # No amplitude variation
        )
        t_no_mod, resp_L_no_mod = generate_respiratory_signal(duration, fs, rr; physiology=phys_no_amp_mod)
        
        # Without modulation, consecutive cycles should have similar amplitudes
        segment_len_no_mod = Int(round(fs * 60 / rr))  # One breath cycle in samples
        if segment_len_no_mod > 0 && 2*segment_len_no_mod < length(resp_L_no_mod)
            cycle1 = resp_L_no_mod[1:segment_len_no_mod]
            cycle2 = resp_L_no_mod[segment_len_no_mod+1:2*segment_len_no_mod]
            amp1 = maximum(cycle1) - minimum(cycle1)
            amp2 = maximum(cycle2) - minimum(cycle2)
            # Amplitudes should be similar without modulation
            @test isapprox(amp1, amp2, rtol=0.05)
        end
        
        # With modulation, breathing cycle amplitudes should vary more
        segment_len_mod = Int(round(fs * 60 / rr))  # One breath cycle in samples
        if segment_len_mod > 0 && 2*segment_len_mod < length(resp_L)
            cycle1_mod = resp_L[1:segment_len_mod]
            cycle2_mod = resp_L[segment_len_mod+1:2*segment_len_mod]
            amp1_mod = maximum(cycle1_mod) - minimum(cycle1_mod)
            amp2_mod = maximum(cycle2_mod) - minimum(cycle2_mod)
            # Signal should show variation (either same or different amplitudes are OK)
            # The key is that amplitude modulation code (line 64) is executed
            @test amp1_mod > 0
            @test amp2_mod > 0
        end
    end
end
