"""
    create_torso_phantom(nx::Int, ny::Int, axis::Symbol; fovs=(30, 30), slice_position=0.0, eltype=Float32) -> Array{eltype, 3}

Generate a 2D slice of a torso phantom with anatomical structures.

# Arguments
- `nx::Int`: Number of voxels in first dimension
- `ny::Int`: Number of voxels in second dimension  
- `axis::Symbol`: Slice orientation - `:axial`, `:coronal`, or `:sagittal`

# Keywords
- `fovs::Tuple=(30, 30)`: Field of view in cm for (x, y) directions
- `slice_position::Real=0.0`: Position of the slice in cm (in the third dimension)
- `respiratory_signal::Union{Nothing,AbstractVector}=nothing`: Respiratory signal in liters for time-varying phantom
- `cardiac_volumes::Union{Nothing,NamedTuple}=nothing`: Cardiac volumes in mL for time-varying phantom; must have fields :lv, :rv, :la, :ra
- `ti::AbstractTissueParameters=TissueIntensities()`: Tissue parameters (TissueIntensities or TissueMask)
- `eltype=Float32`: Element type for the generated phantom array

# Returns
- Array{eltype, 3}: 3D phantom array with size (nx, ny, nt) where nt is the number of time frames. Returns BitArray when TissueMask is passed.

# Description
Creates a 2D slice through the 3D torso phantom. The slice orientation is determined by the `axis` parameter:
- `:axial`: Horizontal slice (x-y plane), controlled by z-position
- `:coronal`: Front-to-back slice (x-z plane), controlled by y-position  
- `:sagittal`: Side-to-side slice (y-z plane), controlled by x-position

# Example
```julia
# Axial slice at heart level (z=0)
phantom_axial = create_torso_phantom(128, 128, :axial)

# Coronal slice through center
phantom_coronal = create_torso_phantom(128, 128, :coronal; slice_position=0.0)

# Sagittal slice, right of center
phantom_sagittal = create_torso_phantom(128, 128, :sagittal; slice_position=5.0)
```
"""
function create_torso_phantom(nx::Int, ny::Int, axis::Symbol; fovs=(30, 30), slice_position::Real=0.0, respiratory_signal=nothing, cardiac_volumes=nothing, ti::AbstractTissueParameters=TissueIntensities(), eltype=Float32)
    # 1) Validate inputs
    if nx <= 0 || ny <= 0
        throw(ArgumentError("nx, ny must be positive integers"))
    end
    length(fovs) == 2 || throw(ArgumentError("fovs must have 2 elements for 2D phantom"))
    axis in (:axial, :coronal, :sagittal) || throw(ArgumentError("axis must be :axial, :coronal, or :sagittal"))
    
    # 2) Setup motion signals and parameters
    is_mask = ti isa TissueMask
    ax_1n, ax_2n, ax_3_val = define_phantom_axes_2d(nx, ny, fovs, axis, slice_position)
    respiratory_signal, cardiac_volumes, nt = setup_and_validate_motion_signals(respiratory_signal, cardiac_volumes)
    lv_scales, rv_scales, la_scales, ra_scales, cardiac_scales_max = precompute_cardiac_scales(cardiac_volumes, nt)

    # 3) Allocate output phantom array
    phantom3d, static_image = if is_mask
        falses(nx, ny, nt), falses(nx, ny)
    else
        zeros(eltype, nx, ny, nt), zeros(eltype, nx, ny)
    end
    
    # 4) Draw static structures once
    draw_static_torso_parts!(static_image, ax_1n, ax_2n, ax_3_val, axis, ti)

    # 5) Draw dynamic structures for each time frame
    @threads for m in 1:nt
        cardiac_scales = (lv=lv_scales[m], rv=rv_scales[m], la=la_scales[m], ra=ra_scales[m])
        motion_params = calculate_motion_parameters(respiratory_signal[m], cardiac_scales, cardiac_scales_max)
        frame = view(phantom3d, :, :, m)
        draw_single_frame_2d!(frame, static_image, ax_1n, ax_2n, ax_3_val, axis, motion_params, ti)
        draw_static_bones_2d!(frame, ax_1n, ax_2n, ax_3_val, axis, ti)  # Draw bones last to overlay
    end
    return phantom3d
end

"""
Helper function to define 2D coordinate axes for phantom slice generation.
Returns (ax_1n, ax_2n, ax_3_val) based on slice orientation.
"""
function define_phantom_axes_2d(nx::Int, ny::Int, fovs::Tuple, axis::Symbol, slice_position::Real)
    # Create axes for the two in-plane dimensions
    Δ1, Δ2 = fovs[1]/nx, fovs[2]/ny
    ax_1 = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δ1
    ax_2 = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δ2
    
    # Normalize to [-1, 1] range
    ax_1n = @. 2 * ax_1 / 30
    ax_2n = @. 2 * ax_2 / 30
    ax_3_val = 2 * slice_position / 30  # Normalized slice position
    
    return (ax_1n, ax_2n, ax_3_val)
end

"""
Helper function to draw static 2D phantom structures onto an image.
"""
function draw_static_torso_parts!(image, ax_1n, ax_2n, ax_3_val, axis::Symbol, ti::AbstractTissueParameters)
    for se in get_torso_static_parts(ti)
        draw_2d!(image, ax_1n, ax_2n, ax_3_val, axis, se)
    end
    return image
end

"""
Helper function to draw static bones onto a 2D slice.
"""
function draw_static_bones_2d!(image, ax_1n, ax_2n, ax_3_val, axis::Symbol, ti::AbstractTissueParameters)
    for se in get_arm_bones(ti)
        draw_2d!(image, ax_1n, ax_2n, ax_3_val, axis, se)
    end
    for se in get_spine(ti)
        draw_2d!(image, ax_1n, ax_2n, ax_3_val, axis, se)
    end
    return image
end

"""
Helper function to draw a single 2D dynamic frame.
"""
function draw_single_frame_2d!(frame, static_image, ax_1n, ax_2n, ax_3_val, axis::Symbol, motion_params::NamedTuple, ti::AbstractTissueParameters)
    copyto!(frame, static_image)
    dynamic_ellipsoids = define_dynamic_ellipsoids(motion_params, ti)
    for se in dynamic_ellipsoids
        draw_2d!(frame, ax_1n, ax_2n, ax_3_val, axis, se)
    end
    return frame
end
