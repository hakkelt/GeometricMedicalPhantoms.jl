const PLANE_MAP = Dict(
    "axial" => :axial,
    "coronal" => :coronal,
    "sagittal" => :sagittal,
)

const PHANTOM_TYPES = Set(["shepp-logan", "torso", "tubes"])
const SIGNAL_TYPES = Set(["respiratory", "cardiac"])
const FORMAT_ALIASES = Dict(
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
