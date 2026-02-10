function parse_size(value::String)
    parts = split(value, ",")
    dims = [parse(Int, strip(p)) for p in parts if !isempty(strip(p))]
    if length(dims) < 2 || length(dims) > 3
        error("--size must have 2 or 3 integers")
    end
    return dims
end

function parse_plane(value::Union{Nothing,String})
    if value === nothing
        return nothing
    end
    key = lowercase(strip(value))
    if haskey(PLANE_MAP, key)
        return PLANE_MAP[key]
    end
    error("Unsupported plane: $value")
end

function resolve_format(format::Union{Nothing,String}, out_path::String)
    if format !== nothing
        key = lowercase(strip(format))
        return get(FORMAT_ALIASES, key, key)
    end

    lower_out = lowercase(out_path)
    ext = lowercase(splitext(out_path)[2])
    if ext == ".npy"
        return "npy"
    elseif ext == ".mat"
        return "mat"
    elseif ext == ".png"
        return "png"
    elseif ext == ".tiff" || ext == ".tif"
        return "tiff"
    elseif ext == ".nii" || endswith(lower_out, ".nii.gz")
        return "nifti"
    end

    error("Cannot infer format from --out. Please provide --format.")
end

function resolve_signal_format(format::Union{Nothing,String}, out_path::String)
    if format !== nothing
        return lowercase(strip(format))
    end
    ext = lowercase(splitext(out_path)[2])
    if ext == ".csv"
        return "csv"
    elseif ext == ".json"
        return "json"
    elseif ext == ".npy"
        return "npy"
    end
    return "csv"
end

function json_to_value(value::Union{Nothing,String})
    if value === nothing
        return nothing
    end

    payload = if isfile(value)
        read(value, String)
    else
        value
    end

    return JSON3.read(payload)
end

function json_kwargs(value::Union{Nothing,String,JSON3.Object})
    obj = value isa JSON3.Object ? value : json_to_value(value)
    if obj === nothing
        return Dict{Symbol,Any}()
    end

    return to_symbol_dict(obj)
end

function to_symbol_dict(obj)
    if obj isa JSON3.Object
        return Dict(Symbol(k) => to_symbol_dict(v) for (k, v) in obj)
    elseif obj isa JSON3.Array
        return [to_symbol_dict(v) for v in obj]
    else
        return obj
    end
end

function as_complex_f32(data)
    if data isa AbstractArray{<:Complex}
        return ComplexF32.(data)
    end
    return ComplexF32.(data)
end
