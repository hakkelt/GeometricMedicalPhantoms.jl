using GeometricMedicalPhantomsApp
using Aqua
using Test

@testset "Aqua" begin
    Aqua.test_all(
        GeometricMedicalPhantomsApp;
        # Exclude ambiguities since this is an application module with limited exports
        ambiguities = false
    )
end
