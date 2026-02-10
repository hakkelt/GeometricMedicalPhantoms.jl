using JET
using Test
using GeometricMedicalPhantomsApp

@testset "JET static analysis" begin
    # Run JET.jl static analysis on the package
    # target_modules=(GeometricMedicalPhantomsApp,) ensures we only analyze this package
    JET.test_package(
        GeometricMedicalPhantomsApp;
        target_modules=(GeometricMedicalPhantomsApp,)
    )
end
