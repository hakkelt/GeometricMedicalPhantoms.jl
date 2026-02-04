using Documenter
using GeometricMedicalPhantoms

makedocs(
    sitename = "GeometricMedicalPhantoms.jl",
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        assets = [asset("assets/favicon.png", class = :ico, islocal = true)],
    ),
    pages = [
        "Home" => "index.md",
        "Phantoms" => [
            "Shepp-Logan Phantom" => "phantoms/shepp_logan.md",
            "Torso Phantom" => "phantoms/torso.md",
            "Tubes Phantom" => "phantoms/tubes.md",
        ],
        "Advanced" => [
            "Geometry Primitives" => "advanced/primitives.md",
            "Custom Phantoms" => "advanced/custom_phantoms.md",
        ],
        "API Reference" => "api.md",
    ],
    modules = [GeometricMedicalPhantoms],
    checkdocs = :public,
)

deploydocs(
    repo = "github.com/hakkelt/GeometricMedicalPhantoms.jl.git",
    push_preview = false,
)
