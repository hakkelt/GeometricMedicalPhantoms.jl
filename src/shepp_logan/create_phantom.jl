"""
    create_shepp_logan_phantom(nx, ny, nz; fov=(20,20,20), ti=CTSheppLoganIntensities(), eltype=Float32, supersample=1)
    create_shepp_logan_phantom(nx, ny, axis; fov=(20,20), slice_position=0.0, ti=CTSheppLoganIntensities(), eltype=Float32, supersample=1)

Generate a 3D Shepp-Logan phantom or a 2D slice of it.

For a 2D slice, provide `nx`, `ny`, and an `axis` (`:axial`, `:coronal`, `:sagittal`). The `slice_position` determines where the slice is taken.
The intensities `ti` can be specified using `CTSheppLoganIntensities()` (default) or `MRISheppLoganIntensities()`.

# Parameters
- `nx`, `ny`, `nz`: Number of voxels in x, y, and z dimensions for 3D phantom; for 2D slice, `nx` and `ny` are used.
- `fov`: Tuple specifying the field of view in each dimension (default is (20, 20, 20) for 3D and (20, 20) for 2D).
- `ti`: Shepp-Logan intensities, defaulting to `CTSheppLoganIntensities()`, but accepts `MRISheppLoganIntensities()` or any custom `SheppLoganIntensities` struct.
- `eltype`: Data type for the phantom array (default is `Float32`).
- `supersample`: Number of sample points per voxel along each in-plane (2D) or spatial (3D)
  dimension (default is `1`). Each voxel holds the mean of `supersample^D` point samples, spread
  evenly over the voxel, instead of the single sample at its centre. This approximates the
  average of the object over the voxel (area sampling), so edges get partial-volume values and
  the phantom's spectrum aliases far less, which matters when the phantom serves as ground truth
  for simulated k-space. A 2D slice is averaged in-plane only. Rendering takes `supersample^D`
  times as long; memory is that of two phantoms. Not available for mask phantoms.
"""
function create_shepp_logan_phantom(nx::Int, ny::Int, nz::Int; fov::Tuple{<:Real, <:Real, <:Real} = (20.0, 20.0, 20.0), ti::SheppLoganIntensities = CTSheppLoganIntensities(), eltype::Type = Float32, supersample::Integer = 1)
    is_mask = ti isa SheppLoganIntensities{Bool}
    check_supersample_eltype(supersample, is_mask)

    Δx, Δy, Δz = fov[1] / nx, fov[2] / ny, fov[3] / nz
    return render_supersampled(supersample, Val(3)) do offset
        ax_x = (range(-(nx - 1) / 2, (nx - 1) / 2, length = nx) .+ offset[1]) .* Δx
        ax_y = (range(-(ny - 1) / 2, (ny - 1) / 2, length = ny) .+ offset[2]) .* Δy
        ax_z = (range(-(nz - 1) / 2, (nz - 1) / 2, length = nz) .+ offset[3]) .* Δz

        ax_xn = ax_x ./ 8
        ax_yn = ax_y ./ 8
        ax_zn = ax_z ./ 8

        phantom = if is_mask
            falses(nx, ny, nz)
        else
            zeros(eltype, nx, ny, nz)
        end

        ctx = DrawContext3D(phantom, ax_xn, ax_yn, ax_zn)
        draw_shepp_logan_shapes!(ctx, ti)

        phantom
    end
end


function create_shepp_logan_phantom(nx::Int, ny::Int, axis::Symbol; fov::Tuple{<:Real, <:Real} = (20.0, 20.0), slice_position::Real = 0.0, ti::SheppLoganIntensities = CTSheppLoganIntensities(), eltype::Type = Float32, supersample::Integer = 1)
    # Use explicit if/elseif with literal Val symbols so JET can infer Val{:axial} etc.
    kw = (; fov, slice_position, ti, eltype, supersample)
    if axis === :axial
        return _create_shepp_logan_2d(nx, ny, Val(:axial); kw...)
    elseif axis === :coronal
        return _create_shepp_logan_2d(nx, ny, Val(:coronal); kw...)
    elseif axis === :sagittal
        return _create_shepp_logan_2d(nx, ny, Val(:sagittal); kw...)
    else
        throw(ArgumentError("axis must be :axial, :coronal, or :sagittal"))
    end
end

function _create_shepp_logan_2d(nx::Int, ny::Int, ::Val{A}; fov, slice_position, ti::SheppLoganIntensities, eltype::Type, supersample::Integer) where {A}
    is_mask = ti isa SheppLoganIntensities{Bool}
    check_supersample_eltype(supersample, is_mask)

    Δ1, Δ2 = fov[1] / nx, fov[2] / ny
    ax_3_val = slice_position ./ 8
    return render_supersampled(supersample, Val(2)) do offset
        ax_1 = (range(-(nx - 1) / 2, (nx - 1) / 2, length = nx) .+ offset[1]) .* Δ1
        ax_2 = (range(-(ny - 1) / 2, (ny - 1) / 2, length = ny) .+ offset[2]) .* Δ2

        ax_1n = ax_1 ./ 8
        ax_2n = ax_2 ./ 8

        phantom = if is_mask
            falses(nx, ny)
        else
            zeros(eltype, nx, ny)
        end

        # A is a compile-time constant here — DrawContext2D{A} is fully typed.
        ctx = DrawContext2D{A}(phantom, ax_1n, ax_2n, ax_3_val)
        draw_shepp_logan_shapes!(ctx, ti)

        phantom
    end
end
