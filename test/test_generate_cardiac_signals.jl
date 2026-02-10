using Test
using GeometricMedicalPhantoms
using Statistics

if !isdefined(Main, :utils_included)
    include("utils.jl")
end

@testset "generate_cardiac_signals" begin
    # Test basic parameters: duration and fs
    @testset "Time vector length and sampling" begin
        duration = 10.0
        fs = 500.0
        hr = 70.0

        t, vols = generate_cardiac_signals(duration, fs, hr)

        expected_length = Int(duration * fs)
        @test length(t) == expected_length
        @test length(vols.lv) == expected_length
        @test length(vols.rv) == expected_length
        @test length(vols.la) == expected_length
        @test length(vols.ra) == expected_length
        @test length(keys(vols)) == 4

        # Check time vector starts at 0 and has correct spacing
        @test t[1] ≈ 0.0
        @test t[end] ≈ duration - 1 / fs
        @test all(diff(t) .≈ 1 / fs)
    end

    # Test heart rate (hr)
    @testset "Heart rate" begin
        duration = 60.0  # 1 minute
        fs = 500.0
        hr = 60.0  # 60 beats per minute

        t, vols = generate_cardiac_signals(duration, fs, hr)

        # Count number of peaks in LV (ventricle should have clear systole/diastole cycles)
        num_peaks = count_peaks(vols.lv)

        # Allow some tolerance due to modulation
        # Should be approximately hr beats in 1 minute
        @test num_peaks >= hr - 5
        @test num_peaks <= hr + 5
    end

    # Test volume ranges from CardiacPhysiology
    @testset "Volume ranges from CardiacPhysiology" begin
        duration = 10.0
        fs = 500.0
        hr = 70.0

        # Test with default physiology
        phys_default = CardiacPhysiology()
        t, vols = generate_cardiac_signals(duration, fs, hr; physiology = phys_default)

        # Left ventricle should range between ESV and EDV
        @test minimum(vols.lv) >= phys_default.lv_esv - 10  # tolerance for baseline wander
        @test maximum(vols.lv) <= phys_default.lv_edv + 10

        # Right ventricle should range between ESV and EDV
        @test minimum(vols.rv) >= phys_default.rv_esv - 10
        @test maximum(vols.rv) <= phys_default.rv_edv + 10

        # Left atrium should range between min and max
        @test minimum(vols.la) >= phys_default.la_min - 10
        @test maximum(vols.la) <= phys_default.la_max + 10

        # Right atrium should range between min and max
        @test minimum(vols.ra) >= phys_default.ra_min - 10
        @test maximum(vols.ra) <= phys_default.ra_max + 10

        # Test with custom physiology
        phys_custom = CardiacPhysiology(
            lv_edv = 150.0, lv_esv = 60.0,
            rv_edv = 160.0, rv_esv = 70.0,
            la_min = 25.0, la_max = 70.0,
            ra_min = 25.0, ra_max = 70.0
        )
        t2, vols2 = generate_cardiac_signals(duration, fs, hr; physiology = phys_custom)

        @test minimum(vols2.lv) >= phys_custom.lv_esv - 10
        @test maximum(vols2.lv) <= phys_custom.lv_edv + 10
        @test minimum(vols2.rv) >= phys_custom.rv_esv - 10
        @test maximum(vols2.rv) <= phys_custom.rv_edv + 10

        # Verify custom range produces different volumes
        @test !isapprox(maximum(vols2.lv), maximum(vols.lv), atol = 5.0)
    end

    # Test different heart rates
    @testset "Different heart rates" begin
        duration = 30.0
        fs = 500.0

        # Test slow heart rate
        hr_slow = 50.0
        t_slow, vols_slow = generate_cardiac_signals(duration, fs, hr_slow)

        # Test fast heart rate
        hr_fast = 100.0
        t_fast, vols_fast = generate_cardiac_signals(duration, fs, hr_fast)

        # Both should have same length based on duration and fs
        @test length(vols_slow.lv) == length(vols_fast.lv)

        # Fast heart rate should have more cycles (more zero-crossings)
        crossings_slow = count_zero_crossings(vols_slow.lv)
        crossings_fast = count_zero_crossings(vols_fast.lv)
        @test crossings_fast == crossings_slow * 2
    end

    # Test signal properties
    @testset "Signal properties" begin
        duration = 10.0
        fs = 500.0
        hr = 70.0

        t, vols = generate_cardiac_signals(duration, fs, hr)

        # All signals should be continuous (no NaN or Inf)
        @test all(isfinite.(vols.lv))
        @test all(isfinite.(vols.rv))
        @test all(isfinite.(vols.la))
        @test all(isfinite.(vols.ra))

        # All signals should vary (not constant)
        std_lv = std(vols.lv)
        @test std_lv > 0.0

        std_rv = std(vols.rv)
        @test std_rv > 0.0

        # Signals should be smooth (no abrupt jumps)
        @test maximum(abs.(diff(vols.lv))) < 10.0  # No jump larger than 10mL per sample
        @test maximum(abs.(diff(vols.rv))) < 10.0
        @test maximum(abs.(diff(vols.la))) < 10.0
        @test maximum(abs.(diff(vols.ra))) < 10.0
    end

    # Test physiological relationship: ventricles vs atria
    @testset "Ventricle-atrium phase relationship" begin
        duration = 10.0
        fs = 500.0
        hr = 70.0

        t, vols = generate_cardiac_signals(duration, fs, hr)

        # Ventricles and atria should be roughly in opposite phase
        # When ventricles are filling (diastole, high volume),
        # atria are emptying (low volume), and vice versa

        # Calculate correlation - should be negative or weakly positive
        mean_lv = mean(vols.lv)
        mean_la = mean(vols.la)

        centered_lv = vols.lv .- mean_lv
        centered_la = vols.la .- mean_la

        covariance = sum(centered_lv .* centered_la) / length(vols.lv)
        std_lv = sqrt(sum(centered_lv .^ 2) / length(vols.lv))
        std_la = sqrt(sum(centered_la .^ 2) / length(vols.la))
        correlation = covariance / (std_lv * std_la)

        # Correlation should not be strongly positive (they're out of phase)
        @test correlation < 0.5
    end

    # Test default arguments
    @testset "Default arguments" begin
        # Should work with all defaults
        t, vols = generate_cardiac_signals()
        @test length(t) == 10.0 * 500.0
        @test all(isfinite.(vols.lv))
        @test all(isfinite.(vols.rv))
        @test all(isfinite.(vols.la))
        @test all(isfinite.(vols.ra))
    end
end
