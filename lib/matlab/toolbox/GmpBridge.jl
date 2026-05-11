# GmpBridge.jl — Julia bridge for the GeometricMedicalPhantoms MATLAB toolbox.
#
# Loaded once per MATLAB session via:
#   jl.include('/path/to/GmpBridge.jl')
#
# All functions are defined in Julia's Main module and are called from MATLAB
# via jl.mex('function_name', args...).  Each function accepts
# Vector{MATLAB.MxArray} and returns Vector{MATLAB.MxArray}.
#
# Struct encoding
# ---------------
# MATLAB structs are encoded as flat Float64 row-vectors with a fixed field
# order.  The same order is used in GeometricMedicalPhantoms.m.
#
#   RespiratoryPhysiology (7)  : minL maxL asym_amp amp_mod_amp amp_mod_freq
#                                rr_var_amp rr_var_freq
#
#   CardiacPhysiology (29)     : lv_edv lv_esv rv_edv rv_esv la_min la_max
#                                ra_min ra_max hr_var_amp hr_var_freq
#                                v_amp_amp v_amp_freq a_amp_amp a_amp_freq
#                                bw_amp bw_freq s_frac_base
#                                lv_kick_amp_frac lv_kick_center lv_kick_width
#                                rv_kick_amp_frac rv_kick_center rv_kick_width
#                                la_contr_amp_frac la_contr_center la_contr_width
#                                ra_contr_amp_frac ra_contr_center ra_contr_width
#
#   TissueIntensities (11)     : lung heart vessels_blood bones liver stomach
#                                body lv_blood rv_blood la_blood ra_blood
#
#   TubesGeometry (5)          : outer_radius outer_height tubes_height_fraction
#                                tube_wall_thickness gap_fraction
#
#   TubesIntensities (2+n)     : outer_cylinder tube_wall [tube_fillings...]
#
#   SheppLoganIntensities (12) : skull brain right_big left_big top middle_high
#                                bottom_left middle_low bottom_center
#                                bottom_right extra_1 extra_2

import MATLAB: MxArray, mxarray, jvalue
using GeometricMedicalPhantoms

# ─── scalar / vector helpers ─────────────────────────────────────────────────
# These handle both MATLAB scalars (Float64) and 1×1 matrices (Matrix{Float64}).

_toi(mx::MxArray) = Int(first(jvalue(mx)))
_tof(mx::MxArray) = Float64(first(jvalue(mx)))
_tov(mx::MxArray) = Float64.(vec(jvalue(mx)))   # any MATLAB numeric → Vector{Float64}

const _AXES = [:axial, :coronal, :sagittal]   # index by (axis_int + 1)

# ─── struct decoders: Float64 vector → Julia struct ──────────────────────────

function _dec_resp(mx::MxArray)
    v = _tov(mx)
    RespiratoryPhysiology(
        minL=v[1], maxL=v[2], asym_amp=v[3],
        amp_mod_amp=v[4], amp_mod_freq=v[5],
        rr_var_amp=v[6], rr_var_freq=v[7],
    )
end

function _dec_card(mx::MxArray)
    v = _tov(mx)
    CardiacPhysiology(
        lv_edv=v[1], lv_esv=v[2], rv_edv=v[3], rv_esv=v[4],
        la_min=v[5], la_max=v[6], ra_min=v[7], ra_max=v[8],
        hr_var_amp=v[9], hr_var_freq=v[10], v_amp_amp=v[11], v_amp_freq=v[12],
        a_amp_amp=v[13], a_amp_freq=v[14], bw_amp=v[15], bw_freq=v[16],
        s_frac_base=v[17],
        lv_kick_amp_frac=v[18], lv_kick_center=v[19], lv_kick_width=v[20],
        rv_kick_amp_frac=v[21], rv_kick_center=v[22], rv_kick_width=v[23],
        la_contr_amp_frac=v[24], la_contr_center=v[25], la_contr_width=v[26],
        ra_contr_amp_frac=v[27], ra_contr_center=v[28], ra_contr_width=v[29],
    )
end

function _dec_tissue(mx::MxArray)
    v = _tov(mx)
    TissueIntensities(
        lung=v[1], heart=v[2], vessels_blood=v[3], bones=v[4],
        liver=v[5], stomach=v[6], body=v[7],
        lv_blood=v[8], rv_blood=v[9], la_blood=v[10], ra_blood=v[11],
    )
end

function _dec_tgeom(mx::MxArray)
    v = _tov(mx)
    TubesGeometry(
        outer_radius=v[1], outer_height=v[2], tubes_height_fraction=v[3],
        tube_wall_thickness=v[4], gap_fraction=v[5],
    )
end

function _dec_tint(mx::MxArray)
    v = _tov(mx)
    TubesIntensities(outer_cylinder=v[1], tube_wall=v[2], tube_fillings=v[3:end])
end

function _dec_sl(mx::MxArray)
    v = _tov(mx)
    SheppLoganIntensities(
        skull=v[1], brain=v[2], right_big=v[3], left_big=v[4],
        top=v[5], middle_high=v[6], bottom_left=v[7], middle_low=v[8],
        bottom_center=v[9], bottom_right=v[10], extra_1=v[11], extra_2=v[12],
    )
end

# ─── struct encoders: Julia struct → MxArray (Float64 row-vector) ────────────

_enc_resp(p::RespiratoryPhysiology) =
    mxarray(Float64[p.minL, p.maxL, p.asym_amp, p.amp_mod_amp, p.amp_mod_freq,
                    p.rr_var_amp, p.rr_var_freq])

_enc_card(p::CardiacPhysiology) =
    mxarray(Float64[
        p.lv_edv, p.lv_esv, p.rv_edv, p.rv_esv,
        p.la_min, p.la_max, p.ra_min, p.ra_max,
        p.hr_var_amp, p.hr_var_freq, p.v_amp_amp, p.v_amp_freq,
        p.a_amp_amp, p.a_amp_freq, p.bw_amp, p.bw_freq, p.s_frac_base,
        p.lv_kick_amp_frac, p.lv_kick_center, p.lv_kick_width,
        p.rv_kick_amp_frac, p.rv_kick_center, p.rv_kick_width,
        p.la_contr_amp_frac, p.la_contr_center, p.la_contr_width,
        p.ra_contr_amp_frac, p.ra_contr_center, p.ra_contr_width,
    ])

_enc_tissue(ti::TissueIntensities) =
    mxarray(Float64[ti.lung, ti.heart, ti.vessels_blood, ti.bones,
                    ti.liver, ti.stomach, ti.body,
                    ti.lv_blood, ti.rv_blood, ti.la_blood, ti.ra_blood])

_enc_tgeom(tg::TubesGeometry) =
    mxarray(Float64[tg.outer_radius, tg.outer_height, tg.tubes_height_fraction,
                    tg.tube_wall_thickness, tg.gap_fraction])

_enc_tint(ti::TubesIntensities{T}) where {T} =
    mxarray(Float64[ti.outer_cylinder, ti.tube_wall, Float64.(ti.tube_fillings)...])

_enc_sl(ti::SheppLoganIntensities) =
    mxarray(Float64[ti.skull, ti.brain, ti.right_big, ti.left_big,
                    ti.top, ti.middle_high, ti.bottom_left, ti.middle_low,
                    ti.bottom_center, ti.bottom_right, ti.extra_1, ti.extra_2])

# ─── optional signal vector helper ───────────────────────────────────────────
# Returns nothing if args[i] is absent or empty, otherwise a Float64 vector.

function _sigvec(args::Vector{MxArray}, i::Int)
    length(args) < i && return nothing
    v = Float64.(vec(jvalue(args[i])))
    isempty(v) ? nothing : v
end

# ─────────────────────────────────────────────────────────────────────────────
# MEX entry points
# ─────────────────────────────────────────────────────────────────────────────

# --- utility ------------------------------------------------------------------

function gmp_version(args::Vector{MxArray})
    mxarray(string(pkgversion(GeometricMedicalPhantoms)))
end

function gmp_signal_length(args::Vector{MxArray})
    duration, fs = _tof(args[1]), _tof(args[2])
    mxarray(Int32(round(duration * fs)))
end

# --- defaults -----------------------------------------------------------------

function gmp_resp_physiology_default(args::Vector{MxArray})
    _enc_resp(RespiratoryPhysiology())
end

function gmp_cardiac_physiology_default(args::Vector{MxArray})
    _enc_card(CardiacPhysiology())
end

function gmp_tissue_intensities_default(args::Vector{MxArray})
    _enc_tissue(TissueIntensities())
end

function gmp_tubes_geometry_default(args::Vector{MxArray})
    _enc_tgeom(TubesGeometry())
end

function gmp_tubes_intensities_default(args::Vector{MxArray})
    _enc_tint(TubesIntensities())
end

function gmp_shepp_logan_ct_default(args::Vector{MxArray})
    _enc_sl(CTSheppLoganIntensities())
end

function gmp_shepp_logan_mri_default(args::Vector{MxArray})
    _enc_sl(MRISheppLoganIntensities())
end

# --- signals ------------------------------------------------------------------

function gmp_generate_respiratory_signal(args::Vector{MxArray})
    duration, fs, rr = _tof(args[1]), _tof(args[2]), _tof(args[3])
    phys = _dec_resp(args[4])
    t, sig = generate_respiratory_signal(duration, fs, rr; physiology=phys)
    [mxarray(collect(Float64, t)), mxarray(Float64.(sig))]
end

function gmp_generate_cardiac_signals(args::Vector{MxArray})
    duration, fs, hr = _tof(args[1]), _tof(args[2]), _tof(args[3])
    phys = _dec_card(args[4])
    t, vols = generate_cardiac_signals(duration, fs, hr; physiology=phys)
    [mxarray(collect(Float64, t)),
     mxarray(Float64.(vols.lv)), mxarray(Float64.(vols.rv)),
     mxarray(Float64.(vols.la)), mxarray(Float64.(vols.ra))]
end

# --- Shepp-Logan --------------------------------------------------------------

function gmp_shepp_logan_3d(args::Vector{MxArray})
    nx, ny, nz = _toi(args[1]), _toi(args[2]), _toi(args[3])
    ti = _dec_sl(args[4])
    mxarray(create_shepp_logan_phantom(nx, ny, nz; ti=ti))
end

function gmp_shepp_logan_2d(args::Vector{MxArray})
    nx, ny  = _toi(args[1]), _toi(args[2])
    axis    = _AXES[_toi(args[3]) + 1]
    slpos   = _tof(args[4])
    ti      = _dec_sl(args[5])
    mxarray(create_shepp_logan_phantom(nx, ny, axis; slice_position=slpos, ti=ti))
end

# --- Tubes --------------------------------------------------------------------

function gmp_tubes_3d(args::Vector{MxArray})
    nx, ny, nz = _toi(args[1]), _toi(args[2]), _toi(args[3])
    tg, ti = _dec_tgeom(args[4]), _dec_tint(args[5])
    mxarray(create_tubes_phantom(nx, ny, nz; tg=tg, ti=ti))
end

function gmp_tubes_2d(args::Vector{MxArray})
    nx, ny  = _toi(args[1]), _toi(args[2])
    axis    = _AXES[_toi(args[3]) + 1]
    slpos   = _tof(args[4])
    tg, ti  = _dec_tgeom(args[5]), _dec_tint(args[6])
    mxarray(create_tubes_phantom(nx, ny, axis; slice_position=slpos, tg=tg, ti=ti))
end

# --- Torso --------------------------------------------------------------------

function gmp_torso_3d(args::Vector{MxArray})
    nx, ny, nz = _toi(args[1]), _toi(args[2]), _toi(args[3])
    nf         = _toi(args[4])
    ti         = _dec_tissue(args[5])
    resp  = _sigvec(args, 6)
    lv    = _sigvec(args, 7)
    rv    = _sigvec(args, 8)
    la    = _sigvec(args, 9)
    ra    = _sigvec(args, 10)
    card  = (lv !== nothing && rv !== nothing && la !== nothing && ra !== nothing) ?
            (lv=lv, rv=rv, la=la, ra=ra) : nothing
    phantom = create_torso_phantom(nx, ny, nz;
                  respiratory_signal=resp, cardiac_volumes=card, ti=ti)
    mxarray(phantom)
end

function gmp_torso_2d(args::Vector{MxArray})
    nx, ny  = _toi(args[1]), _toi(args[2])
    axis    = _AXES[_toi(args[3]) + 1]
    slpos   = _tof(args[4])
    nf      = _toi(args[5])
    ti      = _dec_tissue(args[6])
    resp  = _sigvec(args, 7)
    lv    = _sigvec(args, 8)
    rv    = _sigvec(args, 9)
    la    = _sigvec(args, 10)
    ra    = _sigvec(args, 11)
    card  = (lv !== nothing && rv !== nothing && la !== nothing && ra !== nothing) ?
            (lv=lv, rv=rv, la=la, ra=ra) : nothing
    phantom = create_torso_phantom(nx, ny, axis;
                  slice_position=slpos, respiratory_signal=resp,
                  cardiac_volumes=card, ti=ti)
    mxarray(phantom)
end
