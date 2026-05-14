using GeometricMedicalPhantomsApp
using Aqua
using Test

@testset "Aqua" begin
    Aqua.test_all(
        GeometricMedicalPhantomsApp;
        ambiguities = false, # Exclude ambiguities since this is an application module with limited exports
        persistent_tasks = false # Skip testing for persistent tasks because false positives are common
    )
end
