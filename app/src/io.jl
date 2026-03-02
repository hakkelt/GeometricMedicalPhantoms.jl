function save_output(path::String, format::String, data; plane::Union{Nothing, Symbol} = nothing)
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
        save_tiff(path, data; plane = plane)
    elseif fmt == "gif"
        if !GIF_SUPPORTED
            error("GIF output is not supported on Windows in the CLI app.")
        end
        save_gif(path, data)
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
    PNGFiles.save(path, img)
    return nothing
end

function save_tiff(path::String, data; plane::Union{Nothing, Symbol} = nothing)
    if ndims(data) == 2
        img = prepare_image_2d(data)
        TiffImages.save(path, img)
    elseif ndims(data) == 3
        img = prepare_image_3d(tiff_stack_by_plane(data, plane))
        TiffImages.save(path, img)
    elseif ndims(data) == 4
        reshaped = tiff_stack_by_plane(data, plane)
        img = prepare_image_3d(reshaped)
        TiffImages.save(path, img)
    else
        error("TIFF output requires a 2D, 3D, or 4D array.")
    end
    return nothing
end

function tiff_stack_by_plane(data::AbstractArray{T, 3}, plane::Union{Nothing, Symbol}) where {T}
    selected_plane = plane === nothing ? :axial : plane
    if selected_plane == :axial
        return data
    elseif selected_plane == :coronal
        return permutedims(data, (1, 3, 2))
    elseif selected_plane == :sagittal
        return permutedims(data, (2, 3, 1))
    end
    error("Unsupported plane for TIFF export: $selected_plane")
end

function tiff_stack_by_plane(data::AbstractArray{T, 4}, plane::Union{Nothing, Symbol}) where {T}
    selected_plane = plane === nothing ? :axial : plane
    if selected_plane == :axial
        sz = size(data)
        return reshape(data, sz[1], sz[2], sz[3] * sz[4])
    elseif selected_plane == :coronal
        reoriented = permutedims(data, (1, 3, 2, 4))
        sz = size(reoriented)
        return reshape(reoriented, sz[1], sz[2], sz[3] * sz[4])
    elseif selected_plane == :sagittal
        reoriented = permutedims(data, (2, 3, 1, 4))
        sz = size(reoriented)
        return reshape(reoriented, sz[1], sz[2], sz[3] * sz[4])
    end
    error("Unsupported plane for TIFF export: $selected_plane")
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

function save_gif(path::String, data)
    if !GIF_SUPPORTED
        error("GIF output is not supported on Windows in the CLI app.")
    end

    # Handle both 3D (x, y, time) and 4D (x, y, 1, time) data
    if ndims(data) == 3
        # 3D case: (x, y, time) - perfect for GIF
        frames_2d = data
    elseif ndims(data) == 4
        if size(data, 3) != 1
            error("GIF output is only supported for 2D images (single z-slice per frame). Got z-dimension of size $(size(data, 3)). Use (x, y, 1, time) shape for GIF output.")
        end
        # Extract 2D frames: (x, y, 1, t) -> (x, y, t)
        frames_2d = dropdims(data, dims = 3)
    else
        error("GIF output requires a 3D array (x, y, time) for 2D images or 4D array (x, y, 1, time) for 3D images with single z-slice. Got $(ndims(data))D array.")
    end

    # Normalize globally across all frames
    values = real.(frames_2d)
    min_val = minimum(values)
    max_val = maximum(values)
    if max_val == min_val
        frames_normalized = fill(0.0, size(values))
    else
        frames_normalized = (values .- min_val) ./ (max_val - min_val)
    end
    frames_normalized = clamp.(frames_normalized, 0.0, 1.0)

    # Convert to RGB for GIFImages (requires RGB{N0f8})
    num_frames = size(frames_normalized, 3)
    frames_rgb = Vector{Matrix{RGB{N0f8}}}(undef, num_frames)
    for t in 1:num_frames
        frame_gray = Gray.(N0f8.(frames_normalized[:, :, t]))
        frames_rgb[t] = RGB.(frame_gray)
    end

    # Write GIF using GIFImages
    try
        frames_array = Array{RGB{N0f8}, 3}(undef, size(frames_rgb[1], 1), size(frames_rgb[1], 2), num_frames)
        for t in 1:num_frames
            frames_array[:, :, t] = frames_rgb[t]
        end
        GIFImages.gif_encode(path, frames_array)
    catch e
        error("Failed to save GIF file: $e")
    end
    return nothing
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
    preferred = ["t", "signal", "lv", "rv", "la", "ra"]
    all_keys = collect(keys(data))
    ordered_keys = String[]
    for key in preferred
        if key in all_keys
            push!(ordered_keys, key)
        end
    end
    remaining = sort([k for k in all_keys if !(k in ordered_keys)])
    append!(ordered_keys, remaining)

    rows = length(data[ordered_keys[1]])
    mat = zeros(Float64, rows, length(ordered_keys))
    for (idx, key) in enumerate(ordered_keys)
        mat[:, idx] = data[key]
    end
    header = join(ordered_keys, ",")
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
