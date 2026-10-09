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
- `fov::Tuple{Real,Real,Real}`: Field of view in cm for volume mode (default: (10.0, 10.0, 10.0))
- `fov::Tuple{Real,Real}`: Field of view in cm for slice mode (default: (10.0, 10.0))
- `slice_position::Real`: Position along the perpendicular axis in cm (default: 0.0, slice mode only)
- `tg::TubesGeometry`: Geometry parameters (default: TubesGeometry())
- `ti::Union{TubesIntensities, Vector{<:TubesIntensities}}`: Either a single intensity set or a collection of intensity sets to produce multiple frames (default: TubesIntensities())
- `eltype::Type`: Element type for the phantom array (default: Float32)
- `supersample::Integer`: Sample points per voxel along each spatial (volume mode) or in-plane
  (slice mode) dimension (default: 1). Each voxel holds the mean of `supersample^D` point samples
  spread evenly over the voxel (area sampling), which reduces the aliasing of the rasterized
  phantom in k-space. Rendering takes `supersample^D` times as long. Not available for mask
  phantoms.

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
function create_tubes_phantom(
        nx::Int, ny::Int, nz::Int;
        fov::Tuple{<:Real, <:Real, <:Real} = (10.0, 10.0, 10.0),
        tg::TubesGeometry = TubesGeometry(),
        ti::Union{TubesIntensities, Vector{<:TubesIntensities}} = TubesIntensities(),
        eltype::Type = Float32,
        supersample::Integer = 1
    )
    tis = ti isa Vector ? ti : (ti,)
    check_supersample_eltype(supersample, length(tis) == 1 && tis[1] isa TubesIntensities{Bool})
    return render_supersampled(supersample, Val(3)) do offset
        if length(tis) == 1
            return _render_tubes_volume(nx, ny, nz, offset; fov = fov, tg = tg, ti = tis[1], eltype = eltype, force_eltype = false)
        end
        result = Array{eltype, 4}(undef, nx, ny, nz, length(tis))
        for (idx, intensity) in enumerate(tis)
            result[:, :, :, idx] = _render_tubes_volume(nx, ny, nz, offset; fov = fov, tg = tg, ti = intensity, eltype = eltype, force_eltype = true)
        end
        return result
    end
end

function create_tubes_phantom(
        nx::Int, ny::Int, axis::Symbol;
        fov::Tuple{<:Real, <:Real} = (10.0, 10.0),
        slice_position::Real = 0.0,
        tg::TubesGeometry = TubesGeometry(),
        ti::Union{TubesIntensities, Vector{<:TubesIntensities}} = TubesIntensities(),
        eltype::Type = Float32,
        supersample::Integer = 1
    )
    tis = ti isa Vector ? ti : (ti,)
    check_supersample_eltype(supersample, length(tis) == 1 && tis[1] isa TubesIntensities{Bool})
    return render_supersampled(supersample, Val(2)) do offset
        if length(tis) == 1
            return _render_tubes_slice(nx, ny, offset; fov = fov, slice_position = slice_position, tg = tg, ti = tis[1], eltype = eltype, force_eltype = false, axis = axis)
        end
        result = Array{eltype, 3}(undef, nx, ny, length(tis))
        for (idx, intensity) in enumerate(tis)
            result[:, :, idx] = _render_tubes_slice(nx, ny, offset; fov = fov, slice_position = slice_position, tg = tg, ti = intensity, eltype = eltype, force_eltype = true, axis = axis)
        end
        return result
    end
end

# The axes span `-fov/2:fov/2` endpoint to endpoint; `offset` moves every sample by that many
# grid steps.
_tubes_axis(fov, n, offset) = collect(range(-fov / 2, fov / 2, length = n) .+ offset * (n > 1 ? fov / (n - 1) : 0.0))

function _render_tubes_volume(nx, ny, nz, offset; fov, tg, ti, eltype, force_eltype)
    norm_factor = 10.0
    ax_x = _tubes_axis(fov[1], nx, offset[1]) / norm_factor
    ax_y = _tubes_axis(fov[2], ny, offset[2]) / norm_factor
    ax_z = _tubes_axis(fov[3], nz, offset[3]) / norm_factor
    output_eltype = force_eltype ? eltype : (ti isa TubesIntensities{Bool} ? Bool : eltype)
    phantom = zeros(output_eltype, nx, ny, nz)
    ctx = DrawContext3D(phantom, ax_x, ax_y, ax_z)
    draw_tubes_shapes!(ctx, tg, ti)
    return phantom
end

function _render_tubes_slice(nx, ny, offset; fov, slice_position, tg, ti, eltype, force_eltype, axis)
    # Use explicit if/elseif with literal Val symbols so JET can infer Val{:axial} etc.
    kw = (; fov, slice_position, tg, ti, eltype, force_eltype)
    if axis === :axial
        return _render_tubes_slice_impl(nx, ny, Val(:axial), offset; kw...)
    elseif axis === :coronal
        return _render_tubes_slice_impl(nx, ny, Val(:coronal), offset; kw...)
    elseif axis === :sagittal
        return _render_tubes_slice_impl(nx, ny, Val(:sagittal), offset; kw...)
    else
        throw(ArgumentError("axis must be :axial, :coronal, or :sagittal"))
    end
end

function _render_tubes_slice_impl(nx, ny, ::Val{A}, offset; fov, slice_position, tg, ti, eltype, force_eltype) where {A}
    norm_factor = 10.0
    ax_1 = _tubes_axis(fov[1], nx, offset[1]) / norm_factor
    ax_2 = _tubes_axis(fov[2], ny, offset[2]) / norm_factor
    slice_pos_norm = slice_position / norm_factor
    output_eltype = force_eltype ? eltype : (ti isa TubesIntensities{Bool} ? Bool : eltype)
    phantom = zeros(output_eltype, nx, ny)
    # A is a compile-time constant here — DrawContext2D{A} is fully typed.
    ctx = DrawContext2D{A}(phantom, ax_1, ax_2, slice_pos_norm)
    draw_tubes_shapes!(ctx, tg, ti)
    return phantom
end
