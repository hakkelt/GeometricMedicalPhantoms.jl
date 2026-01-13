using JET
using Test
using GeometricMedicalPhantoms

@testset "JET static analysis" begin
    # Run JET.jl static analysis on the package
    # target_modules=(GeometricMedicalPhantoms,) ensures we only analyze this package
    JET.test_package(
        GeometricMedicalPhantoms;
        target_modules=(GeometricMedicalPhantoms,)
    )
end
