"""
    create_torso_phantom(nx::Int, ny::Int, nz::Int; fov=(30, 30, 30), respiratory_signal=nothing, cardiac_volumes=nothing, ti::AbstractTissueParameters=TissueIntensities(), eltype=Float32) -> Array{eltype, 4}
    create_torso_phantom(nx::Int, ny::Int, axis::Symbol; fov=(30, 30), slice_position=0.0, eltype=Float32) -> Array{eltype, 3}

Generate a 3D torso phantom with anatomical structures including torso outline, lungs, heart, and vessels.

# Arguments
- `nx::Int=128`: Number of voxels in x-direction
- `ny::Int=128`: Number of voxels in y-direction  
- `nz::Int=128`: Number of voxels in z-direction (ignored for 2D slice generation)
- `axis::Symbol`: Slice orientation for 2D phantom - `:axial`, `:coronal`, or `:sagittal` (ignored for 3D phantom)

# Keywords
- `fov::Tuple=(30, 30, 30)`: Field of view in cm for (x, y, z) directions for 3D phantom; for 2D phantom, only first two elements are used
- `slice_position::Real=0.0`: Position of the slice in cm (in the third dimension) for 2D phantom generation; ignored for 3D phantom
- `respiratory_signal::Union{Nothing,AbstractVector}=nothing`: Respiratory signal in liters for 4D phantom generation
- `cardiac_volumes::Union{Nothing,NamedTuple}=nothing`: Cardiac volumes in mL for 4D phantom generation; must have fields :lv, :rv, :la, :ra
- `ti::AbstractTissueParameters=TissueIntensities()`: Tissue parameters (TissueIntensities or TissueMask) for different structures
- `eltype=Float32`: Element type for the generated phantom array (Float32, Float64, ComplexF32, ComplexF64, etc.). When TissueMask is passed, returns BitArray regardless of eltype.

# Returns
- Array{eltype, 4}: 4D phantom array with size (nx, ny, nz, nt) where nt is the number of time frames. Returns BitArray when TissueMask is passed.
- Array{eltype, 3}: 3D phantom array with size (nx, ny, nz) for static phantom or 2D slice array with size (nx, ny) for 2D phantom generation.

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
function create_torso_phantom(nx::Int = 128, ny::Int = 128, nz::Int = 128; fov = (30, 30, 30), respiratory_signal = nothing, cardiac_volumes = nothing, ti::AbstractTissueParameters = TissueIntensities(), eltype::Type{T} = Float32) where {T}
    # 1) Validate inputs
    if nx <= 0 || ny <= 0 || nz <= 0
        throw(ArgumentError("nx, ny, nz must be positive integers"))
    end
    length(fov) == 3 || throw(ArgumentError("fov must have 3 elements for 3D phantom"))

    # 2) Allocate output phantom array
    resp_length = isnothing(respiratory_signal) ? 1 : length(respiratory_signal)
    cardiac_length = isnothing(cardiac_volumes) ? 1 : length(cardiac_volumes.lv)
    nt = max(resp_length, cardiac_length)
    phantom4d, static_image = preallocate_phantom_array(nx, ny, nz, nt, eltype, ti)
    static_bones_mask = fill(false, nx, ny, nz)

    draw_3D_torso_phantom!(phantom4d, static_image, static_bones_mask, fov, ti, respiratory_signal, cardiac_volumes)
    return to_bitarray_if_mask(phantom4d, ti)
end

function preallocate_phantom_array(nx, ny, nz, nt, ::Type{T}, ::TissueMask) where {T}
    return Array{Bool, 4}(undef, nx, ny, nz, nt), fill(false, nx, ny, nz)
end

function preallocate_phantom_array(nx, ny, nz, nt, ::Type{T}, ::AbstractTissueParameters) where {T}
    return Array{T, 4}(undef, nx, ny, nz, nt), zeros(T, nx, ny, nz)
end

function to_bitarray_if_mask(phantom, ::TissueMask)
    return BitArray(phantom)
end

function to_bitarray_if_mask(phantom, ::AbstractTissueParameters)
    return phantom
end

function draw_3D_torso_phantom!(phantom4d, static_image, static_bones_mask, fov, ti, respiratory_signal, cardiac_volumes)
    # 3) Setup motion signals and parameters
    nx, ny, nz, nt = size(phantom4d)
    ax_xn, ax_yn, ax_zn = define_phantom_axes(nx, ny, nz, fov)
    respiratory_signal, cardiac_volumes, nt = setup_and_validate_motion_signals(respiratory_signal, cardiac_volumes)
    lv_scales, rv_scales, la_scales, ra_scales, cardiac_scales_max = precompute_cardiac_scales(cardiac_volumes, nt)

    # 4) Draw static structures once
    ctx = DrawContext3D(static_image, ax_xn, ax_yn, ax_zn)
    ctx_bone = DrawContext3D(static_bones_mask, ax_xn, ax_yn, ax_zn)
    draw_torso_static_shapes!(ctx, ti)
    draw_static_bones!(ctx_bone, MaskingIntensityValue(true))
    static_bones_indices = findall(static_bones_mask)

    # 5) Draw dynamic structures for each time frame
    if nt == 1
        cardiac_scales = (lv = lv_scales[1], rv = rv_scales[1], la = la_scales[1], ra = ra_scales[1])
        motion_params = calculate_motion_parameters(respiratory_signal[1], cardiac_scales, cardiac_scales_max)
        draw_dynamic_shapes!(DrawContext3D(static_image, ax_xn, ax_yn, ax_zn), motion_params, ti)
        static_image[static_bones_indices] .= ti.bones  # Draw bones last to overlay
        phantom4d[:, :, :, 1] .= static_image
    else
        @batch threadlocal = similar(static_image) for m in 1:nt
            cardiac_scales = CardiacScales(lv_scales[m], rv_scales[m], la_scales[m], ra_scales[m])
            motion_params = calculate_motion_parameters(respiratory_signal[m], cardiac_scales, cardiac_scales_max)
            frame = threadlocal
            copyto!(frame, static_image)
            draw_dynamic_shapes!(DrawContext3D(frame, ax_xn, ax_yn, ax_zn), motion_params, ti)
            frame[static_bones_indices] .= ti.bones  # Draw bones last to overlay
            phantom4d[:, :, :, m] .= frame
        end
    end
    return
end

"""
Helper function to define coordinate axes for phantom generation.
Returns normalized axes in the range [-1, 1].
"""
function define_phantom_axes(nx::Int, ny::Int, nz::Int, fov::Tuple)
    Δx, Δy, Δz = fov[1] / nx, fov[2] / ny, fov[3] / nz
    ax_x = range(-(nx - 1) / 2, (nx - 1) / 2, length = nx) .* Δx
    ax_y = range(-(ny - 1) / 2, (ny - 1) / 2, length = ny) .* Δy
    ax_z = range(-(nz - 1) / 2, (nz - 1) / 2, length = nz) .* Δz

    # Normalize to [-1, 1] range for easier ellipsoid definitions
    ax_xn = @. 2 * ax_x / 30
    ax_yn = @. 2 * ax_y / 30
    ax_zn = @. 2 * ax_z / 30

    return (ax_xn, ax_yn, ax_zn)
end

"""
Helper function to draw static bone structures via DrawContext3D.
"""
function draw_static_bones!(ctx::DrawContext3D, bone_intensity)
    draw_arm_bones!(ctx, bone_intensity)
    draw_spine!(ctx, bone_intensity)
    return nothing
end
