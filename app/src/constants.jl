const PLANE_MAP = Dict(
    "axial" => :axial,
    "coronal" => :coronal,
    "sagittal" => :sagittal,
)

const PHANTOM_TYPES = Set(["shepp-logan", "torso", "tubes"])
const SIGNAL_TYPES = Set(["respiratory", "cardiac"])
const GIF_SUPPORTED = !Sys.iswindows()
const SUPPORTED_OUTPUT_FORMATS = GIF_SUPPORTED ? ["npy", "mat", "cfl", "nifti", "png", "tiff", "gif"] : ["npy", "mat", "cfl", "nifti", "png", "tiff"]

const FORMAT_ALIASES = let aliases = Dict(
    "npy" => "npy",
    "mat" => "mat",
    "cfl" => "cfl",
    "hdr" => "cfl",
    "nifti" => "nifti",
    "nii" => "nifti",
    "png" => "png",
    "tiff" => "tiff",
    "tif" => "tiff",
)
    if GIF_SUPPORTED
        aliases["gif"] = "gif"
    end
    aliases
end
