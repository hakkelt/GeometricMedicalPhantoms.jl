using Test
using JSON3
using MAT
using NPZ
using NIfTI
using FileIO
using DelimitedFiles

using GeometricMedicalPhantomsApp

function run_cli(args)
    return GeometricMedicalPhantomsApp.main(args)
end

@testset "geomphantoms CLI" begin
    mktempdir() do dir
        @testset "shepp-logan npy + meta" begin
            out_path = joinpath(dir, "shepp.npy")
            code = run_cli(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            @test isfile(out_path * ".json")
            data = NPZ.npzread(out_path)
            @test size(data["phantom"]) == (16, 16)
            meta = JSON3.read(read(out_path * ".json", String))
            @test meta["type"] == "shepp-logan"
        end

        @testset "default plane for 2D" begin
            out_path = joinpath(dir, "shepp_default.npy")
            code = run_cli(["phantom", "shepp-logan", "--size", "8,8", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            data = NPZ.npzread(out_path)
            @test size(data["phantom"]) == (8, 8)
        end

        @testset "torso mat" begin
            out_path = joinpath(dir, "torso.mat")
            code = run_cli(["phantom", "torso", "--size", "8,8,8", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            mat = MAT.matread(out_path)
            @test haskey(mat, "phantom")
        end

        @testset "tubes cfl" begin
            out_base = joinpath(dir, "tubes")
            code = run_cli(["phantom", "tubes", "--size", "8,8,8", "--format", "cfl", "--out", out_base])
            @test code == 0
            @test isfile(out_base * ".cfl")
            @test isfile(out_base * ".hdr")
        end

        @testset "shepp-logan nifti" begin
            out_path = joinpath(dir, "shepp.nii.gz")
            code = run_cli(["phantom", "shepp-logan", "--size", "8,8", "--plane", "axial", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            nii = NIfTI.niread(out_path)
            @test size(nii.raw) == (8, 8)
        end

        @testset "shepp-logan png" begin
            out_path = joinpath(dir, "shepp.png")
            code = run_cli(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            img = FileIO.load(out_path)
            @test size(img) == (16, 16)
        end

        @testset "shepp-logan tiff" begin
            out_path = joinpath(dir, "shepp.tiff")
            code = run_cli(["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            img = FileIO.load(out_path)
            @test size(img) == (16, 16)
        end

        @testset "torso 3D tiff" begin
            out_path = joinpath(dir, "torso.tif")
            code = run_cli(["phantom", "torso", "--size", "8,8,8", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            img = FileIO.load(out_path)
            @test size(img) == (8, 8, 8)
        end

        @testset "signals respiratory csv" begin
            out_path = joinpath(dir, "resp.csv")
            code = run_cli(["signals", "respiratory", "--duration", "1", "--fs", "4", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            header = split(read(out_path, String), "\n")[1]
            @test occursin("signal", header)
        end

        @testset "signals cardiac json" begin
            out_path = joinpath(dir, "cardiac.json")
            code = run_cli(["signals", "cardiac", "--duration", "1", "--fs", "4", "--format", "json", "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            obj = JSON3.read(read(out_path, String))
            @test haskey(obj, "lv")
            @test haskey(obj, "rv")
            @test haskey(obj, "la")
            @test haskey(obj, "ra")
        end

        @testset "format inference" begin
            fmt = GeometricMedicalPhantomsApp.resolve_format(nothing, joinpath(dir, "image.nii.gz"))
            @test fmt == "nifti"
        end

        @testset "bart extension error" begin
            err = try
                GeometricMedicalPhantomsApp.save_output(joinpath(dir, "bad.cfl"), "cfl", zeros(2, 2))
                nothing
            catch e
                e
            end
            @test err !== nothing
        end

        @testset "invalid size" begin
            err = try
                GeometricMedicalPhantomsApp.parse_size("64")
                nothing
            catch e
                e
            end
            @test err !== nothing
        end

        @testset "torso with respiratory signal" begin
            # Generate a respiratory signal file
            resp_path = joinpath(dir, "resp_input.csv")
            writedlm(resp_path, [0.1 * sin(2π * 0.2 * i) for i in 1:10], ',')
            
            out_path = joinpath(dir, "torso_resp.npy")
            code = run_cli(["phantom", "torso", "--size", "8,8,8", "--resp-signal", resp_path, "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            data = NPZ.npzread(out_path)
            @test haskey(data, "phantom")
        end

        @testset "torso with cardiac signal" begin
            # Generate a cardiac signal file
            cardiac_path = joinpath(dir, "cardiac_input.json")
            cardiac_data = Dict("lv" => [80.0, 85.0, 90.0], "rv" => [70.0, 75.0, 80.0], 
                               "la" => [50.0, 55.0, 60.0], "ra" => [45.0, 50.0, 55.0])
            write(cardiac_path, JSON3.write(cardiac_data))
            
            out_path = joinpath(dir, "torso_cardiac.npy")
            code = run_cli(["phantom", "torso", "--size", "8,8,8", "--cardiac-signal", cardiac_path, "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            data = NPZ.npzread(out_path)
            @test haskey(data, "phantom")
        end

        @testset "torso with both signals" begin
            # Generate both signal files with matching lengths
            n_samples = 5
            resp_path = joinpath(dir, "resp_both.csv")
            writedlm(resp_path, [0.1 * sin(2π * 0.2 * i) for i in 1:n_samples], ',')
            
            cardiac_path = joinpath(dir, "cardiac_both.csv")
            cardiac_matrix = hcat(
                [80.0, 85.0, 90.0, 85.0, 80.0],  # lv
                [70.0, 75.0, 80.0, 75.0, 70.0],  # rv
                [50.0, 55.0, 60.0, 55.0, 50.0],  # la
                [45.0, 50.0, 55.0, 50.0, 45.0]   # ra
            )
            writedlm(cardiac_path, cardiac_matrix, ',')
            
            out_path = joinpath(dir, "torso_both.npy")
            code = run_cli(["phantom", "torso", "--size", "8,8,8", 
                          "--resp-signal", resp_path, "--cardiac-signal", cardiac_path, 
                          "--out", out_path])
            @test code == 0
            @test isfile(out_path)
            data = NPZ.npzread(out_path)
            @test haskey(data, "phantom")
        end
    end

    # Quality assurance tests
    include("test_aqua.jl")
    include("test_jet.jl")
end
