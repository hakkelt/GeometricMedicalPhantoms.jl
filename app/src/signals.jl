function read_numeric_csv(path::String)
    lines = [strip(line) for line in readlines(path) if !isempty(strip(line))]
    isempty(lines) && error("CSV file is empty: $path")

    first_tokens = [strip(tok) for tok in split(lines[1], ',')]
    has_header = any(tok -> tryparse(Float64, tok) === nothing, first_tokens)
    header = has_header ? lowercase.(first_tokens) : nothing

    start_idx = has_header ? 2 : 1
    data_rows = Vector{Vector{Float64}}()
    expected_cols = length(first_tokens)

    for line in lines[start_idx:end]
        tokens = [strip(tok) for tok in split(line, ',')]
        if length(tokens) != expected_cols
            error("Inconsistent CSV column count in $path")
        end
        vals = Vector{Float64}(undef, expected_cols)
        for idx in eachindex(tokens)
            parsed = tryparse(Float64, tokens[idx])
            parsed === nothing && error("file entry \"$(tokens[idx])\" cannot be converted to Float64")
            vals[idx] = parsed
        end
        push!(data_rows, vals)
    end

    isempty(data_rows) && error("CSV file contains no numeric rows: $path")
    mat = permutedims(reduce(hcat, data_rows))
    return mat, header
end

function load_signal_vector(path::Union{Nothing, String})
    if path === nothing
        return nothing
    end
    ext = lowercase(splitext(path)[2])
    if ext == ".json"
        obj = JSON3.read(read(path, String))
        if obj isa JSON3.Array
            converted = to_symbol_dict(obj)
            return collect(Float64, converted)
        end
        dict = to_symbol_dict(obj)
        if dict isa Dict && haskey(dict, :signal)
            return collect(Float64, dict[:signal])
        end
        error("Respiratory JSON must be an array or include a 'signal' field")
    elseif ext == ".csv"
        data, header = read_numeric_csv(path)
        if header !== nothing
            signal_idx = findfirst(==("signal"), header)
            if signal_idx !== nothing
                return vec(data[:, signal_idx])
            end
            t_idx = findfirst(==("t"), header)
            if t_idx !== nothing && size(data, 2) == 2
                return vec(data[:, 3 - t_idx])
            end
        end
        if size(data, 2) == 1
            return vec(data[:, 1])
        end
        return vec(data[:, end])
    elseif ext == ".npy"
        return read_npz_single(path)
    else
        error("Unsupported respiratory signal format: $ext")
    end
end

function load_cardiac_volumes(path::Union{Nothing, String})
    if path === nothing
        return nothing
    end
    ext = lowercase(splitext(path)[2])
    return if ext == ".json"
        obj = JSON3.read(read(path, String))
        dict = to_symbol_dict(obj)
        if dict isa Dict
            return (
                lv = collect(Float64, dict[:lv]),
                rv = collect(Float64, dict[:rv]),
                la = collect(Float64, dict[:la]),
                ra = collect(Float64, dict[:ra]),
            )
        end
        error("Cardiac JSON must be a dictionary with lv, rv, la, ra fields")
    elseif ext == ".csv"
        data, header = read_numeric_csv(path)
        if header !== nothing
            required = ["lv", "rv", "la", "ra"]
            if all(name -> name in header, required)
                idx_lv = findfirst(==("lv"), header)
                idx_rv = findfirst(==("rv"), header)
                idx_la = findfirst(==("la"), header)
                idx_ra = findfirst(==("ra"), header)
                return (
                    lv = vec(data[:, idx_lv]),
                    rv = vec(data[:, idx_rv]),
                    la = vec(data[:, idx_la]),
                    ra = vec(data[:, idx_ra]),
                )
            end
        end

        if size(data, 2) == 4
            return (lv = vec(data[:, 1]), rv = vec(data[:, 2]), la = vec(data[:, 3]), ra = vec(data[:, 4]))
        elseif size(data, 2) >= 5
            return (lv = vec(data[:, 2]), rv = vec(data[:, 3]), la = vec(data[:, 4]), ra = vec(data[:, 5]))
        end
        error("Cardiac CSV must have 4 columns (lv, rv, la, ra) or 5 columns with leading time (t, lv, rv, la, ra)")
    else
        error("Unsupported cardiac signal format: $ext")
    end
end

function parse_respiratory_physiology(value::Union{Nothing, String})
    if value === nothing
        return RespiratoryPhysiology()
    end
    return RespiratoryPhysiology(; json_kwargs(value)...)
end

function parse_cardiac_physiology(value::Union{Nothing, String})
    if value === nothing
        return CardiacPhysiology()
    end
    return CardiacPhysiology(; json_kwargs(value)...)
end
