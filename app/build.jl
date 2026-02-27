using JuliaC

@show ENV["JULIA_CPU_TARGET"]

cd(@__DIR__)

if isdir("build")
    rm("build"; recursive = true, force = true)
end

img = ImageRecipe(
    output_type = "--output-exe",
    file = "main.jl",
    #trim_mode = "safe",
    add_ccallables = false,
    verbose = false,
)

link = LinkRecipe(
    image_recipe = img,
    outname = "build/bin/geomphantoms",
    rpath = "@bundle",
    ld_flags = ["-lm"]
)

bun = BundleRecipe(
    link_recipe = link,
    output_dir = "build",
)

compile_products(img)
link_products(link)
bundle_products(bun)
