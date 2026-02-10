"""
Helper function to set default motion signals and validate inputs.
Returns validated (respiratory_signal, cardiac_volumes, nt).
"""
function setup_and_validate_motion_signals(respiratory_signal, cardiac_volumes)
    # Set default motion signals if not provided
    if isnothing(respiratory_signal) && isnothing(cardiac_volumes)
        respiratory_signal = [2.7] # Single static frame with nominal lung volume
        cardiac_volumes = (lv = [140.0], rv = [140.0], la = [60.0], ra = [60.0]) # Single static frame with nominal volumes
    elseif isnothing(respiratory_signal)
        respiratory_signal = fill(2.7, length(cardiac_volumes.lv)) # Default nominal lung volume
    elseif isnothing(cardiac_volumes)
        cardiac_volumes = (
            lv = fill(140.0, length(respiratory_signal)),
            rv = fill(140.0, length(respiratory_signal)),
            la = fill(60.0, length(respiratory_signal)),
            ra = fill(60.0, length(respiratory_signal)),
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
function calculate_motion_parameters(respiratory_signal_val::Real, cardiac_scales::NamedTuple, cardiac_scales_max::NamedTuple)
    # Cubic coefficients for lung scaling (tuned to minimize volume offset)
    a0, a1, a2, a3 = (0.598, 0.842, -0.175, -0.0320625)
    b0, b1, b2, b3 = (1.819140625, 0.831375, -1.7111875, 1.24575)
    normal_resp_min, normal_resp_max = 1.2, 6.0
    resp_normal_range = normal_resp_max - normal_resp_min
    y_offset_base = -0.4  # Base y-offset for torso position

    resp_norm = (respiratory_signal_val - normal_resp_min) / resp_normal_range
    rn = resp_norm
    scale = a0 + a1 * rn + a2 * rn^2 + a3 * rn^3
    lower_rz_scale = b0 + b1 * rn + b2 * rn^2 + b3 * rn^3

    body_scale = 0.4 + 0.63 * scale
    diaphragm_up = -0.5 * (lower_rz_scale - 1.0)
    diaphragm_rscale = lower_rz_scale
    y_offset = y_offset_base + body_scale * 0.45
    y_offset_visc = y_offset * 0.8
    xy_visc_scale = 1.0 + 0.04 * resp_norm

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
Helper function to define dynamic phantom ellipsoids for a single frame.
Returns a tuple of all dynamic superellipsoids for the given motion parameters.
"""
function define_dynamic_ellipsoids(motion_params::NamedTuple, ti::AbstractTissueParameters)
    torso = get_torso_dynamic_parts(motion_params.body_scale, motion_params.y_offset, ti)
    lungs = get_lungs(
        motion_params.scale, motion_params.diaphragm_up, motion_params.diaphragm_rscale,
        motion_params.lower_rz_scale, motion_params.y_offset, ti
    )
    heart_background = get_heart_background(
        motion_params.heart_scale_max.lv, motion_params.heart_scale_max.rv,
        motion_params.heart_scale_max.la, motion_params.heart_scale_max.ra,
        motion_params.y_offset_visc, ti
    )
    vessels = get_vessels(motion_params.y_offset, ti)
    heart_chambers = get_heart_chambers(motion_params.heart_scale, motion_params.y_offset_visc, ti)
    ribs = get_ribs(motion_params.body_scale, motion_params.body_scale, motion_params.y_offset, ti)
    liver = get_liver(motion_params.diaphragm_up, motion_params.y_offset_visc, motion_params.xy_visc_scale, ti)
    stomach = get_stomach(motion_params.diaphragm_up, motion_params.y_offset_visc, motion_params.xy_visc_scale, ti)

    return (torso..., lungs..., heart_background..., vessels..., heart_chambers..., ribs..., liver..., stomach...)
end
