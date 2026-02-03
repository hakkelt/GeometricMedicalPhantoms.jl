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
    get_tubes_shapes(tg::TubesGeometry, ti::TubesIntensities, output_eltype::Type=Float64)

Generate the cylinder shapes for the tubes phantom.

Returns a tuple of CylinderZ objects representing the outer cylinder and all tubes.

# Arguments
- `tg::TubesGeometry`: Geometry parameters
- `ti::TubesIntensities`: Intensity parameters
- `output_eltype::Type`: Element type for the output (default: Float64)

# Throws
- `ArgumentError`: If the geometry parameters don't allow fitting the desired number of tubes
"""
function get_tubes_shapes(tg::TubesGeometry, ti::TubesIntensities, output_eltype::Type=Float64)
    n_tubes = length(ti.tube_fillings)

    R = tg.outer_radius # outer radius
    r = R * sin(π / n_tubes) / (1.0 + sin(π / n_tubes)) # initial tube radius estimate
    R_centers = R - r
    wall_radius = r * (1 - tg.gap_fraction / 2) # adjust tube radius for gap fraction
    tube_radius = r * (1 - tg.gap_fraction) # inner filling radius
    tube_outer_height = tg.outer_height * tg.tubes_height_fraction
    tube_inner_height = tube_outer_height - 2 * tg.tube_wall_thickness
    wall_thickness = wall_radius - tube_radius
    
    # Create outer cylinder
    outer_cylinder = CylinderZ(
        0.0, 
        0.0, 
        0.0, 
        tg.outer_radius, 
        tg.outer_height, 
        ti.outer_cylinder
    )
    
    # Create tube cylinders
    shapes = [outer_cylinder]
    
    for i in 1:n_tubes
        # Calculate position on the inner circle
        angle = 2π * (i - 1) / n_tubes
        cx = R_centers * cos(angle)
        cy = R_centers * sin(angle)
        
        # Outer wall of tube (larger radius)
        wall_cylinder = CylinderZ(cx, cy, 0.0, wall_radius, tube_outer_height, ti.tube_wall)
        push!(shapes, wall_cylinder)
        
        # Inner filling of tube (smaller radius)
        filling_cylinder = CylinderZ(cx, cy, 0.0, tube_radius, tube_inner_height, ti.tube_fillings[i])
        push!(shapes, filling_cylinder)
    end
    
    return tuple(shapes...)
end
