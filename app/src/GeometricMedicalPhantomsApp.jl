module GeometricMedicalPhantomsApp

export main

using ArgParse
using BartIO
using GeometricMedicalPhantoms
@static if !Sys.iswindows()
	using GIFImages
end
using JSON3
using MAT
using NIfTI
using NPZ
using PNGFiles
using TiffImages
using DelimitedFiles
using Dates
using ColorTypes
using FixedPointNumbers

include("constants.jl")
include("utils.jl")
include("signals.jl")
include("io.jl")
include("phantoms.jl")
include("cli.jl")

end
