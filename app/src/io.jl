function save_output(path::String, format::String, data)
    fmt = lowercase(format)
    if fmt == "npy"
        NPZ.npzwrite(path, Dict("phantom" => data))
    elseif fmt == "mat"
        MAT.matwrite(path, Dict("phantom" => data))
    elseif fmt == "cfl"
        if endswith(lowercase(path), ".cfl") || endswith(lowercase(path), ".hdr")
            error("For BART output, provide the base path without extension.")
        end
        BartIO.write_cfl(path, as_complex_f32(data))
    elseif fmt == "nifti"
        # Use NIfTI package directly for proper compressed NIfTI support
        nii = NIfTI.NIVolume(data)
        NIfTI.niwrite(path, nii)
    elseif fmt == "png"
        save_png(path, data)
    elseif fmt == "tiff"
        save_tiff(path, data)
    else
        error("Unsupported output format: $format")
    end
    return nothing
end

function save_png(path::String, data)
    if ndims(data) != 2
        error("PNG output requires a 2D array.")
    end
    img = prepare_png(data)
    FileIO.save(path, img)
    return nothing
end

function save_tiff(path::String, data)
    if ndims(data) == 2
        img = prepare_image_2d(data)
        FileIO.save(path, img)
    elseif ndims(data) == 3
        img = prepare_image_3d(data)
        FileIO.save(path, img)
    elseif ndims(data) == 4
        # For 4D data (e.g., 3D + time), reshape to 3D by stacking slices
        # Shape (x, y, z, t) -> (x, y, z*t)
        sz = size(data)
        reshaped = reshape(data, sz[1], sz[2], sz[3] * sz[4])
        img = prepare_image_3d(reshaped)
        FileIO.save(path, img)
    else
        error("TIFF output requires a 2D, 3D, or 4D array.")
    end
    return nothing
end

function prepare_png(data)
    return prepare_image_2d(data)
end

function prepare_image_2d(data)
    values = data
    if values isa AbstractArray{<:Complex}
        values = abs.(values)
    end
    values = Float64.(values)
    min_val = minimum(values)
    max_val = maximum(values)
    if max_val == min_val
        norm = fill(0.0, size(values))
    else
        norm = (values .- min_val) ./ (max_val - min_val)
    end
    norm = clamp.(norm, 0.0, 1.0)
    return Gray.(N0f8.(norm))
end

function prepare_image_3d(data)
    values = data
    if values isa AbstractArray{<:Complex}
        values = abs.(values)
    end
    values = Float64.(values)
    # Use global min/max across all slices for consistent normalization
    min_val = minimum(values)
    max_val = maximum(values)
    if max_val == min_val
        norm = fill(0.0, size(values))
    else
        norm = (values .- min_val) ./ (max_val - min_val)
    end
    norm = clamp.(norm, 0.0, 1.0)
    return Gray.(N0f8.(norm))
end

function save_signal(path::String, format::String, data::Dict)
    fmt = lowercase(format)
    if fmt == "csv"
        save_signal_csv(path, data)
    elseif fmt == "json"
        write_metadata(path, data)
    elseif fmt == "npy"
        if length(data) != 1
            error("NPY output supports a single array; use CSV or JSON for multi-series data.")
        end
        NPZ.npzwrite(path, Dict("signal" => first(values(data))))
    else
        error("Unsupported signal output format: $format")
    end
    return nothing
end

function save_signal_csv(path::String, data::Dict)
    keys_sorted = sort(collect(keys(data)))
    rows = length(data[keys_sorted[1]])
    mat = zeros(Float64, rows, length(keys_sorted))
    for (idx, key) in enumerate(keys_sorted)
        mat[:, idx] = data[key]
    end
    header = join(keys_sorted, ",")
    open(path, "w") do io
        println(io, header)
        writedlm(io, mat, ',')
    end
    return nothing
end

function write_metadata(path::String, data::Dict)
    open(path, "w") do io
        JSON3.write(io, data)
    end
    return nothing
end

function read_npz_single(path::String)
    obj = NPZ.npzread(path)
    if obj isa AbstractArray
        return obj
    end
    if obj isa Dict
        return first(values(obj))
    end
    error("Unexpected NPZ content in $path")
end
