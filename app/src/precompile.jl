@compile_workload begin
    redirect_stdout(devnull) do
        redirect_stderr(devnull) do
            main(["info"])
            main(["phantom", "shepp-logan", "--size", "64,64", "--plane", "axial", "--out", tempname() * ".npy"])
            main(["phantom", "shepp-logan", "--size", "64,64", "--fov", "30,30", "--plane", "axial", "--out", tempname() * ".npy", "--no-meta"])
            main(["phantom", "torso", "--size", "32,32,32", "--out", tempname() * ".mat", "--no-meta"])
            main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "coronal", "--out", tempname() * ".nii.gz", "--no-meta"])
            main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", tempname() * ".png", "--no-meta"])
            main(["signals", "respiratory", "--duration", "1.0", "--fs", "24.0", "--out", tempname() * ".csv"])
            main(["signals", "cardiac", "--duration", "1.0", "--fs", "100.0", "--out", tempname() * ".json"])
            main(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--format", "cfl", "--out", tempname(), "--no-meta"])
            main(["phantom", "torso", "--size", "16,16,16", "--format", "cfl", "--out", tempname(), "--no-meta"])

            # Explicit precompile for image/CFL helpers across common array shapes
            precompile(save_tiff, (String, Matrix{Float32}))
            precompile(save_tiff, (String, Array{Float32, 3}))
            if GIF_SUPPORTED
                precompile(save_gif, (String, Array{Float32, 3}))
            end
            precompile(as_complex_f32, (Matrix{Float32},))
            precompile(as_complex_f32, (Array{Float32, 3},))
            precompile(as_complex_f32, (Array{Float32, 4},))
        end
    end
end
