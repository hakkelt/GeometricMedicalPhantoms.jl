using JuliaC

# Change working directory to the lib/ folder so that relative paths in
# ImageRecipe / LinkRecipe resolve correctly.
cd(@__DIR__)

if isdir("build")
    rm("build"; recursive = true, force = true)
end

# Build the shared library.
#
# Trim strategy (best → good → fallback):
#   1. --trim=safe  — static verifier ensures no dead stubs; fails when Polyester's
#      @batch macro generates type-unstable threading code (known limitation).
#   2. --trim=on    — removes dead code without the strict verifier; smaller than
#      untrimmed but skips the safety check.
#   3. no trim      — full Julia runtime + all precompiled methods bundled.
function do_build(; trim_mode::Union{String, Nothing})
    img = ImageRecipe(
        output_type = "--output-lib",
        file = "src/GeometricMedicalPhantomsLib.jl",
        trim_mode = trim_mode,
        add_ccallables = true,
        verbose = false,
    )

    # Platform-specific library name (JuliaC appends the extension automatically)
    lib_name = Sys.iswindows() ? "geomphantoms" : "libgeomphantoms"
    link = LinkRecipe(
        image_recipe = img,
        outname = "build/lib/$(lib_name)",
        rpath = "@bundle",
        ld_flags = ["-lm"],
    )

    bun = BundleRecipe(
        link_recipe = link,
        output_dir = "build",
    )

    compile_products(img)
    link_products(link)
    bundle_products(bun)
    return
end

function clean_build()
    if isdir("build")
        rm("build"; recursive = true, force = true)
    end
    return
end

# --trim=safe and --trim=on both fail for this library because Polyester's
# @batch macro generates type-unstable thread-dispatch code that the static
# verifier cannot resolve.  Skip trimming to keep build times short.
@info "Building shared library (no trimming) ..."
do_build(trim_mode = nothing)
@info "Build complete (untrimmed)."
