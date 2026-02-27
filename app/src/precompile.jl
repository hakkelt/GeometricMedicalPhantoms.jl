using GeometricMedicalPhantomsApp

# Precompile common CLI operations
redirect_stdout(devnull) do
    redirect_stderr(devnull) do
        GeometricMedicalPhantomsApp.main(["info"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "64,64", "--plane", "axial", "--out", tempname() * ".npy"])
        GeometricMedicalPhantomsApp.main(["phantom", "torso", "--size", "32,32,32", "--out", tempname() * ".mat", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "coronal", "--out", tempname() * ".nii.gz", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", tempname() * ".png", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["signals", "respiratory", "--duration", "1.0", "--fs", "24.0", "--out", tempname() * ".csv"])
        GeometricMedicalPhantomsApp.main(["signals", "cardiac", "--duration", "1.0", "--fs", "100.0", "--out", tempname() * ".json"])

        # Avoid blocking codec/delegate I/O during precompile.
        precompile(GeometricMedicalPhantomsApp.save_tiff, (String, Matrix{Float32}))
        precompile(GeometricMedicalPhantomsApp.save_tiff, (String, Array{Float32, 3}))
        if GeometricMedicalPhantomsApp.GIF_SUPPORTED
            precompile(GeometricMedicalPhantomsApp.save_gif, (String, Array{Float32, 3}))
        end
    end
end
