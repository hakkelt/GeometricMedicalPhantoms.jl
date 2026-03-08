"""
    TubesGeometry

Geometry parameters for the tubes phantom.

# Fields
- `outer_radius::Float64`: Radius of the outer cylinder
- `outer_height::Float64`: Height of the outer cylinder
- `tube_wall_thickness::Float64`: Thickness of tube walls
- `gap_fraction::Float64`: Fraction of space between tubes
"""
Base.@kwdef struct TubesGeometry
    outer_radius::Float64 = 0.4
    outer_height::Float64 = 0.8
    tubes_height_fraction::Float64 = 0.9
    tube_wall_thickness::Float64 = 0.025
    gap_fraction::Float64 = 0.3
end

"""
Draw all tube shapes onto `ctx`.  The outer cylinder is drawn first, then each
tube's wall + filling pair is drawn.
"""
function draw_tubes_shapes!(ctx, tg::TubesGeometry, ti::TubesIntensities)
    n_tubes = length(ti.tube_fillings)

    R = tg.outer_radius
    r = R * sin(π / n_tubes) / (1.0 + sin(π / n_tubes))
    R_centers = R - r
    wall_radius = r * (1 - tg.gap_fraction / 2)
    tube_radius = r * (1 - tg.gap_fraction)
    tube_outer_height = tg.outer_height * tg.tubes_height_fraction
    tube_inner_height = tube_outer_height - 2 * tg.tube_wall_thickness

    # Outer cylinder
    draw_shape!(ctx, CylinderZ(0.0, 0.0, 0.0, tg.outer_radius, tg.outer_height, ti.outer_cylinder))

    # Individual tubes (wall + filling)
    for i in 1:n_tubes
        angle = 2π * (i - 1) / n_tubes
        cx = R_centers * cos(angle)
        cy = R_centers * sin(angle)
        draw_shape!(ctx, CylinderZ(cx, cy, 0.0, wall_radius, tube_outer_height, ti.tube_wall))
        draw_shape!(ctx, CylinderZ(cx, cy, 0.0, tube_radius, tube_inner_height, ti.tube_fillings[i]))
    end
    return nothing
end
