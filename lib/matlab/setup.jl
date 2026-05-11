# setup.jl — one-time Julia setup for the GeometricMedicalPhantoms MATLAB toolbox.
#
# Run this script before using the toolbox for the first time:
#
#   julia lib/matlab/setup.jl
#
# What it does:
#   1. Installs GeometricMedicalPhantoms.jl in the current Julia environment.
#   2. Installs Mex.jl, which builds the mexjulia MEX file and registers the
#      toolbox directory on the MATLAB path automatically.
#   3. Verifies the package loads correctly.
#
# After running this script, start MATLAB — mexjulia will already be on the
# MATLAB path and you can use:
#   lib = GeometricMedicalPhantoms();

import Pkg

println("=== GeometricMedicalPhantoms MATLAB toolbox setup ===\n")

# --- 1. GeometricMedicalPhantoms.jl ------------------------------------------
println("Step 1: Installing GeometricMedicalPhantoms.jl ...")
Pkg.add("GeometricMedicalPhantoms")
using GeometricMedicalPhantoms
println("  OK  version=$(pkgversion(GeometricMedicalPhantoms))\n")

# --- 2. MATLAB.jl (required by Mex.jl) ----------------------------------------
println("Step 2: Installing MATLAB.jl ...")
Pkg.add("MATLAB")
println("  OK\n")

# --- 3. Mex.jl ----------------------------------------------------------------
println("Step 3: Installing Mex.jl (builds mexjulia MEX file) ...")
Pkg.add("Mex")
println("  OK\n")

println("=== Setup complete ===")
println("""
Start MATLAB and verify:
  >> ver = jl.mex('gmp_version')   % after constructing a GeometricMedicalPhantoms object
Or just:
  >> lib = GeometricMedicalPhantoms();
  >> lib.version()
""")
