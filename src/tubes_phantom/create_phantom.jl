"""
    create_tubes_phantom(nx::Int, ny::Int, nz::Int; kwargs...)

Create a 3D tubes phantom.

# Arguments
- `nx::Int`: Number of voxels in x direction
- `ny::Int`: Number of voxels in y direction
- `nz::Int`: Number of voxels in z direction

# Keyword Arguments
- `fovs::Tuple{Real,Real,Real}`: Field of view in cm (default: (10.0, 10.0, 10.0))
- `tg::TubesGeometry`: Geometry parameters (default: TubesGeometry())
- `ti::TubesIntensities`: Intensity parameters (default: TubesIntensities())
- `eltype::Type`: Element type for the phantom array (default: Float32)

# Returns
- `phantom::Array{eltype,3}`: 3D phantom array

# Example
```julia
phantom = create_tubes_phantom(128, 128, 128)
```
"""
function create_tubes_phantom(nx::Int, ny::Int, nz::Int; 
    fovs::Tuple{<:Real,<:Real,<:Real}=(10.0, 10.0, 10.0),
    tg::TubesGeometry=TubesGeometry(),
    ti::TubesIntensities=TubesIntensities(),
    eltype::Type=Float32)
    
    # Create normalized axes (-1 to 1 range)
    norm_factor = 10.0
    ax_x = collect(range(-fovs[1]/2, fovs[1]/2, length=nx)) / norm_factor
    ax_y = collect(range(-fovs[2]/2, fovs[2]/2, length=ny)) / norm_factor
    ax_z = collect(range(-fovs[3]/2, fovs[3]/2, length=nz)) / norm_factor
    
    # Determine output type
    output_eltype = ti isa TubesIntensities{Bool} ? Bool : eltype
    
    # Create phantom array
    phantom = zeros(output_eltype, nx, ny, nz)
    
    # Get all shapes with appropriate element type
    shapes = get_tubes_shapes(tg, ti, output_eltype)
    
    # Draw all shapes
    for shape in shapes
        draw!(phantom, ax_x, ax_y, ax_z, shape)
    end
    
    return phantom
end

"""
    create_tubes_phantom(nx::Int, ny::Int, axis::Symbol; kwargs...)

Create a 2D tubes phantom slice.

# Arguments
- `nx::Int`: Number of voxels in x direction
- `ny::Int`: Number of voxels in y direction
- `axis::Symbol`: Axis perpendicular to the slice (:axial, :coronal, or :sagittal)

# Keyword Arguments
- `fovs::Tuple{Real,Real}`: Field of view in cm for the slice (default: (10.0, 10.0))
- `slice_position::Real`: Position along the perpendicular axis in cm (default: 0.0)
- `tg::TubesGeometry`: Geometry parameters (default: TubesGeometry())
- `ti::TubesIntensities`: Intensity parameters (default: TubesIntensities())
- `eltype::Type`: Element type for the phantom array (default: Float32)

# Returns
- `phantom::Array{eltype,2}`: 2D phantom slice

# Example
```julia
# Axial slice at z=0
phantom_axial = create_tubes_phantom(128, 128, :axial)

# Coronal slice at y=2.5 cm
phantom_coronal = create_tubes_phantom(128, 128, :coronal; slice_position=2.5)
```
"""
function create_tubes_phantom(nx::Int, ny::Int, axis::Symbol; 
    fovs::Tuple{<:Real,<:Real}=(10.0, 10.0),
    slice_position::Real=0.0,
    tg::TubesGeometry=TubesGeometry(),
    ti::TubesIntensities=TubesIntensities(),
    eltype::Type=Float32)
    
    # Create normalized axes
    norm_factor = 10.0
    ax_1 = collect(range(-fovs[1]/2, fovs[1]/2, length=nx)) / norm_factor
    ax_2 = collect(range(-fovs[2]/2, fovs[2]/2, length=ny)) / norm_factor
    
    # Convert slice_position from cm to normalized units
    slice_pos_norm = slice_position / norm_factor
    
    # Determine output type
    output_eltype = ti isa TubesIntensities{Bool} ? Bool : eltype
    
    # Create phantom array
    phantom = zeros(output_eltype, nx, ny)
    
    # Get all shapes with appropriate element type
    shapes = get_tubes_shapes(tg, ti, output_eltype)
    
    # Draw all shapes using the appropriate axis orientation
    for shape in shapes
        draw_2d!(phantom, ax_1, ax_2, slice_pos_norm, axis, shape)
    end
    
    return phantom
end
