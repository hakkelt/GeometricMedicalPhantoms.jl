function main(args::Vector{String})
    if isempty(args)
        print_usage()
        return 1
    end

    command = args[1]
    rest = args[2:end]

    if command == "phantom"
        return run_phantom(rest)
    elseif command == "signals"
        return run_signals(rest)
    elseif command == "info"
        return run_info()
    else
        println("Unknown command: $command")
        print_usage()
        return 1
    end
end

function print_usage()
    println("Usage:")
    println("  geomphantoms phantom <type> --size <nx,ny[,nz]> [options]")
    println("  geomphantoms signals <type> [options]")
    println("  geomphantoms info")
    println()
    println("Phantoms: shepp-logan, torso, tubes")
    println("Signals: respiratory, cardiac")
end

function run_info()
    version = Base.pkgversion(GeometricMedicalPhantoms)
    println("GeometricMedicalPhantoms CLI")
    println("Package version: $(version)")
    println("Julia version: $(VERSION)")
    return 0
end

function run_phantom(args::Vector{String})
    s = ArgParseSettings(autofix_names=true)
    @add_arg_table! s begin
        "type"
            help = "shepp-logan | torso | tubes"
            required = true
        "--size"
            help = "Voxel size, e.g. 256,256,128"
            arg_type = String
            required = true
        "--plane"
            help = "Slice plane for 2D output: axial, coronal, sagittal"
            arg_type = String
        "--slice-position"
            help = "Slice position in cm for 2D output"
            arg_type = Float64
            default = 0.0
        "--out"
            help = "Output path"
            arg_type = String
            required = true
        "--format"
            help = "Output format: npy, mat, cfl, nifti, png"
            arg_type = String
        "--meta"
            help = "Metadata JSON path (defaults to <out>.json)"
            arg_type = String
        "--no-meta"
            help = "Disable metadata JSON output"
            action = :store_true
        "--intensity"
            help = "Intensity preset (ct/mri/default) or JSON (string or file path)"
            arg_type = String
        "--mask"
            help = "Mask JSON (string or file path)"
            arg_type = String
        "--geometry"
            help = "Geometry JSON (string or file path)"
            arg_type = String
        "--stack"
            help = "Stack of intensity JSON objects (string or file path)"
            arg_type = String
        "--resp-signal"
            help = "Respiratory signal (CSV/JSON/NPY file)"
            arg_type = String
        "--cardiac-signal"
            help = "Cardiac volumes (CSV/JSON file)"
            arg_type = String
    end

    parsed = parse_args(args, s; as_symbols=true)
    phantom_type = parsed[:type]
    if !(phantom_type in PHANTOM_TYPES)
        error("Unsupported phantom type: $phantom_type")
    end

    size_vec = parse_size(parsed[:size])
    plane = parse_plane(get(parsed, :plane, nothing))
    out_path = parsed[:out]
    format = resolve_format(get(parsed, :format, nothing), out_path)

    data = if phantom_type == "shepp-logan"
        build_shepp_logan(size_vec; plane=plane, slice_position=parsed[:slice_position], intensity=parsed[:intensity], mask=parsed[:mask])
    elseif phantom_type == "torso"
        build_torso(size_vec; plane=plane, slice_position=parsed[:slice_position], intensity=parsed[:intensity], mask=parsed[:mask], resp_signal=parsed[:resp_signal], cardiac_signal=parsed[:cardiac_signal])
    elseif phantom_type == "tubes"
        build_tubes(size_vec; plane=plane, slice_position=parsed[:slice_position], intensity=parsed[:intensity], geometry=parsed[:geometry], stack=parsed[:stack])
    else
        error("Unsupported phantom type: $phantom_type")
    end

    save_output(out_path, format, data)

    if !parsed[:no_meta]
        meta_path = get(parsed, :meta, nothing)
        if meta_path === nothing
            meta_path = out_path * ".json"
        end
        write_metadata(meta_path, Dict(
            "command" => "phantom",
            "type" => phantom_type,
            "size" => size_vec,
            "plane" => plane === nothing ? nothing : String(plane),
            "slice_position" => parsed[:slice_position],
            "format" => format,
            "output" => out_path,
            "timestamp" => string(Dates.now()),
            "package_version" => string(Base.pkgversion(GeometricMedicalPhantoms)),
            "julia_version" => string(VERSION),
        ))
    end

    return 0
end

function run_signals(args::Vector{String})
    s = ArgParseSettings(autofix_names=true)
    @add_arg_table! s begin
        "type"
            help = "respiratory | cardiac"
            required = true
        "--duration"
            help = "Duration in seconds"
            arg_type = Float64
            default = 10.0
        "--fs"
            help = "Sampling rate in Hz"
            arg_type = Float64
            default = 24.0
        "--rate"
            help = "Respiratory rate (breaths/min) or heart rate (beats/min)"
            arg_type = Float64
            default = NaN
        "--physiology"
            help = "Physiology JSON (string or file path)"
            arg_type = String
        "--out"
            help = "Output path"
            arg_type = String
            required = true
        "--format"
            help = "Output format: csv, json, npy"
            arg_type = String
    end

    parsed = parse_args(args, s; as_symbols=true)
    signal_type = parsed[:type]
    if !(signal_type in SIGNAL_TYPES)
        error("Unsupported signal type: $signal_type")
    end

    rate = parsed[:rate]
    if isnan(rate)
        rate = signal_type == "cardiac" ? 70.0 : 15.0
    end

    out_path = parsed[:out]
    format = resolve_signal_format(get(parsed, :format, nothing), out_path)

    if signal_type == "respiratory"
        physiology = parse_respiratory_physiology(parsed[:physiology])
        t, sig = generate_respiratory_signal(parsed[:duration], parsed[:fs], rate; physiology=physiology)
        save_signal(out_path, format, Dict("t" => t, "signal" => sig))
    else
        physiology = parse_cardiac_physiology(parsed[:physiology])
        t, vols = generate_cardiac_signals(parsed[:duration], parsed[:fs], rate; physiology=physiology)
        save_signal(out_path, format, Dict("t" => t, "lv" => vols.lv, "rv" => vols.rv, "la" => vols.la, "ra" => vols.ra))
    end

    if get(parsed, :format, nothing) === nothing && format == "csv"
        println("Saved signal data as CSV: $out_path")
    end

    return 0
end
