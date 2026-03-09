function build_shepp_logan(size_vec; plane, slice_position, intensity, mask, fov)
    ti = if mask !== nothing
        SheppLoganMask(; json_kwargs(mask)...)
    elseif intensity === nothing
        CTSheppLoganIntensities()
    else
        value = lowercase(strip(intensity))
        if value == "ct"
            CTSheppLoganIntensities()
        elseif value == "mri"
            MRISheppLoganIntensities()
        elseif value == "default"
            SheppLoganIntensities()
        else
            SheppLoganIntensities(; json_kwargs(intensity)...)
        end
    end

    if length(size_vec) == 2
        plane = plane === nothing ? :axial : plane
        kwargs = fov === nothing ? (; slice_position = slice_position, ti = ti) : (; fov = Tuple(fov), slice_position = slice_position, ti = ti)
        return create_shepp_logan_phantom(size_vec[1], size_vec[2], plane; kwargs...)
    end

    kwargs = fov === nothing ? (; ti = ti) : (; fov = Tuple(fov), ti = ti)
    return create_shepp_logan_phantom(size_vec[1], size_vec[2], size_vec[3]; kwargs...)
end

function build_torso(size_vec; plane, slice_position, intensity, mask, resp_signal, cardiac_signal, fov)
    ti = if mask !== nothing
        TissueMask(; json_kwargs(mask)...)
    elseif intensity !== nothing
        TissueIntensities(; json_kwargs(intensity)...)
    else
        TissueIntensities()
    end

    resp = load_signal_vector(resp_signal)
    cardiac = load_cardiac_volumes(cardiac_signal)

    if length(size_vec) == 2
        plane = plane === nothing ? :axial : plane
        kwargs = fov === nothing ? (; slice_position = slice_position, respiratory_signal = resp, cardiac_volumes = cardiac, ti = ti) : (; fov = Tuple(fov), slice_position = slice_position, respiratory_signal = resp, cardiac_volumes = cardiac, ti = ti)
        return create_torso_phantom(size_vec[1], size_vec[2], plane; kwargs...)
    end

    kwargs = fov === nothing ? (; respiratory_signal = resp, cardiac_volumes = cardiac, ti = ti) : (; fov = Tuple(fov), respiratory_signal = resp, cardiac_volumes = cardiac, ti = ti)
    return create_torso_phantom(size_vec[1], size_vec[2], size_vec[3]; kwargs...)
end

function build_tubes(size_vec; plane, slice_position, intensity, geometry, stack, fov)
    tg = geometry === nothing ? TubesGeometry() : TubesGeometry(; json_kwargs(geometry)...)

    if stack !== nothing
        stack_values = json_to_value(stack)
        if !(stack_values isa Vector)
            error("--stack must be a JSON array of intensity objects")
        end
        ti = [TubesIntensities(; json_kwargs(entry)...) for entry in stack_values]
    elseif intensity !== nothing
        ti = TubesIntensities(; json_kwargs(intensity)...)
    else
        ti = TubesIntensities()
    end

    if length(size_vec) == 2
        plane = plane === nothing ? :axial : plane
        kwargs = fov === nothing ? (; slice_position = slice_position, tg = tg, ti = ti) : (; fov = Tuple(fov), slice_position = slice_position, tg = tg, ti = ti)
        return create_tubes_phantom(size_vec[1], size_vec[2], plane; kwargs...)
    end

    kwargs = fov === nothing ? (; tg = tg, ti = ti) : (; fov = Tuple(fov), tg = tg, ti = ti)
    return create_tubes_phantom(size_vec[1], size_vec[2], size_vec[3]; kwargs...)
end
