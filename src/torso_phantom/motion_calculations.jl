struct CardiacScales
    lv::Float64
    rv::Float64
    la::Float64
    ra::Float64
end

Base.@kwdef struct TorsoMotionModel
    static_lung_volume::Float64 = 2.7
    static_lv_volume::Float64 = 140.0
    static_rv_volume::Float64 = 140.0
    static_la_volume::Float64 = 60.0
    static_ra_volume::Float64 = 60.0
    lung_scale_poly::NTuple{4, Float64} = (0.598, 0.842, -0.175, -0.0320625)
    diaphragm_scale_poly::NTuple{4, Float64} = (1.819140625, 0.831375, -1.7111875, 1.24575)
    normal_resp_min::Float64 = 1.2
    normal_resp_max::Float64 = 6.0
    y_offset_base::Float64 = -0.4
    body_scale_offset::Float64 = 0.4
    body_scale_gain::Float64 = 0.63
    diaphragm_motion_gain::Float64 = -0.5
    y_offset_body_scale::Float64 = 0.45
    viscera_y_offset_scale::Float64 = 0.8
    viscera_xy_resp_gain::Float64 = 0.04
end

const DEFAULT_TORSO_MOTION_MODEL = TorsoMotionModel()
const TORSO_REFERENCE_FOV_CM = 30.0

"""
Helper function to set default motion signals and validate inputs.
Returns validated (respiratory_signal, cardiac_volumes, nt).
"""
function setup_and_validate_motion_signals(
        respiratory_signal, cardiac_volumes;
        motion_model::TorsoMotionModel = DEFAULT_TORSO_MOTION_MODEL
    )
    # Set default motion signals if not provided
    if isnothing(respiratory_signal) && isnothing(cardiac_volumes)
        respiratory_signal = [motion_model.static_lung_volume] # Single static frame with nominal lung volume
        cardiac_volumes = (
            lv = [motion_model.static_lv_volume],
            rv = [motion_model.static_rv_volume],
            la = [motion_model.static_la_volume],
            ra = [motion_model.static_ra_volume],
        ) # Single static frame with nominal volumes
    elseif isnothing(respiratory_signal)
        respiratory_signal = fill(motion_model.static_lung_volume, length(cardiac_volumes.lv)) # Default nominal lung volume
    elseif isnothing(cardiac_volumes)
        cardiac_volumes = (
            lv = fill(motion_model.static_lv_volume, length(respiratory_signal)),
            rv = fill(motion_model.static_rv_volume, length(respiratory_signal)),
            la = fill(motion_model.static_la_volume, length(respiratory_signal)),
            ra = fill(motion_model.static_ra_volume, length(respiratory_signal)),
        ) # Default nominal volumes
    end

    nt = length(respiratory_signal)
    # Validate lengths
    for f in (:lv, :rv, :la, :ra)
        hasproperty(cardiac_volumes, f) || throw(ArgumentError("cardiac_volumes must have fields :lv,:rv,:la,:ra"))
        length(getfield(cardiac_volumes, f)) == nt || throw(ArgumentError("respiratory_signal and cardiac_volumes must have the same length"))
    end

    return (respiratory_signal, cardiac_volumes, nt)
end

"""
Helper function to precompute cardiac scale factors.
Returns (lv_scales, rv_scales, la_scales, ra_scales, cardiac_scales_max).
"""
function precompute_cardiac_scales(cardiac_volumes, nt::Int)
    lv_mean = sum(cardiac_volumes.lv) / nt
    rv_mean = sum(cardiac_volumes.rv) / nt
    la_mean = sum(cardiac_volumes.la) / nt
    ra_mean = sum(cardiac_volumes.ra) / nt
    lv_scales = (cardiac_volumes.lv ./ lv_mean) .^ (1 / 3)
    rv_scales = (cardiac_volumes.rv ./ rv_mean) .^ (1 / 3)
    la_scales = (cardiac_volumes.la ./ la_mean) .^ (1 / 3)
    ra_scales = (cardiac_volumes.ra ./ ra_mean) .^ (1 / 3)
    cardiac_scales_max = (
        lv = maximum(lv_scales),
        rv = maximum(rv_scales),
        la = maximum(la_scales),
        ra = maximum(ra_scales),
    )
    return (lv_scales, rv_scales, la_scales, ra_scales, cardiac_scales_max)
end

"""
Helper function to calculate motion parameters for a given time frame.
Returns a NamedTuple with all motion-related parameters.
"""
function calculate_motion_parameters(
        respiratory_signal_val::Real, cardiac_scales, cardiac_scales_max;
        motion_model::TorsoMotionModel = DEFAULT_TORSO_MOTION_MODEL
    )
    # Cubic coefficients are tuned to match the phantom's lung and diaphragm motion.
    a0, a1, a2, a3 = motion_model.lung_scale_poly
    b0, b1, b2, b3 = motion_model.diaphragm_scale_poly
    resp_normal_range = motion_model.normal_resp_max - motion_model.normal_resp_min

    resp_norm = (respiratory_signal_val - motion_model.normal_resp_min) / resp_normal_range
    rn = resp_norm
    scale = a0 + a1 * rn + a2 * rn^2 + a3 * rn^3
    lower_rz_scale = b0 + b1 * rn + b2 * rn^2 + b3 * rn^3

    body_scale = motion_model.body_scale_offset + motion_model.body_scale_gain * scale
    diaphragm_up = motion_model.diaphragm_motion_gain * (lower_rz_scale - 1.0)
    diaphragm_rscale = lower_rz_scale
    y_offset = motion_model.y_offset_base + body_scale * motion_model.y_offset_body_scale
    y_offset_visc = y_offset * motion_model.viscera_y_offset_scale
    xy_visc_scale = 1.0 + motion_model.viscera_xy_resp_gain * resp_norm

    return (
        scale = scale,
        lower_rz_scale = lower_rz_scale,
        body_scale = body_scale,
        diaphragm_up = diaphragm_up,
        diaphragm_rscale = diaphragm_rscale,
        y_offset = y_offset,
        y_offset_visc = y_offset_visc,
        heart_scale = cardiac_scales,
        heart_scale_max = cardiac_scales_max,
        xy_visc_scale = xy_visc_scale,
    )
end

"""
Type-stable dynamic shape drawing: calls each `draw_*!` function in order.
No tuple assembly or splatting — each anatomical group is drawn directly.
"""
function draw_dynamic_shapes!(ctx, motion_params::NamedTuple, ti::AbstractTissueParameters)
    draw_torso_dynamic_parts!(ctx, motion_params.body_scale, motion_params.y_offset, ti)
    draw_lungs!(
        ctx, motion_params.scale, motion_params.diaphragm_up, motion_params.diaphragm_rscale,
        motion_params.lower_rz_scale, motion_params.y_offset, ti
    )
    draw_heart_background!(
        ctx, motion_params.heart_scale_max.lv, motion_params.heart_scale_max.rv,
        motion_params.heart_scale_max.la, motion_params.heart_scale_max.ra,
        motion_params.y_offset_visc, ti
    )
    draw_vessels!(ctx, motion_params.y_offset, ti)
    draw_heart_chambers!(ctx, motion_params.heart_scale, motion_params.y_offset_visc, ti)
    draw_ribs!(ctx, motion_params.body_scale, motion_params.body_scale, motion_params.y_offset, ti)
    draw_liver!(ctx, motion_params.diaphragm_up, motion_params.y_offset_visc, motion_params.xy_visc_scale, ti)
    draw_stomach!(ctx, motion_params.diaphragm_up, motion_params.y_offset_visc, motion_params.xy_visc_scale, ti)
    return nothing
end
