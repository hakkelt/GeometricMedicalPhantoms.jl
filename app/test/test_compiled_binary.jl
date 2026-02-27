using JSON3
using NIfTI
using NPZ
using MAT
using DelimitedFiles
using Test

function run_cmd(exe::String, args::Vector{String})
    cmd = Cmd([exe; args])
    return success(ignorestatus(cmd))
end

function main(exe::String)
    @testset "compiled geomphantoms binary" begin
        mktempdir() do dir
            out_npy = joinpath(dir, "shepp.npy")
            out_mat = joinpath(dir, "torso.mat")
            out_nii = joinpath(dir, "shepp.nii.gz")
            out_png = joinpath(dir, "shepp.png")
            out_tiff = joinpath(dir, "torso.tif")
            out_resp = joinpath(dir, "resp.csv")
            out_card = joinpath(dir, "cardiac.json")
            out_gif = joinpath(dir, "torso_dynamic.gif")

            @test run_cmd(exe, ["info"])

            @test run_cmd(exe, ["phantom", "shepp-logan", "--size", "32,32", "--plane", "axial", "--out", out_npy])
            @test isfile(out_npy)
            npy = NPZ.npzread(out_npy)
            @test size(npy["phantom"]) == (32, 32)

            @test run_cmd(exe, ["phantom", "torso", "--size", "16,16,16", "--out", out_mat])
            @test isfile(out_mat)
            mat = MAT.matread(out_mat)
            @test haskey(mat, "phantom")

            @test run_cmd(exe, ["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", out_nii])
            @test isfile(out_nii)
            nii = NIfTI.niread(out_nii)
            @test size(nii.raw) == (16, 16)

            @test run_cmd(exe, ["phantom", "shepp-logan", "--size", "16,16", "--plane", "axial", "--out", out_png])
            @test isfile(out_png)

            @test run_cmd(exe, ["phantom", "torso", "--size", "8,8,8", "--out", out_tiff])
            @test isfile(out_tiff)

            @test run_cmd(exe, ["signals", "respiratory", "--duration", "10", "--fs", "24", "--rate", "15", "--out", out_resp])
            @test isfile(out_resp)
            resp_header = split(read(out_resp, String), "\n")[1]
            @test startswith(resp_header, "t,")

            @test run_cmd(exe, ["signals", "cardiac", "--duration", "10", "--fs", "24", "--rate", "70", "--out", out_card])
            @test isfile(out_card)
            card = JSON3.read(read(out_card, String))
            @test haskey(card, "lv")

            gif_ok = run_cmd(exe, ["phantom", "torso", "--size", "128,128", "--plane", "coronal", "--resp-signal", out_resp, "--cardiac-signal", out_card, "--out", out_gif])
            if Sys.iswindows()
                @test !gif_ok
                @test !isfile(out_gif)
            else
                @test gif_ok
                @test isfile(out_gif)
            end
        end
    end
end

if length(ARGS) != 1
    error("Usage: julia test_compiled_binary.jl <path-to-geomphantoms-executable>")
end

main(ARGS[1])
