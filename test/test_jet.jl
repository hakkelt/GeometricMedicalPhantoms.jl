using JET
using Test
using GeometricMedicalPhantoms

@testset "JET static analysis" begin
    # Skip JET tests on pre-release Julia versions
    if VERSION.prerelease == ()
        # Run JET.jl static analysis on the package
        # target_modules=(GeometricMedicalPhantoms,) ensures we only analyze this package
        JET.test_package(
            GeometricMedicalPhantoms;
            target_modules=(GeometricMedicalPhantoms,)
        )
    else
        @info "Skipping JET tests on Julia pre-release version $(VERSION)"
    end
end
