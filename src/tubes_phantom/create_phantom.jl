"""
    create_tubes_phantom(nx::Int, ny::Int, nz::Int; kwargs...)
    create_tubes_phantom(nx::Int, ny::Int, axis::Symbol; kwargs...)

Generate a tubes phantom. When invoked with three dimensions, a 3D volume is returned; when invoked with an axis symbol, a 2D slice is produced. In both modes the `ti` keyword accepts either a single `TubesIntensities` or a vector of intensities to render a stack of frames (resulting in a 4D volume or 3D stack, respectively).

# Arguments
- `nx::Int`: Number of voxels in the x direction
- `ny::Int`: Number of voxels in the y direction
- `nz::Int`: Number of voxels in the z direction (only for volume mode)
- `axis::Symbol`: Slice orientation (`:axial`, `:coronal`, or `:sagittal`)

# Keyword Arguments
- `fovs::Tuple{Real,Real,Real}`: Field of view in cm for volume mode (default: (10.0, 10.0, 10.0))
- `fovs::Tuple{Real,Real}`: Field of view in cm for slice mode (default: (10.0, 10.0))
- `slice_position::Real`: Position along the perpendicular axis in cm (default: 0.0, slice mode only)
- `tg::TubesGeometry`: Geometry parameters (default: TubesGeometry())
- `ti::Union{TubesIntensities, Vector{<:TubesIntensities}}`: Either a single intensity set or a collection of intensity sets to produce multiple frames (default: TubesIntensities())
- `eltype::Type`: Element type for the phantom array (default: Float32)

# Returns
- Volume mode: `Array{eltype,3}` for single intensity or `Array{eltype,4}` when a vector of intensities is provided
- Slice mode: `Array{eltype,2}` for single intensity or `Array{eltype,3}` when multiple intensities are passed

# Examples
```julia
phantom3d = create_tubes_phantom(128, 128, 128)
phantom_stack = create_tubes_phantom(128, 128, 128; ti=[TubesIntensities(), TubesIntensities(tube_fillings=[0.2])])
phantom_axial = create_tubes_phantom(128, 128, :axial; slice_position=2.0)
phantom_axial_stack = create_tubes_phantom(128, 128, :axial; ti=[TubesIntensities(), TubesIntensities(tube_fillings=[0.8])])
```
"""
function create_tubes_phantom(nx::Int, ny::Int, nz::Int; 
    fovs::Tuple{<:Real,<:Real,<:Real}=(10.0, 10.0, 10.0),
    tg::TubesGeometry=TubesGeometry(),
    ti::Union{TubesIntensities, Vector{<:TubesIntensities}}=TubesIntensities(),
    eltype::Type=Float32)
    tis = ti isa Vector ? ti : (ti,)
    if length(tis) == 1
        return _render_tubes_volume(nx, ny, nz; fovs=fovs, tg=tg, ti=tis[1], eltype=eltype, force_eltype=false)
    end
    result = Array{eltype,4}(undef, nx, ny, nz, length(tis))
    for (idx, intensity) in enumerate(tis)
        result[:, :, :, idx] = _render_tubes_volume(nx, ny, nz; fovs=fovs, tg=tg, ti=intensity, eltype=eltype, force_eltype=true)
    end
    return result
end

function create_tubes_phantom(nx::Int, ny::Int, axis::Symbol; 
    fovs::Tuple{<:Real,<:Real}=(10.0, 10.0),
    slice_position::Real=0.0,
    tg::TubesGeometry=TubesGeometry(),
    ti::Union{TubesIntensities, Vector{<:TubesIntensities}}=TubesIntensities(),
    eltype::Type=Float32)
    tis = ti isa Vector ? ti : (ti,)
    if length(tis) == 1
        return _render_tubes_slice(nx, ny; fovs=fovs, slice_position=slice_position, tg=tg, ti=tis[1], eltype=eltype, force_eltype=false, axis=axis)
    end
    result = Array{eltype,3}(undef, nx, ny, length(tis))
    for (idx, intensity) in enumerate(tis)
        result[:, :, idx] = _render_tubes_slice(nx, ny; fovs=fovs, slice_position=slice_position, tg=tg, ti=intensity, eltype=eltype, force_eltype=true, axis=axis)
    end
    return result
end

function _render_tubes_volume(nx, ny, nz; fovs, tg, ti, eltype, force_eltype)
    norm_factor = 10.0
    ax_x = collect(range(-fovs[1]/2, fovs[1]/2, length=nx)) / norm_factor
    ax_y = collect(range(-fovs[2]/2, fovs[2]/2, length=ny)) / norm_factor
    ax_z = collect(range(-fovs[3]/2, fovs[3]/2, length=nz)) / norm_factor
    output_eltype = force_eltype ? eltype : (ti isa TubesIntensities{Bool} ? Bool : eltype)
    phantom = zeros(output_eltype, nx, ny, nz)
    shapes = get_tubes_shapes(tg, ti, output_eltype)
    for shape in shapes
        draw!(phantom, ax_x, ax_y, ax_z, shape)
    end
    return phantom
end

function _render_tubes_slice(nx, ny; fovs, slice_position, tg, ti, eltype, force_eltype, axis)
    norm_factor = 10.0
    ax_1 = collect(range(-fovs[1]/2, fovs[1]/2, length=nx)) / norm_factor
    ax_2 = collect(range(-fovs[2]/2, fovs[2]/2, length=ny)) / norm_factor
    slice_pos_norm = slice_position / norm_factor
    output_eltype = force_eltype ? eltype : (ti isa TubesIntensities{Bool} ? Bool : eltype)
    phantom = zeros(output_eltype, nx, ny)
    phantom = convert(Array{output_eltype,2}, phantom)
    shapes = get_tubes_shapes(tg, ti, output_eltype)
    for shape in shapes
        draw_2d!(phantom, ax_1, ax_2, slice_pos_norm, axis, shape)
    end
    return phantom
end
