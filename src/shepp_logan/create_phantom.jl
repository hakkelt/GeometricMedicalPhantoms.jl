
"""
    create_shepp_logan_phantom(nx, ny, nz; fovs=(20,20,20), ti=CTSheppLoganIntensities(), eltype=Float32)
    create_shepp_logan_phantom(nx, ny, axis; fovs=(20,20), slice_position=0.0, ti=CTSheppLoganIntensities(), eltype=Float32)

Generate a 3D Shepp-Logan phantom or a 2D slice of it.

For a 2D slice, provide `nx`, `ny`, and an `axis` (`:axial`, `:coronal`, `:sagittal`). The `slice_position` determines where the slice is taken.
The intensities `ti` can be specified using `CTSheppLoganIntensities()` (default) or `MRISheppLoganIntensities()`.

# Parameters
- `nx`, `ny`, `nz`: Number of voxels in x, y, and z dimensions for 3D phantom; for 2D slice, `nx` and `ny` are used.
- `fovs`: Tuple specifying the field of view in each dimension (default is (20, 20, 20) for 3D and (20, 20) for 2D).
- `ti`: Shepp-Logan intensities, defaulting to `CTSheppLoganIntensities()`, but accepts `MRISheppLoganIntensities()` or any custom `SheppLoganIntensities` struct.
- `eltype`: Data type for the phantom array (default is `Float32`).
"""
function create_shepp_logan_phantom(nx::Int, ny::Int, nz::Int; fovs::Tuple{<:Real,<:Real,<:Real}=(20.0, 20.0, 20.0), ti::SheppLoganIntensities=CTSheppLoganIntensities(), eltype::Type=Float32)
    is_mask = ti isa SheppLoganIntensities{Bool}
    
    Δx, Δy, Δz = fovs[1]/nx, fovs[2]/ny, fovs[3]/nz
    ax_x = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δx
    ax_y = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δy
    ax_z = range(-(nz-1)/2, (nz-1)/2, length=nz) .* Δz
    
    ax_xn = ax_x ./ 8
    ax_yn = ax_y ./ 8
    ax_zn = ax_z ./ 8

    phantom = if is_mask
        falses(nx, ny, nz)
    else
        zeros(eltype, nx, ny, nz)
    end

    shapes = get_shepp_logan_shapes(ti)
    for s in shapes
        draw!(phantom, ax_xn, ax_yn, ax_zn, s)
    end
    
    return phantom
end


function create_shepp_logan_phantom(nx::Int, ny::Int, axis::Symbol; fovs::Tuple{<:Real,<:Real}=(20.0, 20.0), slice_position::Real=0.0, ti::SheppLoganIntensities=CTSheppLoganIntensities(), eltype::Type=Float32)
    is_mask = ti isa SheppLoganIntensities{Bool}
    
    Δ1, Δ2 = fovs[1]/nx, fovs[2]/ny
    ax_1 = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δ1
    ax_2 = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δ2
    
    ax_1n = ax_1 ./ 8
    ax_2n = ax_2 ./ 8
    ax_3_val = slice_position ./ 8
    
    phantom = if is_mask
        falses(nx, ny)
    else
        zeros(eltype, nx, ny)
    end

    shapes = get_shepp_logan_shapes(ti)
    for s in shapes
        draw_2d!(phantom, ax_1n, ax_2n, ax_3_val, axis, s)
    end
    
    return phantom
end
