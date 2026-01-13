"""
    create_torso_phantom(nx::Int=128, ny::Int=128, nz::Int=128; fovs=(30, 30, 30), eltype=Float32) -> Array{eltype, 4}

Generate a 3D torso phantom with anatomical structures including torso outline, lungs, heart, and vessels.

# Arguments
- `nx::Int=128`: Number of voxels in x-direction
- `ny::Int=128`: Number of voxels in y-direction  
- `nz::Int=128`: Number of voxels in z-direction

# Keywords
- `fovs::Tuple=(30, 30, 30)`: Field of view in cm for (x, y, z) directions
- `respiratory_signal::Union{Nothing,AbstractVector}=nothing`: Respiratory signal in liters for 4D phantom generation
- `cardiac_volumes::Union{Nothing,NamedTuple}=nothing`: Cardiac volumes in mL for 4D phantom generation; must have fields :lv, :rv, :la, :ra
- `ti::AbstractTissueParameters=TissueIntensities()`: Tissue parameters (TissueIntensities or TissueMask) for different structures
- `eltype=Float32`: Element type for the generated phantom array (Float32, Float64, ComplexF32, ComplexF64, etc.). When TissueMask is passed, returns BitArray regardless of eltype.

# Returns
- Array{eltype, 4}: 4D phantom array with size (nx, ny, nz, nt) where nt is the number of time frames. Returns BitArray when TissueMask is passed.

# Description
Creates a simplified anatomical torso phantom with the following structures:
- Torso: Multi-segment outer boundary (upper/middle/lower) for realistic shape
- Lungs: Multiple ellipsoids representing left/right lung lobes
- Heart: Multiple ellipsoids for ventricles and atria
- Vessels: Aorta, pulmonary artery, and superior vena cava
- Spine: Vertebral column with 12 vertebrae
- Ribs: Paired rib structures arranged in 9 levels
- Liver and Stomach: Basic ellipsoidal shapes in the abdomen

# Example
```julia
phantom = create_torso_phantom(128, 128, 128)  # Float32
phantom_f64 = create_torso_phantom(128, 128, 128; eltype=Float64)
phantom_complex = create_torso_phantom(128, 128, 128; eltype=ComplexF32)

# Create binary mask for lung tissue
lung_mask = TissueMask(lung=true)
phantom_mask = create_torso_phantom(128, 128, 128; ti=lung_mask)  # BitArray
```
"""
function create_torso_phantom(nx::Int=128, ny::Int=128, nz::Int=128; fovs=(30, 30, 30), respiratory_signal=nothing, cardiac_volumes=nothing, ti::AbstractTissueParameters=TissueIntensities(), eltype=Float32)
    # 1) Validate inputs
    if nx <= 0 || ny <= 0 || nz <= 0
        throw(ArgumentError("nx, ny, nz must be positive integers"))
    end
    length(fovs) == 3 || throw(ArgumentError("fovs must have 3 elements for 3D phantom"))
    
    # 2) Setup motion signals and parameters
    is_mask = ti isa TissueMask
    ax_xn, ax_yn, ax_zn = define_phantom_axes(nx, ny, nz, fovs)
    respiratory_signal, cardiac_volumes, nt = setup_and_validate_motion_signals(respiratory_signal, cardiac_volumes)
    lv_scales, rv_scales, la_scales, ra_scales, cardiac_scales_max = precompute_cardiac_scales(cardiac_volumes, nt)

    # 3) Allocate output phantom array
    phantom4d, static_image = if is_mask
        falses(nx, ny, nz, nt), falses(nx, ny, nz)
    else
        zeros(eltype, nx, ny, nz, nt), zeros(eltype, nx, ny, nz)
    end
    
    # 4) Draw static structures once
    draw_static_torso_parts!(static_image, ax_xn, ax_yn, ax_zn, ti)

    # 5) Draw dynamic structures for each time frame
    @threads for m in 1:nt
        cardiac_scales = (lv=lv_scales[m], rv=rv_scales[m], la=la_scales[m], ra=ra_scales[m])
        motion_params = calculate_motion_parameters(respiratory_signal[m], cardiac_scales, cardiac_scales_max)
        frame = view(phantom4d, :, :, :, m)
        draw_single_frame!(frame, static_image, ax_xn, ax_yn, ax_zn, motion_params, ti)
        draw_static_bones!(frame, ax_xn, ax_yn, ax_zn, ti)  # Draw bones last to overlay
    end
    return phantom4d
end

"""
Helper function to define coordinate axes for phantom generation.
Returns normalized axes in the range [-1, 1].
"""
function define_phantom_axes(nx::Int, ny::Int, nz::Int, fovs::Tuple)
    Δx, Δy, Δz = fovs[1]/nx, fovs[2]/ny, fovs[3]/nz
    ax_x = range(-(nx-1)/2, (nx-1)/2, length=nx) .* Δx
    ax_y = range(-(ny-1)/2, (ny-1)/2, length=ny) .* Δy
    ax_z = range(-(nz-1)/2, (nz-1)/2, length=nz) .* Δz
    
    # Normalize to [-1, 1] range for easier ellipsoid definitions
    ax_xn = @. 2 * ax_x / 30
    ax_yn = @. 2 * ax_y / 30
    ax_zn = @. 2 * ax_z / 30
    
    return (ax_xn, ax_yn, ax_zn)
end

"""
Helper function to draw static phantom structures onto an image.
"""
function draw_static_torso_parts!(image, ax_xn, ax_yn, ax_zn, ti::AbstractTissueParameters)
    for se in get_torso_static_parts(ti)
        draw!(image, ax_xn, ax_yn, ax_zn, se)
    end
    return image
end

"""
Helper function to draw static bone structures onto an image.
"""
function draw_static_bones!(image, ax_xn, ax_yn, ax_zn, ti::AbstractTissueParameters)
    for se in get_arm_bones(ti)
        draw!(image, ax_xn, ax_yn, ax_zn, se)
    end
    for se in get_spine(ti)
        draw!(image, ax_xn, ax_yn, ax_zn, se)
    end
    return image
end

"""
Helper function to draw a single dynamic frame.
"""
function draw_single_frame!(frame, static_image, ax_xn, ax_yn, ax_zn, motion_params::NamedTuple, ti::AbstractTissueParameters)
    copyto!(frame, static_image)
    dynamic_ellipsoids = define_dynamic_ellipsoids(motion_params, ti)
    for se in dynamic_ellipsoids
        draw!(frame, ax_xn, ax_yn, ax_zn, se)
    end
    return frame
end
