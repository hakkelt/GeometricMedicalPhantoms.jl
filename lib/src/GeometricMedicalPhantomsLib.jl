module GeometricMedicalPhantomsLib

using GeometricMedicalPhantoms

# ---------------------------------------------------------------------------
# C-compatible struct definitions
#
# Field order and types must match the corresponding declarations in
# lib/include/geometric_medical_phantoms.h exactly.  All structs are isbits
# so unsafe_load / unsafe_store! work correctly across the FFI boundary.
# ---------------------------------------------------------------------------

struct GmpRespiratoryPhysiology
    minL::Cdouble
    maxL::Cdouble
    asym_amp::Cdouble
    amp_mod_amp::Cdouble
    amp_mod_freq::Cdouble
    rr_var_amp::Cdouble
    rr_var_freq::Cdouble
end

struct GmpCardiacPhysiology
    lv_edv::Cdouble
    lv_esv::Cdouble
    rv_edv::Cdouble
    rv_esv::Cdouble
    la_min::Cdouble
    la_max::Cdouble
    ra_min::Cdouble
    ra_max::Cdouble
    hr_var_amp::Cdouble
    hr_var_freq::Cdouble
    v_amp_amp::Cdouble
    v_amp_freq::Cdouble
    a_amp_amp::Cdouble
    a_amp_freq::Cdouble
    bw_amp::Cdouble
    bw_freq::Cdouble
    s_frac_base::Cdouble
    lv_kick_amp_frac::Cdouble
    lv_kick_center::Cdouble
    lv_kick_width::Cdouble
    rv_kick_amp_frac::Cdouble
    rv_kick_center::Cdouble
    rv_kick_width::Cdouble
    la_contr_amp_frac::Cdouble
    la_contr_center::Cdouble
    la_contr_width::Cdouble
    ra_contr_amp_frac::Cdouble
    ra_contr_center::Cdouble
    ra_contr_width::Cdouble
end

struct GmpTissueIntensities
    lung::Cdouble
    heart::Cdouble
    vessels_blood::Cdouble
    bones::Cdouble
    liver::Cdouble
    stomach::Cdouble
    body::Cdouble
    lv_blood::Cdouble
    rv_blood::Cdouble
    la_blood::Cdouble
    ra_blood::Cdouble
end

# TubesIntensities carries a pointer + length because tube_fillings is a
# variable-length array owned by the caller.
struct GmpTubesIntensities
    outer_cylinder::Cdouble
    tube_wall::Cdouble
    tube_fillings::Ptr{Cdouble}
    n_tubes::Cint
end

struct GmpTubesGeometry
    outer_radius::Cdouble
    outer_height::Cdouble
    tubes_height_fraction::Cdouble
    tube_wall_thickness::Cdouble
    gap_fraction::Cdouble
end

struct GmpSheppLoganIntensities
    skull::Cdouble
    brain::Cdouble
    right_big::Cdouble
    left_big::Cdouble
    top::Cdouble
    middle_high::Cdouble
    bottom_left::Cdouble
    middle_low::Cdouble
    bottom_center::Cdouble
    bottom_right::Cdouble
    extra_1::Cdouble
    extra_2::Cdouble
end

# ---------------------------------------------------------------------------
# Conversion helpers  (C struct → Julia struct)
# ---------------------------------------------------------------------------

function to_julia(g::GmpRespiratoryPhysiology)
    RespiratoryPhysiology(
        minL = g.minL,
        maxL = g.maxL,
        asym_amp = g.asym_amp,
        amp_mod_amp = g.amp_mod_amp,
        amp_mod_freq = g.amp_mod_freq,
        rr_var_amp = g.rr_var_amp,
        rr_var_freq = g.rr_var_freq,
    )
end

function to_julia(g::GmpCardiacPhysiology)
    CardiacPhysiology(
        lv_edv = g.lv_edv,
        lv_esv = g.lv_esv,
        rv_edv = g.rv_edv,
        rv_esv = g.rv_esv,
        la_min = g.la_min,
        la_max = g.la_max,
        ra_min = g.ra_min,
        ra_max = g.ra_max,
        hr_var_amp = g.hr_var_amp,
        hr_var_freq = g.hr_var_freq,
        v_amp_amp = g.v_amp_amp,
        v_amp_freq = g.v_amp_freq,
        a_amp_amp = g.a_amp_amp,
        a_amp_freq = g.a_amp_freq,
        bw_amp = g.bw_amp,
        bw_freq = g.bw_freq,
        s_frac_base = g.s_frac_base,
        lv_kick_amp_frac = g.lv_kick_amp_frac,
        lv_kick_center = g.lv_kick_center,
        lv_kick_width = g.lv_kick_width,
        rv_kick_amp_frac = g.rv_kick_amp_frac,
        rv_kick_center = g.rv_kick_center,
        rv_kick_width = g.rv_kick_width,
        la_contr_amp_frac = g.la_contr_amp_frac,
        la_contr_center = g.la_contr_center,
        la_contr_width = g.la_contr_width,
        ra_contr_amp_frac = g.ra_contr_amp_frac,
        ra_contr_center = g.ra_contr_center,
        ra_contr_width = g.ra_contr_width,
    )
end

function to_julia(g::GmpTissueIntensities)
    TissueIntensities(
        lung = g.lung,
        heart = g.heart,
        vessels_blood = g.vessels_blood,
        bones = g.bones,
        liver = g.liver,
        stomach = g.stomach,
        body = g.body,
        lv_blood = g.lv_blood,
        rv_blood = g.rv_blood,
        la_blood = g.la_blood,
        ra_blood = g.ra_blood,
    )
end

function to_julia(g::GmpSheppLoganIntensities)
    SheppLoganIntensities{Float64}(
        skull = g.skull,
        brain = g.brain,
        right_big = g.right_big,
        left_big = g.left_big,
        top = g.top,
        middle_high = g.middle_high,
        bottom_left = g.bottom_left,
        middle_low = g.middle_low,
        bottom_center = g.bottom_center,
        bottom_right = g.bottom_right,
        extra_1 = g.extra_1,
        extra_2 = g.extra_2,
    )
end

function to_julia(g::GmpTubesGeometry)
    TubesGeometry(
        outer_radius = g.outer_radius,
        outer_height = g.outer_height,
        tubes_height_fraction = g.tubes_height_fraction,
        tube_wall_thickness = g.tube_wall_thickness,
        gap_fraction = g.gap_fraction,
    )
end

function to_julia(g::GmpTubesIntensities)
    n = Int(g.n_tubes)
    fillings = Vector{Float64}(undef, n)
    for i in 1:n
        fillings[i] = unsafe_load(g.tube_fillings, i)
    end
    TubesIntensities{Float64}(
        outer_cylinder = g.outer_cylinder,
        tube_wall = g.tube_wall,
        tube_fillings = fillings,
    )
end

# ---------------------------------------------------------------------------
# Axis helper
# ---------------------------------------------------------------------------

function axis_from_cint(axis::Cint)
    axis == Cint(0) && return :axial
    axis == Cint(1) && return :coronal
    axis == Cint(2) && return :sagittal
    return nothing
end

# ---------------------------------------------------------------------------
# Utility
# ---------------------------------------------------------------------------

# Global constant so the pointer remains valid for the lifetime of the process.
# Version is read from the bundled package at compile time.
const _VERSION_CSTR = string(pkgversion(GeometricMedicalPhantoms))

# gmp_init / gmp_cleanup — explicit Julia runtime lifecycle for embedders
# (e.g. MATLAB loadlibrary) that cannot rely on the automatic thread-adoption
# prologue injected by JuliaC.
#
# Perform a real GC allocation so that the calling thread's Julia GC state
# (jl_get_ptls_states / jl_current_task) is fully initialised before any
# heavier @ccallable function tries to use it.  Without this warm-up,
# MATLAB's interpreter thread ends up with a NULL ptls pointer the first
# time it hits jl_gc_alloc, causing a segfault.
Base.@ccallable function gmp_init()::Cint
    # Allocate a tiny vector — forces full GC state initialisation on this
    # thread (thread adoption + ptls setup + safepoint registration).
    v = Vector{Float32}(undef, 4)
    GC.@preserve v begin
        v[1] = 0f0
    end
    return Cint(0)
end

Base.@ccallable function gmp_cleanup()::Cvoid
    return nothing
end

Base.@ccallable function gmp_version()::Ptr{Cchar}
    return pointer(_VERSION_CSTR)
end

# ---------------------------------------------------------------------------
# Default-filler functions
# Caller allocates the struct, we fill it with default values.
# ---------------------------------------------------------------------------

Base.@ccallable function gmp_respiratory_physiology_default(
    out::Ptr{GmpRespiratoryPhysiology},
)::Cvoid
    d = RespiratoryPhysiology()
    unsafe_store!(
        out,
        GmpRespiratoryPhysiology(d.minL, d.maxL, d.asym_amp, d.amp_mod_amp, d.amp_mod_freq, d.rr_var_amp, d.rr_var_freq),
    )
    return nothing
end

Base.@ccallable function gmp_cardiac_physiology_default(
    out::Ptr{GmpCardiacPhysiology},
)::Cvoid
    d = CardiacPhysiology()
    unsafe_store!(
        out,
        GmpCardiacPhysiology(
            d.lv_edv, d.lv_esv, d.rv_edv, d.rv_esv,
            d.la_min, d.la_max, d.ra_min, d.ra_max,
            d.hr_var_amp, d.hr_var_freq,
            d.v_amp_amp, d.v_amp_freq,
            d.a_amp_amp, d.a_amp_freq,
            d.bw_amp, d.bw_freq,
            d.s_frac_base,
            d.lv_kick_amp_frac, d.lv_kick_center, d.lv_kick_width,
            d.rv_kick_amp_frac, d.rv_kick_center, d.rv_kick_width,
            d.la_contr_amp_frac, d.la_contr_center, d.la_contr_width,
            d.ra_contr_amp_frac, d.ra_contr_center, d.ra_contr_width,
        ),
    )
    return nothing
end

Base.@ccallable function gmp_tissue_intensities_default(
    out::Ptr{GmpTissueIntensities},
)::Cvoid
    d = TissueIntensities()
    unsafe_store!(
        out,
        GmpTissueIntensities(
            d.lung, d.heart, d.vessels_blood, d.bones, d.liver,
            d.stomach, d.body, d.lv_blood, d.rv_blood, d.la_blood, d.ra_blood,
        ),
    )
    return nothing
end

Base.@ccallable function gmp_tubes_geometry_default(
    out::Ptr{GmpTubesGeometry},
)::Cvoid
    d = TubesGeometry()
    unsafe_store!(
        out,
        GmpTubesGeometry(d.outer_radius, d.outer_height, d.tubes_height_fraction, d.tube_wall_thickness, d.gap_fraction),
    )
    return nothing
end

# fillings_out: caller-allocated array of at least n_tubes doubles; filled
#               with default filling intensities (up to 6 values).
# out:          receives the GmpTubesIntensities struct with tube_fillings
#               pointing to fillings_out.
Base.@ccallable function gmp_tubes_intensities_default(
    out::Ptr{GmpTubesIntensities},
    fillings_out::Ptr{Cdouble},
    n_tubes::Cint,
)::Cvoid
    defaults = (0.1, 0.3, 0.5, 0.7, 0.9, 1.0)
    n = Int(n_tubes)
    for i in 1:min(n, length(defaults))
        unsafe_store!(fillings_out, defaults[i], i)
    end
    unsafe_store!(
        out,
        GmpTubesIntensities(0.25, 0.0, fillings_out, n_tubes),
    )
    return nothing
end

Base.@ccallable function gmp_shepp_logan_ct_default(
    out::Ptr{GmpSheppLoganIntensities},
)::Cvoid
    d = CTSheppLoganIntensities()
    unsafe_store!(
        out,
        GmpSheppLoganIntensities(
            d.skull, d.brain, d.right_big, d.left_big, d.top, d.middle_high,
            d.bottom_left, d.middle_low, d.bottom_center, d.bottom_right, d.extra_1, d.extra_2,
        ),
    )
    return nothing
end

Base.@ccallable function gmp_shepp_logan_mri_default(
    out::Ptr{GmpSheppLoganIntensities},
)::Cvoid
    d = MRISheppLoganIntensities()
    unsafe_store!(
        out,
        GmpSheppLoganIntensities(
            d.skull, d.brain, d.right_big, d.left_big, d.top, d.middle_high,
            d.bottom_left, d.middle_low, d.bottom_center, d.bottom_right, d.extra_1, d.extra_2,
        ),
    )
    return nothing
end

# ---------------------------------------------------------------------------
# Signal length helper
# Returns the number of samples for a signal with the given duration and
# sampling frequency.  Use this to size the output buffers before calling
# gmp_generate_respiratory_signal / gmp_generate_cardiac_signals.
# ---------------------------------------------------------------------------

Base.@ccallable function gmp_signal_length(duration::Cdouble, fs::Cdouble)::Cint
    # Mirrors the range construction used by generate_respiratory_signal:
    #   t = 0 : (1/fs) : (duration - 1/fs)
    n = length(range(0.0; step = 1.0 / fs, stop = duration - 1.0 / fs))
    return Cint(n)
end

# ---------------------------------------------------------------------------
# Signal generation
# ---------------------------------------------------------------------------

Base.@ccallable function gmp_generate_respiratory_signal(
    duration::Cdouble,
    fs::Cdouble,
    rr::Cdouble,
    phys_ptr::Ptr{GmpRespiratoryPhysiology},
    t_out::Ptr{Cdouble},
    sig_out::Ptr{Cdouble},
    n::Cint,
)::Cint
    try
        phys = to_julia(unsafe_load(phys_ptr))
        t, sig = generate_respiratory_signal(Float64(duration), Float64(fs), Float64(rr); physiology = phys)
        len = min(length(t), Int(n))
        for i in 1:len
            unsafe_store!(t_out, t[i], i)
            unsafe_store!(sig_out, sig[i], i)
        end
        return Cint(0)
    catch
        return Cint(-1)
    end
end

Base.@ccallable function gmp_generate_cardiac_signals(
    duration::Cdouble,
    fs::Cdouble,
    hr::Cdouble,
    phys_ptr::Ptr{GmpCardiacPhysiology},
    t_out::Ptr{Cdouble},
    lv_out::Ptr{Cdouble},
    rv_out::Ptr{Cdouble},
    la_out::Ptr{Cdouble},
    ra_out::Ptr{Cdouble},
    n::Cint,
)::Cint
    try
        phys = to_julia(unsafe_load(phys_ptr))
        t, vols = generate_cardiac_signals(Float64(duration), Float64(fs), Float64(hr); physiology = phys)
        len = min(length(t), Int(n))
        for i in 1:len
            unsafe_store!(t_out, t[i], i)
            unsafe_store!(lv_out, vols.lv[i], i)
            unsafe_store!(rv_out, vols.rv[i], i)
            unsafe_store!(la_out, vols.la[i], i)
            unsafe_store!(ra_out, vols.ra[i], i)
        end
        return Cint(0)
    catch
        return Cint(-1)
    end
end

# ---------------------------------------------------------------------------
# Shepp-Logan phantom
# ---------------------------------------------------------------------------

Base.@ccallable function gmp_create_shepp_logan_phantom_3d(
    nx::Cint,
    ny::Cint,
    nz::Cint,
    ti_ptr::Ptr{GmpSheppLoganIntensities},
    out::Ptr{Cfloat},
)::Cint
    try
        ti = to_julia(unsafe_load(ti_ptr))
        phantom = create_shepp_logan_phantom(Int(nx), Int(ny), Int(nz); ti = ti, eltype = Float32)
        n = Int(nx) * Int(ny) * Int(nz)
        GC.@preserve phantom unsafe_copyto!(out, pointer(phantom), n)
        return Cint(0)
    catch
        return Cint(-1)
    end
end

# axis: 0=axial, 1=coronal, 2=sagittal
Base.@ccallable function gmp_create_shepp_logan_phantom_2d(
    nx::Cint,
    ny::Cint,
    axis::Cint,
    slice_pos::Cdouble,
    ti_ptr::Ptr{GmpSheppLoganIntensities},
    out::Ptr{Cfloat},
)::Cint
    try
        ax = axis_from_cint(axis)
        ax === nothing && return Cint(-2)
        ti = to_julia(unsafe_load(ti_ptr))
        phantom = create_shepp_logan_phantom(Int(nx), Int(ny), ax; slice_position = Float64(slice_pos), ti = ti, eltype = Float32)
        n = Int(nx) * Int(ny)
        GC.@preserve phantom unsafe_copyto!(out, pointer(phantom), n)
        return Cint(0)
    catch
        return Cint(-1)
    end
end

# ---------------------------------------------------------------------------
# Tubes phantom
# ---------------------------------------------------------------------------

Base.@ccallable function gmp_create_tubes_phantom_3d(
    nx::Cint,
    ny::Cint,
    nz::Cint,
    tg_ptr::Ptr{GmpTubesGeometry},
    ti_ptr::Ptr{GmpTubesIntensities},
    out::Ptr{Cfloat},
)::Cint
    try
        tg = to_julia(unsafe_load(tg_ptr))
        ti = to_julia(unsafe_load(ti_ptr))
        phantom = create_tubes_phantom(Int(nx), Int(ny), Int(nz); tg = tg, ti = ti, eltype = Float32)
        n = Int(nx) * Int(ny) * Int(nz)
        GC.@preserve phantom unsafe_copyto!(out, pointer(phantom), n)
        return Cint(0)
    catch
        return Cint(-1)
    end
end

Base.@ccallable function gmp_create_tubes_phantom_2d(
    nx::Cint,
    ny::Cint,
    axis::Cint,
    slice_pos::Cdouble,
    tg_ptr::Ptr{GmpTubesGeometry},
    ti_ptr::Ptr{GmpTubesIntensities},
    out::Ptr{Cfloat},
)::Cint
    try
        ax = axis_from_cint(axis)
        ax === nothing && return Cint(-2)
        tg = to_julia(unsafe_load(tg_ptr))
        ti = to_julia(unsafe_load(ti_ptr))
        phantom = create_tubes_phantom(Int(nx), Int(ny), ax; slice_position = Float64(slice_pos), tg = tg, ti = ti, eltype = Float32)
        n = Int(nx) * Int(ny)
        GC.@preserve phantom unsafe_copyto!(out, pointer(phantom), n)
        return Cint(0)
    catch
        return Cint(-1)
    end
end

# ---------------------------------------------------------------------------
# Torso phantom
# ---------------------------------------------------------------------------
#
# n_frames: number of time frames.
#   - 0 or 1 with NULL signal pointers: static phantom (1 frame output).
#   - >1 with valid signal pointers:    dynamic phantom (n_frames output).
# resp:           respiratory signal in liters, length n_frames (or NULL).
# cardiac_lv/rv/la/ra: cardiac chamber volumes in mL, length n_frames (or NULL).
# ti_ptr:         tissue intensities.
# out:            caller-allocated buffer; size = nx*ny*nz*max(n_frames,1) floats.
#                 Data layout: Fortran (column-major) order, time as last dimension.

Base.@ccallable function gmp_create_torso_phantom_3d(
    nx::Cint,
    ny::Cint,
    nz::Cint,
    n_frames::Cint,
    resp::Ptr{Cdouble},
    cardiac_lv::Ptr{Cdouble},
    cardiac_rv::Ptr{Cdouble},
    cardiac_la::Ptr{Cdouble},
    cardiac_ra::Ptr{Cdouble},
    ti_ptr::Ptr{GmpTissueIntensities},
    out::Ptr{Cfloat},
)::Cint
    try
        ti = to_julia(unsafe_load(ti_ptr))
        nf = max(Int(n_frames), 1)

        resp_signal = if resp == C_NULL
            nothing
        else
            [unsafe_load(resp, i) for i in 1:nf]
        end

        cardiac_volumes = if cardiac_lv == C_NULL
            nothing
        else
            (
                lv = [unsafe_load(cardiac_lv, i) for i in 1:nf],
                rv = [unsafe_load(cardiac_rv, i) for i in 1:nf],
                la = [unsafe_load(cardiac_la, i) for i in 1:nf],
                ra = [unsafe_load(cardiac_ra, i) for i in 1:nf],
            )
        end

        phantom = create_torso_phantom(
            Int(nx), Int(ny), Int(nz);
            respiratory_signal = resp_signal,
            cardiac_volumes = cardiac_volumes,
            ti = ti,
            eltype = Float32,
        )
        n = Int(nx) * Int(ny) * Int(nz) * size(phantom, 4)
        GC.@preserve phantom unsafe_copyto!(out, pointer(phantom), n)
        return Cint(0)
    catch
        return Cint(-1)
    end
end

Base.@ccallable function gmp_create_torso_phantom_2d(
    nx::Cint,
    ny::Cint,
    axis::Cint,
    slice_pos::Cdouble,
    n_frames::Cint,
    resp::Ptr{Cdouble},
    cardiac_lv::Ptr{Cdouble},
    cardiac_rv::Ptr{Cdouble},
    cardiac_la::Ptr{Cdouble},
    cardiac_ra::Ptr{Cdouble},
    ti_ptr::Ptr{GmpTissueIntensities},
    out::Ptr{Cfloat},
)::Cint
    try
        ax = axis_from_cint(axis)
        ax === nothing && return Cint(-2)
        ti = to_julia(unsafe_load(ti_ptr))
        nf = max(Int(n_frames), 1)

        resp_signal = if resp == C_NULL
            nothing
        else
            [unsafe_load(resp, i) for i in 1:nf]
        end

        cardiac_volumes = if cardiac_lv == C_NULL
            nothing
        else
            (
                lv = [unsafe_load(cardiac_lv, i) for i in 1:nf],
                rv = [unsafe_load(cardiac_rv, i) for i in 1:nf],
                la = [unsafe_load(cardiac_la, i) for i in 1:nf],
                ra = [unsafe_load(cardiac_ra, i) for i in 1:nf],
            )
        end

        phantom = create_torso_phantom(
            Int(nx), Int(ny), ax;
            fov = (30, 30),
            slice_position = Float64(slice_pos),
            respiratory_signal = resp_signal,
            cardiac_volumes = cardiac_volumes,
            ti = ti,
            eltype = Float32,
        )
        n = Int(nx) * Int(ny) * size(phantom, 3)
        GC.@preserve phantom unsafe_copyto!(out, pointer(phantom), n)
        return Cint(0)
    catch
        return Cint(-1)
    end
end

# ---------------------------------------------------------------------------
# Precompile workload
#
# Calling the @ccallable entry points here with concrete types forces Julia to
# specialise all downstream phantom-generation paths (eltype=Float32), which
# improves cold-start latency of the untrimmed build.
# ---------------------------------------------------------------------------
let
    # --- lifecycle ---
    gmp_init()
    gmp_cleanup()

    # --- default-struct functions ---
    _ct_ref  = Ref(GmpSheppLoganIntensities(ntuple(_ -> 0.0, 12)...))
    _mri_ref = Ref(GmpSheppLoganIntensities(ntuple(_ -> 0.0, 12)...))
    _rp_ref  = Ref(GmpRespiratoryPhysiology(ntuple(_ -> 0.0, 7)...))
    _cp_ref  = Ref(GmpCardiacPhysiology(ntuple(_ -> 0.0, 29)...))
    _ti_ref  = Ref(GmpTissueIntensities(ntuple(_ -> 0.0, 11)...))
    _tg_ref  = Ref(GmpTubesGeometry(ntuple(_ -> 0.0, 5)...))
    _tfi     = zeros(Cdouble, 4)
    _tui_ref = Ref(GmpTubesIntensities(0.0, 0.0, pointer(_tfi), Cint(4)))

    GC.@preserve _ct_ref _mri_ref _rp_ref _cp_ref _ti_ref _tg_ref _tfi _tui_ref begin
        gmp_shepp_logan_ct_default(Base.unsafe_convert(Ptr{GmpSheppLoganIntensities}, _ct_ref))
        gmp_shepp_logan_mri_default(Base.unsafe_convert(Ptr{GmpSheppLoganIntensities}, _mri_ref))
        gmp_respiratory_physiology_default(Base.unsafe_convert(Ptr{GmpRespiratoryPhysiology}, _rp_ref))
        gmp_cardiac_physiology_default(Base.unsafe_convert(Ptr{GmpCardiacPhysiology}, _cp_ref))
        gmp_tissue_intensities_default(Base.unsafe_convert(Ptr{GmpTissueIntensities}, _ti_ref))
        gmp_tubes_geometry_default(Base.unsafe_convert(Ptr{GmpTubesGeometry}, _tg_ref))
        # signature: (out::Ptr{GmpTubesIntensities}, fillings_out::Ptr{Cdouble}, n_tubes::Cint)
        gmp_tubes_intensities_default(
            Base.unsafe_convert(Ptr{GmpTubesIntensities}, _tui_ref),
            pointer(_tfi), Cint(4))
    end

    # --- phantom functions (small grids) ---
    _p3  = zeros(Float32, 4 * 4 * 4)
    _p2  = zeros(Float32, 4 * 4)
    _p4  = zeros(Float32, 4 * 4 * 4 * 1)

    GC.@preserve _ct_ref _mri_ref _tg_ref _tui_ref _ti_ref _p3 _p2 _p4 begin
        gmp_create_shepp_logan_phantom_3d(
            Cint(4), Cint(4), Cint(4),
            Base.unsafe_convert(Ptr{GmpSheppLoganIntensities}, _ct_ref), pointer(_p3))
        gmp_create_shepp_logan_phantom_2d(
            Cint(4), Cint(4), Cint(0), 0.0,
            Base.unsafe_convert(Ptr{GmpSheppLoganIntensities}, _ct_ref), pointer(_p2))
        gmp_create_tubes_phantom_3d(
            Cint(4), Cint(4), Cint(4),
            Base.unsafe_convert(Ptr{GmpTubesGeometry}, _tg_ref),
            Base.unsafe_convert(Ptr{GmpTubesIntensities}, _tui_ref), pointer(_p3))
        gmp_create_tubes_phantom_2d(
            Cint(4), Cint(4), Cint(0), 0.0,
            Base.unsafe_convert(Ptr{GmpTubesGeometry}, _tg_ref),
            Base.unsafe_convert(Ptr{GmpTubesIntensities}, _tui_ref), pointer(_p2))
        _null_f64 = Ptr{Cdouble}(0)
        gmp_create_torso_phantom_3d(
            Cint(4), Cint(4), Cint(4), Cint(1),
            _null_f64, _null_f64, _null_f64, _null_f64, _null_f64,
            Base.unsafe_convert(Ptr{GmpTissueIntensities}, _ti_ref), pointer(_p4))
        gmp_create_torso_phantom_2d(
            Cint(4), Cint(4), Cint(0), 0.0, Cint(1),
            _null_f64, _null_f64, _null_f64, _null_f64, _null_f64,
            Base.unsafe_convert(Ptr{GmpTissueIntensities}, _ti_ref), pointer(_p4))
    end

    # --- signal functions ---
    # signature: (duration, fs, rr, phys_ptr, t_out, sig_out, n)
    _n     = gmp_signal_length(1.0, 10.0)
    _t_buf = zeros(Cdouble, _n)
    _s_buf = zeros(Cdouble, _n)
    GC.@preserve _rp_ref _t_buf _s_buf begin
        gmp_generate_respiratory_signal(
            1.0, 10.0, 15.0,
            Base.unsafe_convert(Ptr{GmpRespiratoryPhysiology}, _rp_ref),
            pointer(_t_buf), pointer(_s_buf), Cint(_n))
    end
    # signature: (duration, fs, hr, phys_ptr, t_out, lv, rv, la, ra, n)
    _lv = zeros(Cdouble, _n); _rv = zeros(Cdouble, _n)
    _la = zeros(Cdouble, _n); _ra = zeros(Cdouble, _n)
    GC.@preserve _cp_ref _t_buf _lv _rv _la _ra begin
        gmp_generate_cardiac_signals(
            1.0, 10.0, 70.0,
            Base.unsafe_convert(Ptr{GmpCardiacPhysiology}, _cp_ref),
            pointer(_t_buf), pointer(_lv), pointer(_rv), pointer(_la), pointer(_ra),
            Cint(_n))
    end
end

end # module GeometricMedicalPhantomsLib
