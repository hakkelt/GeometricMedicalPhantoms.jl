
"""
    create_shepp_logan_phantom(nx::Int, ny::Int, nz::Int; fovs=(20,20,20), ti::SheppLoganIntensities=CTSheppLoganIntensities(), eltype=Float32)

Generate a 3D Shepp-Logan phantom.
"""
function create_shepp_logan_phantom(nx::Int, ny::Int, nz::Int; fovs=(20, 20, 20), ti::SheppLoganIntensities=CTSheppLoganIntensities(), eltype=Float32)
    is_mask = ti isa SheppLoganIntensities{Bool}
    
    Δx, Δy, Δz = fovs[1]/nx, fovs[2]/ny, fovs[3]/nz
    ax_x = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δx
    ax_y = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δy
    ax_z = range(-(nz-1)/2, (nz-1)/2, length=nz) .* Δz
    
    # Standard Shepp-Logan is defined on [-1, 1] but usually in [-0.5, 0.5] if radii are small?
    # In ImagePhantoms.jl, the range is [-0.5, 0.5].
    # Our normalization in torso was 2 * ax / 30.
    # For Shepp-Logan, we'll use ax as is if the user wants [-fov/2, fov/2].
    # But the parameters from ImagePhantoms are for a FOV of 1 (range -0.5 to 0.5).
    # So we should normalize by fov.
    
    ax_xn = ax_x ./ fovs[1] .* 2
    ax_yn = ax_y ./ fovs[2] .* 2
    ax_zn = ax_z ./ fovs[3] .* 2

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

"""
    create_shepp_logan_phantom(nx::Int, ny::Int, axis::Symbol; fovs=(20, 20), slice_position=0.0, ti::SheppLoganIntensities=CTSheppLoganIntensities(), eltype=Float32)

Generate a 2D slice of a Shepp-Logan phantom.
"""
function create_shepp_logan_phantom(nx::Int, ny::Int, axis::Symbol; fovs=(20, 20), slice_position::Real=0.0, ti::SheppLoganIntensities=CTSheppLoganIntensities(), eltype=Float32)
    is_mask = ti isa SheppLoganIntensities{Bool}
    
    Δ1, Δ2 = fovs[1]/nx, fovs[2]/ny
    ax_1 = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δ1
    ax_2 = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δ2
    
    # Normalize to FOV 1
    ax_1n = ax_1 ./ fovs[1] .* 2
    ax_2n = ax_2 ./ fovs[2] .* 2
    # For slice position, we assume it's relative to the 3rd dimension FOV which is 1 by default.
    ax_3_val = slice_position ./ 10
    
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
