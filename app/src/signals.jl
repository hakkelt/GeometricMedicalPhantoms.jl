function load_signal_vector(path::Union{Nothing,String})
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
        data = readdlm(path, ',', Float64; header=false)
        if data isa AbstractMatrix
            return vec(data)
        else
            error("Unexpected CSV format")
        end
    elseif ext == ".npy"
        return read_npz_single(path)
    else
        error("Unsupported respiratory signal format: $ext")
    end
end

function load_cardiac_volumes(path::Union{Nothing,String})
    if path === nothing
        return nothing
    end
    ext = lowercase(splitext(path)[2])
    if ext == ".json"
        obj = JSON3.read(read(path, String))
        dict = to_symbol_dict(obj)
        if dict isa Dict
            return (
                lv=collect(Float64, dict[:lv]),
                rv=collect(Float64, dict[:rv]),
                la=collect(Float64, dict[:la]),
                ra=collect(Float64, dict[:ra])
            )
        end
        error("Cardiac JSON must be a dictionary with lv, rv, la, ra fields")
    elseif ext == ".csv"
        data = readdlm(path, ',', Float64; header=false)
        if data isa AbstractMatrix
            if size(data, 2) < 4
                error("Cardiac CSV must have 4 columns: lv, rv, la, ra")
            end
            return (lv=vec(data[:, 1]), rv=vec(data[:, 2]), la=vec(data[:, 3]), ra=vec(data[:, 4]))
        else
            error("Unexpected CSV format")
        end
    else
        error("Unsupported cardiac signal format: $ext")
    end
end

function parse_respiratory_physiology(value::Union{Nothing,String})
    if value === nothing
        return RespiratoryPhysiology()
    end
    return RespiratoryPhysiology(; json_kwargs(value)...) 
end

function parse_cardiac_physiology(value::Union{Nothing,String})
    if value === nothing
        return CardiacPhysiology()
    end
    return CardiacPhysiology(; json_kwargs(value)...) 
end
