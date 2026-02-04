# Building Custom Phantoms

This guide shows how to create new phantom types from scratch using the geometric primitives provided by GeometricMedicalPhantoms. We'll walk through the key concepts and build a complete example.

## Overview: From Primitives to Phantoms

Every phantom in GeometricMedicalPhantoms follows the same pattern:

1. **Define geometry**: Create an array of geometric primitives (ellipsoids, cylinders, etc.)
2. **Define intensities**: Create a structure specifying how to assign intensities to tissues
3. **Create parameters**: Build a function to generate these based on user input
4. **Render**: Call the internal rendering function to create the phantom

## Intensity Assignment: Additive vs. Masking

When primitives overlap, their intensities combine according to one of two modes:

### Additive Mode

Intensities add together. If two primitives overlap at a point, the result is the sum of both intensities (or maximum, depending on implementation):

```julia
# Pseudo-code
for point in phantom
    intensity = 0
    for primitive in primitives
        if point_in_primitive(point, primitive)
            intensity += primitive.intensity
        end
    end
end
```

**Use when**: Creating phantoms where structures have distinct tissue types that don't overlap (e.g., Shepp-Logan brain).

### Masking Mode

Later primitives overwrite earlier ones. Order matters:

```julia
# Pseudo-code
for point in phantom
    intensity = 0
    for primitive in primitives
        if point_in_primitive(point, primitive)
            intensity = primitive.intensity  # Overwrite
        end
    end
end
```

**Use when**: Creating composites where you want inner structures to override outer ones (e.g., heart chambers inside the torso, blood vessels overriding tissue).

## Combining Primitives

Complex phantoms are created by combining multiple primitives. The order and intensity assignment mode (Additive vs. Masking) determine the final result.

```@setup custom_setup
using GeometricMedicalPhantoms
using MIRTjim: jim
using Plots
```

```@example custom_setup
# Combine ellipsoid and cylinder
# Note: Constructors use positional arguments (cx, cy, cz, rx, ry, rz, intensity)
combined_shapes = [
    Ellipsoid(0.0, 0.0, 0.0, 0.7, 0.6, 0.5, 0.5),
    CylinderZ(0.0, 0.0, 0.0, 0.2, 1.5, 0.9)
]

# When using draw!, the order in the array matters for Masking primitives.
# Additive primitives sum up.
nothing # hide
```

## Example: Building a Simple Brain Phantom

Let's create a minimal custom phantom showing a brain with ventricles and a tumor. This example follows the pattern used in the package's built-in phantoms.

```@setup custom_setup
using GeometricMedicalPhantoms
using MIRTjim: jim
using Plots
```

### Step 1: Define Geometry Structure

First, define the geometry parameters and a function that generates the shapes:

```@example custom_setup
# Custom geometry structure for our brain phantom
struct SimpleBrainGeometry
    brain_radius::Float32      # Radius of brain ellipsoid
    ventricle_radius::Float32  # Central ventricles
    tumor_radius::Float32      # Lesion/tumor size
    tumor_position::NTuple{3, Float32}  # (x, y, z) position
end

# Default constructor
SimpleBrainGeometry() = SimpleBrainGeometry(0.8f0, 0.15f0, 0.1f0, (0.3f0, 0.2f0, 0.0f0))

# Function that generates the list of shapes
function get_brain_shapes(geom::SimpleBrainGeometry, intensities)
    shapes = []
    
    # Brain ellipsoid (outermost) - using MaskingIntensityValue for masking mode
    push!(shapes, Ellipsoid(
        0.0f0, 0.0f0, 0.0f0,  # center
        geom.brain_radius, geom.brain_radius * 1.1f0, geom.brain_radius * 0.9f0,  # radii
        GeometricMedicalPhantoms.MaskingIntensityValue(Float32(intensities.brain))  # wrapped intensity
    ))
    
    # Ventricles (overwrites brain interior)
    push!(shapes, Ellipsoid(
        0.0f0, 0.0f0, 0.0f0,
        geom.ventricle_radius, geom.ventricle_radius * 1.5f0, geom.ventricle_radius * 2f0,
        GeometricMedicalPhantoms.MaskingIntensityValue(Float32(intensities.ventricles))
    ))
    
    # Tumor (overwrites everything at its location)
    tx, ty, tz = geom.tumor_position
    push!(shapes, Ellipsoid(
        tx, ty, tz,
        geom.tumor_radius * 1.2f0, geom.tumor_radius * 1.0f0, geom.tumor_radius * 0.8f0,
        GeometricMedicalPhantoms.MaskingIntensityValue(Float32(intensities.tumor))
    ))
    
    return shapes
end
nothing # hide
```

### Step 2: Define Intensity Structure

This struct holds intensity values. We also define helper functions for both numeric and boolean (mask) intensities:

```@example custom_setup
# Numeric intensities
struct SimpleBrainIntensities
    brain::Float32
    ventricles::Float32
    tumor::Float32
end

# Default constructor
SimpleBrainIntensities() = SimpleBrainIntensities(0.6f0, 0.9f0, 1.0f0)

# Helper function to get intensity by name (for numeric)
function get_intensity(intensities::SimpleBrainIntensities, tissue::Symbol)
    if tissue == :brain
        return intensities.brain
    elseif tissue == :ventricles
        return intensities.ventricles
    elseif tissue == :tumor
        return intensities.tumor
    else
        return 0.0f0
    end
end

# Boolean mask structure
struct SimpleBrainMask
    brain::Bool
    ventricles::Bool
    tumor::Bool
end

# Default: all false
SimpleBrainMask(; brain=false, ventricles=false, tumor=false) = 
    SimpleBrainMask(brain, ventricles, tumor)

# Helper function for mask (returns 1.0 if enabled, 0.0 otherwise)
function get_intensity(mask::SimpleBrainMask, tissue::Symbol)
    if tissue == :brain && mask.brain
        return 1.0f0
    elseif tissue == :ventricles && mask.ventricles
        return 1.0f0
    elseif tissue == :tumor && mask.tumor
        return 1.0f0
    else
        return 0.0f0
    end
end
nothing # hide
```

### Step 3: Create Rendering Function

Now create the main function that ties everything together:

```@example custom_setup
function create_simple_brain_phantom(
    nx::Int, ny::Int, nz::Int;
    fovs::NTuple{3, Float32} = (2.0f0, 2.0f0, 2.0f0),
    geometry::SimpleBrainGeometry = SimpleBrainGeometry(),
    intensities = SimpleBrainIntensities(),
    eltype::Type = Float32
)
    # Initialize phantom array
    phantom = zeros(eltype, nx, ny, nz)
    
    # Create coordinate axes in physical space
    ax_x = collect(range(-fovs[1]/2, fovs[1]/2, length=nx))
    ax_y = collect(range(-fovs[2]/2, fovs[2]/2, length=ny))
    ax_z = collect(range(-fovs[3]/2, fovs[3]/2, length=nz))
    
    # Get shapes with their intensities
    shapes = get_brain_shapes(geometry, intensities)
    
    # Draw each shape onto the phantom
    for shape in shapes
        draw!(phantom, ax_x, ax_y, ax_z, shape)
    end
    
    return phantom
end

# Create the phantom
brain_phantom = create_simple_brain_phantom(128, 128, 128)
println("Brain phantom created with size: $(size(brain_phantom))")
nothing # hide
```

### Step 4: Visualize Your Custom Result

```@example custom_setup
# Extract center slices for all three planes
axial_slice = brain_phantom[:, :, div(128, 2)]
coronal_slice = brain_phantom[:, div(128, 2), :]
sagittal_slice = brain_phantom[div(128, 2), :, :]

# Create a single row plot with three images
fig = plot(layout=(1, 3), size=(1200, 400))
heatmap!(fig[1], axial_slice', title="Axial", aspect_ratio=:equal, color=:grays, legend=false, axis=false)
heatmap!(fig[2], coronal_slice', title="Coronal", aspect_ratio=:equal, color=:grays, legend=false, axis=false)
heatmap!(fig[3], sagittal_slice', title="Sagittal", aspect_ratio=:equal, color=:grays, legend=false, axis=false)

savefig(fig, "custom_brain_views.png"); nothing # hide
```

![custom_brain_views.png](custom_brain_views.png)

You can also create masks to extract specific structures:

```@example custom_setup
# Create a mask showing only the tumor
tumor_mask = create_simple_brain_phantom(
    128, 128, 128; 
    intensities=SimpleBrainMask(tumor=true)
)

jim(tumor_mask[:, :, div(128, 2)]; title="Tumor Mask")
savefig("custom_brain_tumor_mask.png"); nothing # hide
```

![custom_brain_tumor_mask.png](custom_brain_tumor_mask.png)


## Key Design Principles

When building custom phantoms, follow these practices:

### 1. Separate Concerns
- **Geometry structure**: Holds shape parameters
- **Intensity structure**: Holds tissue properties
- **Rendering function**: Combines them into a phantom

### 2. Coordinate System
Always work in physical space (cm), not voxel indices:

```julia
x_coords = range(-fovs[1]/2, fovs[1]/2, length=nx)
# Avoids confusion and makes phantoms independent of resolution
```

### 3. Rendering Order
In masking mode, render in order from:
1. Large outer structures
2. Medium interior structures
3. Small details/pathology last

This ensures later structures overwrite earlier ones correctly.

### 4. Documentation
Include docstrings explaining:
- Purpose of each parameter
- Typical values
- Biological meaning

Example:

```julia
"""
    create_custom_phantom(nx, ny, nz; fovs=(20,20,20), geometry=..., intensities=...)

Create a custom phantom.

# Arguments
- `nx, ny, nz`: Grid dimensions
- `fovs`: Field of view in cm (default: (20, 20, 20))
- `geometry`: Geometry structure with shape parameters
- `intensities`: Intensity structure with tissue values

# Returns
- `phantom::Array{Float32, 3}`: Generated phantom array
"""
```

### 5. Parameter Validation
Validate inputs to catch errors early:

```julia
function create_phantom(nx, ny, nz; ...)
    nx > 0 || throw(ArgumentError("nx must be positive"))
    ny > 0 || throw(ArgumentError("ny must be positive"))
    nz > 0 || throw(ArgumentError("nz must be positive"))
    # ... rest of function
end
```

## Integration into the Package

Once you've defined a custom phantom, you can integrate it with the package by:

1. Creating a module file in `src/`
2. Defining your geometry and intensity structures
3. Implementing a public `create_*_phantom` function
4. Adding tests to `test/`
5. Documenting in the guide (this page)

The package structure supports arbitrary custom phantoms while maintaining consistency with built-in phantoms.
