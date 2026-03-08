function create_torso_phantom(nx::Int, ny::Int, axis::Symbol; fovs = (30, 30), slice_position::Real = 0.0, respiratory_signal = nothing, cardiac_volumes = nothing, ti::AbstractTissueParameters = TissueIntensities(), eltype::Type{T} = Float32) where {T}
    # 1) Validate inputs
    if nx <= 0 || ny <= 0
        throw(ArgumentError("nx, ny must be positive integers"))
    end
    length(fovs) == 2 || throw(ArgumentError("fovs must have 2 elements for 2D phantom"))
    # Use explicit if/elseif with literal Val symbols so JET can infer Val{:axial} etc.
    # Pass eltype as a POSITIONAL arg (not keyword) so Type{T} specialization is preserved;
    # keyword arguments are bundled into a NamedTuple at the call site, which widens
    # Type{Float32} → DataType and breaks the ::Type{T} dispatch in preallocate_phantom_array.
    if axis === :axial
        return _create_torso_phantom_2d(nx, ny, Val(:axial), eltype; fovs = fovs, slice_position = slice_position, respiratory_signal = respiratory_signal, cardiac_volumes = cardiac_volumes, ti = ti)
    elseif axis === :coronal
        return _create_torso_phantom_2d(nx, ny, Val(:coronal), eltype; fovs = fovs, slice_position = slice_position, respiratory_signal = respiratory_signal, cardiac_volumes = cardiac_volumes, ti = ti)
    elseif axis === :sagittal
        return _create_torso_phantom_2d(nx, ny, Val(:sagittal), eltype; fovs = fovs, slice_position = slice_position, respiratory_signal = respiratory_signal, cardiac_volumes = cardiac_volumes, ti = ti)
    else
        throw(ArgumentError("axis must be :axial, :coronal, or :sagittal"))
    end
end

function _create_torso_phantom_2d(nx::Int, ny::Int, ::Val{A}, eltype::Type{T}; fovs, slice_position, respiratory_signal, cardiac_volumes, ti::AbstractTissueParameters) where {A, T}
    # 2) Setup motion signals and parameters
    ax_1n, ax_2n, ax_3_val = define_phantom_axes_2d(nx, ny, fovs, slice_position)
    respiratory_signal, cardiac_volumes, nt = setup_and_validate_motion_signals(respiratory_signal, cardiac_volumes)
    lv_scales, rv_scales, la_scales, ra_scales, cardiac_scales_max = precompute_cardiac_scales(cardiac_volumes, nt)

    # 3) Allocate output phantom array
    phantom3d, static_image = preallocate_phantom_array(nx, ny, nt, eltype, ti)
    static_bone_mask = fill(false, nx, ny)

    # 4) Create drawing context — A is now a compile-time constant
    ctx = DrawContext2D{A}(static_image, ax_1n, ax_2n, ax_3_val)
    ctx_bone = DrawContext2D{A}(static_bone_mask, ax_1n, ax_2n, ax_3_val)

    # 5) Draw static structures once
    draw_torso_static_shapes!(ctx, ti)
    draw_static_bones!(ctx_bone, MaskingIntensityValue(true))
    static_bones_indices = findall(static_bone_mask)

    # 6) Draw dynamic structures for each time frame
    if nt == 1
        cardiac_scales = (lv = lv_scales[1], rv = rv_scales[1], la = la_scales[1], ra = ra_scales[1])
        motion_params = calculate_motion_parameters(respiratory_signal[1], cardiac_scales, cardiac_scales_max)
        draw_dynamic_shapes!(ctx, motion_params, ti)
        static_image[static_bones_indices] .= ti.bones  # Draw bones last to overlay
        phantom3d[:, :, 1] .= static_image
    else
        @batch threadlocal = similar(static_image) for m in 1:nt
            cardiac_scales = CardiacScales(lv_scales[m], rv_scales[m], la_scales[m], ra_scales[m])
            motion_params = calculate_motion_parameters(respiratory_signal[m], cardiac_scales, cardiac_scales_max)
            frame = threadlocal
            copyto!(frame, static_image)
            draw_dynamic_shapes!(DrawContext2D{A}(frame, ax_1n, ax_2n, ax_3_val), motion_params, ti)
            frame[static_bones_indices] .= ti.bones  # Draw bones last to overlay
            phantom3d[:, :, m] .= frame
        end
    end
    return to_bitarray_if_mask(phantom3d, ti)
end

"""
Helper function to define 2D coordinate axes for phantom slice generation.
Returns (ax_1n, ax_2n, ax_3_val) based on slice orientation.
"""
function define_phantom_axes_2d(nx::Int, ny::Int, fovs::Tuple, slice_position::Real)
    # Create axes for the two in-plane dimensions
    Δ1, Δ2 = fovs[1] / nx, fovs[2] / ny
    ax_1 = range(-(nx - 1) / 2, (nx - 1) / 2, length = nx) .* Δ1
    ax_2 = range(-(ny - 1) / 2, (ny - 1) / 2, length = ny) .* Δ2

    # Normalize to [-1, 1] range
    ax_1n = @. 2 * ax_1 / 30
    ax_2n = @. 2 * ax_2 / 30
    ax_3_val = 2 * slice_position / 30  # Normalized slice position

    return (ax_1n, ax_2n, ax_3_val)
end

function preallocate_phantom_array(nx, ny, nt, ::Type{T}, ::TissueMask) where {T}
    return Array{Bool, 3}(undef, nx, ny, nt), fill(false, nx, ny)
end

function preallocate_phantom_array(nx, ny, nt, ::Type{T}, ::AbstractTissueParameters) where {T}
    return Array{T, 3}(undef, nx, ny, nt), zeros(T, nx, ny)
end

"""
Helper function to draw static bones onto a 2D slice via DrawContext2D.
"""
function draw_static_bones!(ctx::DrawContext2D, bone_intensity)
    draw_arm_bones!(ctx, bone_intensity)
    draw_spine!(ctx, bone_intensity)
    return nothing
end
