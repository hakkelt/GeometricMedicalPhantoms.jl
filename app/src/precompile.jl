using GeometricMedicalPhantomsApp

# Precompile common CLI operations
redirect_stdout(devnull) do
    redirect_stderr(devnull) do
        GeometricMedicalPhantomsApp.main(["info"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "64,64", "--plane", "axial", "--out", tempname() * ".npy", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "torso", "--size", "32,32,32", "--out", tempname() * ".mat", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "coronal", "--out", tempname() * ".nii.gz", "--no-meta"])
        # GeometricMedicalPhantomsApp.main(["phantom", "torso", "--size", "16,16", "--plane", "coronal", "--out", tempname() * ".png", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", tempname() * ".png", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "sagi", "--out", tempname() * ".tiff", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["phantom", "torso", "--size", "8,8,8", "--out", tempname() * ".tif", "--no-meta"])
        GeometricMedicalPhantomsApp.main(["signals", "respiratory", "--duration", "1.0", "--fs", "24.0", "--out", tempname() * ".csv"])
        GeometricMedicalPhantomsApp.main(["signals", "cardiac", "--duration", "1.0", "--fs", "100.0", "--out", tempname() * ".json"])
    end
end
