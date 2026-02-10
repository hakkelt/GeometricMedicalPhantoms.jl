"""
Helper function to get static torso superellipsoids (neck, shoulders, arms, back)
"""
function get_torso_static_parts(ti::AbstractTissueParameters)
    body_val = get_intensity(ti, :body)
    return (
        # Neck
        SuperEllipsoid(0.0, 0.165, 0.85, 0.312, 0.336, 0.264, (2.5, 2.5, 2.5), body_val),
        SuperEllipsoid(0.0, 0.165, 1.0, 0.312, 0.312, 0.18, (2.5, 2.5, 2.5), body_val),

        # Shoulders
        SuperEllipsoid(0.0, 0.165, 0.7, 0.8, 0.28, 0.25, (2.5, 2.5, 2.5), body_val),

        # Arms
        # Left arm - upper
        SuperEllipsoid(-0.68, 0.165, 0.62, 0.18, 0.18, 0.28, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Left arm - mid
        SuperEllipsoid(-0.88, 0.165, 0.5, 0.17, 0.17, 0.26, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Left arm - lower
        SuperEllipsoid(-1.05, 0.165, 0.38, 0.16, 0.16, 0.24, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Right arm - upper
        SuperEllipsoid(0.68, 0.165, 0.62, 0.18, 0.18, 0.28, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Right arm - mid
        SuperEllipsoid(0.88, 0.165, 0.5, 0.17, 0.17, 0.26, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Right arm - lower
        SuperEllipsoid(1.05, 0.165, 0.38, 0.16, 0.16, 0.24, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Posterior extensions for spine/back coverage (does not move with breathing)
        # Upper back (cervical/upper thoracic region)
        SuperEllipsoid(0.0, 0.28, 0.35, 0.7, 0.43, 0.5, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Mid back (mid thoracic region)
        SuperEllipsoid(0.0, 0.28, -0.1, 0.75, 0.47, 0.55, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Lower back (lumbar region)
        SuperEllipsoid(0.0, 0.15, -0.6, 0.78, 0.48, 0.55, (2.5, 2.5, 2.5), get_intensity(ti, :body)),
    )
end

"""
Helper function to get dynamic torso superellipsoids (chest, abdomen)
"""
function get_torso_dynamic_parts(body_scale::Real, y_offset::Real, ti::AbstractTissueParameters)
    s = body_scale
    return (
        # Chest
        # Ribs 1-4 level (upper chest)
        SuperEllipsoid(0.0, 0.0 - y_offset, 0.45, 0.86 * s, 0.69 * s, 0.35, (2.5, 2.5, 2.5), get_intensity(ti, :body)),

        # Ribs 5-8 level (mid chest - widest)
        SuperEllipsoid(0.0, 0.0 - y_offset, 0.17, 0.93 * s, 0.72 * s, 0.32, (2.5, 2.5, 3.5), get_intensity(ti, :body)),

        # Ribs 9-12 level (lower chest)
        SuperEllipsoid(0.0, 0.0 - y_offset, -0.11, 0.91 * s, 0.71 * s, 0.32, (2.5, 2.5, 3.5), get_intensity(ti, :body)),

        # Abdomen (smaller changes in radii than chest)
        # Upper abdomen
        SuperEllipsoid(0.0, 0.0 - y_offset, -0.45, 0.87 * s, 0.67 * s, 0.4, (2.5, 2.5, 3.5), get_intensity(ti, :body)),

        # Lower abdomen
        SuperEllipsoid(0.0, 0.0 - y_offset, -0.85, 0.83 * (s^(1 / 2)), 0.62 * (s^(1 / 2)), 0.45, (2.5, 2.5, 3.5), get_intensity(ti, :body)),
    )
end

"""
Helper function to get lung parts with upper lobe, lower lobe, and diaphragm.
"""
function get_lungs(scale::Real, diaphragm_upshift::Real, diaphragm_radius_scale::Real, lower_rz_scale::Real, y_offset::Real, ti::AbstractTissueParameters)
    lung_x_offset = 0.32
    lung_l_top_x = lung_x_offset - 0.1
    lung_l_top_radius = 0.25 + 0.22 * scale
    lung_l_lower_radius = 0.43 * scale
    lung_l_lower_rz = 0.48 * lower_rz_scale
    lung_r_top_x = lung_x_offset - 0.1
    diaphragm_radius = lung_l_lower_radius

    return (
        # Left Lung
        # Upper lobe
        SuperEllipsoid(-lung_l_top_x, 0.0 - y_offset, -0.1 - diaphragm_upshift * 0.5, lung_l_top_radius, lung_l_lower_radius, 0.7, (2.0, 2.0, 1.2), get_intensity(ti, :lung)),

        # Lower lobe (rz varies with respiration)
        SuperEllipsoid(-lung_x_offset, 0.0 - y_offset, -0.17 + diaphragm_upshift * 0.5, lung_l_lower_radius, lung_l_lower_radius, lung_l_lower_rz, (2.0, 2.0, 2.5), get_intensity(ti, :lung)),

        # Right Lung
        # Upper lobe
        SuperEllipsoid(lung_r_top_x, 0.0 - y_offset, -0.1 - diaphragm_upshift * 0.5, lung_l_top_radius, lung_l_lower_radius, 0.7, (2.0, 2.0, 1.2), get_intensity(ti, :lung)),
        # Lower lobe (rz varies with respiration)
        SuperEllipsoid(lung_x_offset, 0.0 - y_offset, -0.17 + diaphragm_upshift * 0.5, lung_l_lower_radius, lung_l_lower_radius, lung_l_lower_rz, (2.0, 2.0, 2.5), get_intensity(ti, :lung)),

        # Left diaphragm dome
        SuperEllipsoid(-lung_x_offset, 0.0 - y_offset, -0.5 + diaphragm_upshift, diaphragm_radius, diaphragm_radius, 0.4, (2.5, 2.5, 1.5), get_intensity(ti, :body)),

        # Right diaphragm dome
        SuperEllipsoid(lung_x_offset, 0.0 - y_offset, -0.5 + diaphragm_upshift, diaphragm_radius, diaphragm_radius, 0.4, (2.5, 2.5, 1.5), get_intensity(ti, :body)),
    )
end

"""
Helper function to get heart background ellipsoid.
"""
function get_heart_background(lv_scale_max::Real, rv_scale_max::Real, la_scale_max::Real, ra_scale_max::Real, y_offset_visc::Real, ti::AbstractTissueParameters)
    rx_bg = 1.35 * max(0.251 * lv_scale_max, 0.209 * rv_scale_max, 0.15 * la_scale_max, 0.15 * ra_scale_max)
    ry_bg = 0.8 * rx_bg
    rz_bg = 1.65 * max(0.242 * lv_scale_max, 0.178 * lv_scale_max, 0.195 * rv_scale_max, 0.136 * rv_scale_max, 0.188 * la_scale_max, 0.188 * ra_scale_max)
    x_bg = 0.01
    y_bg = -y_offset_visc
    z_bg = 0.24
    return (SuperEllipsoid(x_bg, y_bg, z_bg, rx_bg, ry_bg, rz_bg, (2.2, 2.2, 2.2), get_intensity(ti, :body)),)
end

"""
Helper function to get heart chambers.
"""
function get_heart_chambers(heart_scale, y_offset::Real, ti::AbstractTissueParameters)
    z_offset = 0.2
    s_lv = heart_scale.lv
    s_rv = heart_scale.rv
    s_la = heart_scale.la
    s_ra = heart_scale.ra
    # Slight cavity-specific scaling to improve volume match
    s_lv_c = s_lv * 1.1
    s_rv_c = s_rv * 1.06
    s_la_c = s_la * 0.95
    s_ra_c = s_ra * 1.0
    # Dynamic lateral separation for ventricles (scaled by radius increase)
    sep_factor = 0.45
    dx_lv = sep_factor * (0.251) * (s_lv - 1.0)
    dx_rv = sep_factor * (0.209) * (s_rv - 1.0)
    # Atria dynamic separation in proportion to radius change
    dx_la = 0.15048 * (s_la - 1.0)
    dx_ra = 0.15048 * (s_ra - 1.0)
    # Dynamic z-separation within heart pairs (atrium vs ventricle) proportional to sum of z-radius changes
    z_sep_factor = 0.9
    base_z_lv = 0.209
    base_z_la = 0.188
    base_z_rv = 0.195
    base_z_ra = 0.188
    dz_lv = base_z_lv * (s_lv - 1.0)
    dz_la = base_z_la * (s_la - 1.0)
    dz_rv = base_z_rv * (s_rv - 1.0)
    dz_ra = base_z_ra * (s_ra - 1.0)
    z_sep_L = z_sep_factor * (dz_lv + dz_la)
    z_sep_R = z_sep_factor * (dz_rv + dz_ra)

    # Tuning parameters
    myocardium_bottom_z_scale = 1.2
    lv_rad_offset = 0.006
    rv_rad_offset = 0.004
    la_rad_offset = -0.001
    ra_rad_offset = 0.0005
    lv_c_base_factor = 1.02
    rv_c_base_factor = 0.98

    return (
        # Heart main body
        # Upper heart (base)
        # Outer myocardium (base)
        Ellipsoid(-0.06 - dx_lv, 0.02 - y_offset, -0.1 + z_offset, 0.1595 * s_lv, 0.2145 * s_lv, 0.242 * s_lv, get_intensity(ti, :heart)),
        Ellipsoid(0.14 + dx_rv, 0.0 - y_offset, -0.1 + z_offset, 0.1595 * s_rv, 0.2145 * s_rv, 0.242 * s_rv, get_intensity(ti, :heart)),

        # Mid heart
        # Outer myocardium (mid)
        SuperEllipsoid(-0.06 - dx_lv, 0.02 - y_offset, 0.0 + z_offset, 0.1485 * s_lv, 0.2035 * s_lv, 0.1782 * s_lv, (2.5, 2.5, 2.5), get_intensity(ti, :heart)),
        SuperEllipsoid(0.14 + dx_rv, 0.0 - y_offset, 0.0 + z_offset, 0.1485 * s_rv, 0.2035 * s_rv, 0.1782 * s_rv, (2.5, 2.5, 2.5), get_intensity(ti, :heart)),

        # Left ventricle myocardium
        SuperEllipsoid(-0.063 - dx_lv, 0.02 - y_offset, (0.0 + z_offset) - z_sep_L, 0.251 * s_lv, 0.251 * s_lv, (0.209 * s_lv) * myocardium_bottom_z_scale, (2.0, 2.0, 2.0), get_intensity(ti, :heart)),
        SuperEllipsoid(-0.063 - dx_lv, 0.02 - y_offset, (0.08 + z_offset) - z_sep_L, 0.195 * s_lv, 0.195 * s_lv, 0.157 * s_lv, (3.0, 3.0, 2.0), get_intensity(ti, :heart)),

        # Left ventricle cavities (including base/mid)
        SuperEllipsoid(-0.06 - dx_lv, 0.02 - y_offset, (-0.1 + z_offset) - z_sep_L, (0.112125 * s_lv_c + lv_rad_offset) * lv_c_base_factor, (0.160875 * s_lv_c + lv_rad_offset) * lv_c_base_factor, (0.156 * s_lv_c) * lv_c_base_factor, (2.0, 2.0, 2.0), get_intensity(ti, :lv_blood)),
        SuperEllipsoid(-0.06 - dx_lv, 0.02 - y_offset, (0.0 + z_offset) - z_sep_L, (0.102375 * s_lv_c + lv_rad_offset), (0.151125 * s_lv_c + lv_rad_offset), 0.1404 * s_lv_c, (2.5, 2.5, 2.5), get_intensity(ti, :lv_blood)),
        SuperEllipsoid(-0.06 - dx_lv, 0.02 - y_offset, (0.0 + z_offset) - z_sep_L, 0.193288 * s_lv_c, 0.193288 * s_lv_c, 0.14366 * s_lv_c, (2.0, 2.0, 2.0), get_intensity(ti, :lv_blood)),
        SuperEllipsoid(-0.06 - dx_lv, 0.02 - y_offset, (0.04 + z_offset) - z_sep_L, 0.151496 * s_lv_c, 0.151496 * s_lv_c, 0.094032 * s_lv_c, (3.0, 3.0, 2.0), get_intensity(ti, :lv_blood)),

        # Right ventricle myocardium
        SuperEllipsoid(0.143 + dx_rv, 0.0 - y_offset, (0.0 + z_offset) - z_sep_R, 0.209 * s_rv, 0.209 * s_rv, (0.195 * s_rv) * myocardium_bottom_z_scale, (2.0, 2.0, 2.0), get_intensity(ti, :heart)),
        SuperEllipsoid(0.143 + dx_rv, 0.0 - y_offset, (0.08 + z_offset) - z_sep_R, 0.167 * s_rv, 0.167 * s_rv, 0.136 * s_rv, (3.0, 3.0, 2.0), get_intensity(ti, :heart)),

        # Right ventricle cavities (including base/mid)
        SuperEllipsoid(0.14 + dx_rv, 0.0 - y_offset, (-0.1 + z_offset) - z_sep_R, (0.11822 * s_rv_c + rv_rad_offset) * rv_c_base_factor, (0.16962 * s_rv_c + rv_rad_offset) * rv_c_base_factor, (0.16448 * s_rv_c) * rv_c_base_factor, (2.0, 2.0, 2.0), get_intensity(ti, :rv_blood)),
        SuperEllipsoid(0.14 + dx_rv, 0.0 - y_offset, (0.0 + z_offset) - z_sep_R, (0.10794 * s_rv_c + rv_rad_offset), (0.15934 * s_rv_c + rv_rad_offset), 0.148032 * s_rv_c, (2.5, 2.5, 2.5), get_intensity(ti, :rv_blood)),
        SuperEllipsoid(0.14 + dx_rv, 0.0 - y_offset, (0.0 + z_offset) - z_sep_R, 0.172112 * s_rv_c, 0.172112 * s_rv_c, 0.133248 * s_rv_c, (2.0, 2.0, 2.0), get_intensity(ti, :rv_blood)),
        SuperEllipsoid(0.14 + dx_rv, 0.0 - y_offset, (0.04 + z_offset) - z_sep_R, 0.1388 * s_rv_c, 0.1388 * s_rv_c, 0.094384 * s_rv_c, (3.0, 3.0, 2.0), get_intensity(ti, :rv_blood)),

        # Left atrium myocardium and cavity
        SuperEllipsoid(-0.101 - dx_la, -0.05 - y_offset, (0.25 + z_offset) + z_sep_L, 0.15 * s_la, 0.15 * s_la, 0.188 * s_la, (2.2, 2.2, 2.2), get_intensity(ti, :heart)),
        SuperEllipsoid(-0.101, -0.05 - y_offset, (0.25 + z_offset) + z_sep_L, (0.134352 * s_la_c + la_rad_offset), (0.134352 * s_la_c + la_rad_offset), 0.16794 * s_la_c, (2.2, 2.2, 2.2), get_intensity(ti, :la_blood)),

        # Right atrium myocardium and cavity
        SuperEllipsoid(0.161 + dx_ra, -0.07 - y_offset, (0.25 + z_offset) + z_sep_R, 0.15 * s_ra, 0.15 * s_ra, 0.188 * s_ra, (2.2, 2.2, 2.2), get_intensity(ti, :heart)),
        SuperEllipsoid(0.161, -0.07 - y_offset, (0.25 + z_offset) + z_sep_R, (0.126468 * s_ra_c + ra_rad_offset), (0.126468 * s_ra_c + ra_rad_offset), 0.158085 * s_ra_c, (2.2, 2.2, 2.2), get_intensity(ti, :ra_blood)),
    )
end

"""
Helper function to get vessel centerlines and segments
"""
function get_vessels(y_offset::Real, ti::AbstractTissueParameters)
    vessel_parts = ()
    z_offset = 0.2
    # Curved centerlines parameterized by z (normalized coordinates). These produce gentle 3D curvature.
    aorta_xy(z) = (-0.02 + 0.06 * sin(π * (z - 0.2)), -0.05 + 0.035 * sin(0.7π * (z - 0.2) + 0.4))
    pulm_xy(z) = (-0.05 + 0.05 * sin(π * (z - 0.22) + 0.2), -0.05 + 0.03 * sin(0.9π * (z - 0.22) - 0.3))
    svc_xy(z) = (0.1 + 0.05 * sin(0.8π * (z - 0.3)), -0.05 + 0.03 * sin(0.6π * (z - 0.3) + 0.2))

    function add_vessel(current_parts, xyf, z_center, radius_xy, height_z, n)
        zc = z_center + z_offset
        x_center, y_center = xyf(zc)
        return (current_parts..., SuperEllipsoid(x_center, -y_center - y_offset, zc, radius_xy, radius_xy, height_z, (n, n, n), get_intensity(ti, :vessels_blood)))
    end

    # Segment lists; lowest segments start at ~0.20 to just touch heart base
    aorta_segments = [(1.0, 0.08), (0.95, 0.08), (0.9, 0.08), (0.75, 0.12), (0.6, 0.12), (0.45, 0.12), (0.32, 0.1)]
    pulmonary_segments = [(0.75, 0.08), (0.62, 0.1), (0.47, 0.12), (0.34, 0.12), (0.3, 0.1)]
    svc_segments = [(1.0, 0.08), (0.95, 0.08), (0.82, 0.1), (0.68, 0.12), (0.55, 0.12), (0.45, 0.08)]

    # Aorta (ascending)
    for (z_center, half_height) in aorta_segments
        vessel_parts = add_vessel(vessel_parts, aorta_xy, z_center, 0.06, half_height, 2.5)
    end

    # Pulmonary artery
    for (z_center, half_height) in pulmonary_segments
        vessel_parts = add_vessel(vessel_parts, pulm_xy, z_center, 0.05, half_height, 2.5)
    end

    # Superior vena cava
    for (z_center, half_height) in svc_segments
        vessel_parts = add_vessel(vessel_parts, svc_xy, z_center, 0.04, half_height, 2.5)
    end
    return vessel_parts
end

# Spinal curvature function: Y offset based on Z position
function spine_curve(z)
    # Single sinusoidal curvature with linearly increasing amplitude and period toward lumbar
    # Progress from neck (z≈1.0) to lumbar (z≈-1.0)
    p = 0.5 * (1.0 - z)  # 0 at neck, 1 at lumbar
    A_neck, A_lumbar = 0.07, 0.2   # amplitude
    T_neck, T_lumbar = 1.5, 2.3   # period (in z units)
    A = A_neck + p * (A_lumbar - A_neck)
    T = T_neck + p * (T_lumbar - T_neck)
    ω = 2π / T
    base_y = 0.4 + 0.25 * p  # slight linear slope downward toward lumbar
    phase_shift = -0.7  # slight shift to align with torso
    return base_y - A * sin(ω * (z + phase_shift))
end

"""
Helper function to get spine (vertebral column) with spinal curvature.
"""
function get_spine(ti::AbstractTissueParameters)
    parts = ()
    # Upper thoracic vertebrae
    for z_pos in [1.05, 0.95, 0.85, 0.7, 0.55, 0.4]
        y_curve = spine_curve(z_pos)
        parts = (parts..., Ellipsoid(0.0, y_curve, z_pos, 0.084, 0.084, 0.084, get_intensity(ti, :bones)))
    end
    # Mid thoracic vertebrae
    for z_pos in [0.25, 0.1, -0.05, -0.2]
        y_curve = spine_curve(z_pos)
        parts = (parts..., Ellipsoid(0.0, y_curve, z_pos, 0.084, 0.084, 0.084, get_intensity(ti, :bones)))
    end
    # Lower thoracic to lumbar vertebrae
    for z_pos in [-0.4, -0.6, -0.8, -1.0]
        y_curve = spine_curve(z_pos)
        parts = (parts..., Ellipsoid(0.0, y_curve, z_pos, 0.095, 0.095, 0.095, get_intensity(ti, :bones)))
    end
    return parts
end

"""
Helper function to get ribs with curvature and variable arc coverage.
"""
function get_ribs(rib_width_scale::Real, rib_depth_scale::Real, y_offset::Real, ti::AbstractTissueParameters)
    parts = ()

    # Helper function to create curved rib with variable arc coverage
    function create_rib_curve(current_parts, z_pos, num_segments, torso_width, torso_depth, arc_coverage)
        function spine_curve_local(z)
            if z > 0.5
                return 0.45 - 0.18 * (z - 0.5)^2.2
            elseif z > -0.3
                return 0.5 + 0.06 * sin((z + 0.3) / 0.8 * π)
            else
                return 0.48 - 0.04 * ((z + 0.3) / 0.5)^2
            end
        end
        spine_y = spine_curve(z_pos)

        # arc_coverage: 1.0 = full 360° (complete circle), 0.5 = 180° (posterior only)
        if arc_coverage >= 1.0
            angles = range(-3π / 2, π / 2, length = num_segments)
        else
            total_angle = 2π * arc_coverage
            angle_center = -π / 2  # Posterior (at spine)
            angle_start = angle_center - total_angle / 2
            angle_end = angle_center + total_angle / 2
            angles = range(angle_start, angle_end, length = Int(round(num_segments * arc_coverage)))
        end

        local_parts = current_parts
        for angle in angles
            # Ribs extend from spine (posterior) wrapping to anterior
            x_pos = torso_width * cos(angle)
            y_pos = spine_y - torso_depth - torso_depth * sin(angle) - y_offset

            # Ribs slope downward anteriorly (higher at posterior/spine, lower anteriorly)
            z_adjustment = (π - abs(π / 2 + angle)) / (2π) * 0.06

            local_parts = (local_parts..., Ellipsoid(x_pos, y_pos, z_pos + z_adjustment, 0.04, 0.04, 0.055, get_intensity(ti, :bones)))
        end
        return local_parts
    end

    num_segments = 80
    # Upper ribs with full coverage
    parts = create_rib_curve(parts, 0.6, num_segments, 0.64 * rib_width_scale, 0.53 * rib_depth_scale, 1.0)
    parts = create_rib_curve(parts, 0.45, num_segments, 0.68 * rib_width_scale, 0.58 * rib_depth_scale, 1.0)
    parts = create_rib_curve(parts, 0.3, num_segments, 0.72 * rib_width_scale, 0.61 * rib_depth_scale, 1.0)
    parts = create_rib_curve(parts, 0.15, num_segments, 0.76 * rib_width_scale, 0.62 * rib_depth_scale, 1.0)

    # Ribs around mid-chest with slight reduction in coverage
    parts = create_rib_curve(parts, 0.0, num_segments, 0.8 * rib_width_scale, 0.62 * rib_depth_scale, 1.0)
    parts = create_rib_curve(parts, -0.15, num_segments, 0.8 * rib_width_scale, 0.62 * rib_depth_scale, 0.9)

    # Lower ribs with further reduction in coverage
    parts = create_rib_curve(parts, -0.3, num_segments, 0.78 * rib_width_scale, 0.58 * rib_depth_scale, 0.75)
    parts = create_rib_curve(parts, -0.45, num_segments, 0.78 * rib_width_scale, 0.59 * rib_depth_scale, 0.6)
    parts = create_rib_curve(parts, -0.6, num_segments, 0.8 * rib_width_scale, 0.6 * rib_depth_scale, 0.5)

    return parts
end

"""
Helper function to add arm bones.
"""
function get_arm_bones(ti::AbstractTissueParameters)
    parts = ()

    # Left arm bones
    arm_bone_positions_l = [
        (-0.5, 0.28, 0.58, 0.15, 0.075, 0.15),
        (-0.55, 0.25, 0.56, 0.16, 0.08, 0.2),
        (-0.6, 0.23, 0.54, 0.165, 0.083, 0.26),
        (-0.65, 0.2, 0.52, 0.17, 0.1, 0.35),
        (-0.7, 0.15, 0.51, 0.175, 0.12, 0.22),
        (-0.75, 0.05, 0.5, 0.175, 0.15, 0.175),
        (-0.8, 0.0, 0.5, 0.17, 0.17, 0.17),
        (-0.85, 0.0, 0.5, 0.165, 0.165, 0.165),
        (-0.9, 0.0, 0.48, 0.16, 0.16, 0.16),
        (-0.95, 0.0, 0.45, 0.155, 0.155, 0.155),
        (-1.0, 0.0, 0.42, 0.15, 0.15, 0.15),
        (-1.05, 0.0, 0.39, 0.145, 0.145, 0.145),
        (-1.1, 0.0, 0.36, 0.14, 0.14, 0.14),
        (-1.15, 0.0, 0.33, 0.135, 0.135, 0.135),
        (-1.2, 0.0, 0.3, 0.13, 0.13, 0.13),
    ]

    for (x_pos, y_pos, z_pos, radius_x, radius_y, radius_z) in arm_bone_positions_l
        parts = (parts..., Ellipsoid(x_pos, y_pos + 0.165, z_pos, radius_x / 2, radius_y / 2, radius_z / 2, get_intensity(ti, :bones)))
    end

    # Right arm bones
    arm_bone_positions_r = [
        (0.5, 0.28, 0.58, 0.15, 0.075, 0.15),
        (0.55, 0.25, 0.56, 0.16, 0.08, 0.2),
        (0.6, 0.23, 0.54, 0.165, 0.083, 0.26),
        (0.65, 0.2, 0.52, 0.17, 0.1, 0.35),
        (0.7, 0.15, 0.51, 0.175, 0.12, 0.22),
        (0.75, 0.05, 0.5, 0.175, 0.15, 0.175),
        (0.8, 0.0, 0.5, 0.17, 0.17, 0.17),
        (0.85, 0.0, 0.5, 0.165, 0.165, 0.165),
        (0.9, 0.0, 0.48, 0.16, 0.16, 0.16),
        (0.95, 0.0, 0.45, 0.155, 0.155, 0.155),
        (1.0, 0.0, 0.42, 0.15, 0.15, 0.15),
        (1.05, 0.0, 0.39, 0.145, 0.145, 0.145),
        (1.1, 0.0, 0.36, 0.14, 0.14, 0.14),
        (1.15, 0.0, 0.33, 0.135, 0.135, 0.135),
        (1.2, 0.0, 0.3, 0.13, 0.13, 0.13),
    ]

    for (x_pos, y_pos, z_pos, radius_x, radius_y, radius_z) in arm_bone_positions_r
        parts = (parts..., Ellipsoid(x_pos, y_pos + 0.165, z_pos, radius_x / 2, radius_y / 2, radius_z / 2, get_intensity(ti, :bones)))
    end

    return parts
end

"""
Helper function to get liver parts.
"""
function get_liver(diaphragm_upshift::Real, y_offset::Real, xy_scale::Real, ti::AbstractTissueParameters)
    return (
        # Liver (right upper abdomen) moves with diaphragm
        SuperEllipsoid(0.3, -0.15 - y_offset, -0.55 + diaphragm_upshift, 0.385 * xy_scale, 0.33 * xy_scale, 0.3, (2.5, 2.5, 2.5), get_intensity(ti, :liver)),

        # Left lobe
        SuperEllipsoid(0.0, -0.12 - y_offset, -0.5 + diaphragm_upshift, 0.22 * xy_scale, 0.275 * xy_scale, 0.25, (2.5, 2.5, 2.5), get_intensity(ti, :liver)),
    )
end

"""
Helper function to get stomach parts.
"""
function get_stomach(diaphragm_upshift::Real, y_offset::Real, xy_scale::Real, ti::AbstractTissueParameters)
    return (
        # Stomach (left upper abdomen) moves with diaphragm
        # Fundus
        SuperEllipsoid(-0.3, -0.05 - y_offset, -0.45 + diaphragm_upshift, 0.33 * xy_scale, 0.198 * xy_scale, 0.2, (2.5, 2.5, 2.5), get_intensity(ti, :stomach)),

        # Body
        SuperEllipsoid(-0.2, -0.08 - y_offset, -0.55 + diaphragm_upshift, 0.176 * xy_scale, 0.176 * xy_scale, 0.22, (2.5, 2.5, 2.5), get_intensity(ti, :stomach)),
    )
end
