
"""
    get_shepp_logan_shapes(p::SheppLoganIntensities)

Return a tuple of 12 `RotatedEllipsoid` objects representing the 3D Shepp-Logan phantom
with intensities specified by `p`.
"""
function get_shepp_logan_shapes(p::SheppLoganIntensities)
    # Radii are already scaled by 0.5 where needed in ImagePhantoms.jl logic
    # We follow the same logic.
    # should by shifted by 2.5 cm in z-direction
    
    return (
        # 1: skull
        RotatedEllipsoid(0.0, 0.0, 0.0, 0.69, 0.92, 0.9, 0.0, 0.0, 0.0, get_intensity(p, :skull)),
        # 2: brain
        RotatedEllipsoid(0.0, -0.0184, 0.0, 0.6624, 0.874, 0.88, 0.0, 0.0, 0.0, get_intensity(p, :brain)),
        # 3: right big (x=0.22)
        RotatedEllipsoid(-0.22, 0.0, -0.25, 0.41, 0.16, 0.21, -72*π/180, 0.0, 0.0, get_intensity(p, :right_big)),
        # 4: left big (x=-0.22)
        RotatedEllipsoid(0.22, 0.0, -0.25, 0.31, 0.11, 0.22, 72*π/180, 0.0, 0.0, get_intensity(p, :left_big)),
        # 5: top
        RotatedEllipsoid(0.0, 0.35, -0.25, 0.21, 0.25, 0.35, 0.0, 0.0, 0.0, get_intensity(p, :top)),
        # 6: middle high
        RotatedEllipsoid(0.0, 0.1, -0.25, 0.046, 0.046, 0.046, 0.0, 0.0, 0.0, get_intensity(p, :middle_high)),
        # 7: bottom left
        RotatedEllipsoid(-0.08, -0.605, -0.25, 0.046, 0.023, 0.02, 0.0, 0.0, 0.0, get_intensity(p, :bottom_left)),
        # 8: middle low
        RotatedEllipsoid(0.0, -0.1, -0.25, 0.046, 0.046, 0.046, 0.0, 0.0, 0.0, get_intensity(p, :middle_low)),
        # 9: bottom center
        RotatedEllipsoid(0.0, -0.605, -0.25, 0.023, 0.023, 0.023, 0.0, 0.0, 0.0, get_intensity(p, :bottom_center)),
        # 10: bottom right
        RotatedEllipsoid(0.06, -0.605, -0.25, 0.046, 0.023, 0.02, -90*π/180, 0.0, 0.0, get_intensity(p, :bottom_right)),
        # 11: 
        RotatedEllipsoid(0.06, -0.105, 0.0625, 0.056, 0.04, 0.1, -90*π/180, 0.0, 0.0, get_intensity(p, :extra_1)),
        # 12: 
        RotatedEllipsoid(0.0, 0.1, 0.625, 0.056, 0.056, 0.1, 0.0, 0.0, 0.0, get_intensity(p, :extra_2))
    )
end

#function get_shepp_logan_shapes(p::SheppLoganIntensities)
#    # Radii are already scaled by 0.5 where needed in ImagePhantoms.jl logic
#    # We follow the same logic.
#    
#    return (
#        # 1: skull
#        RotatedEllipsoid(0.0, 0.0, 0.0, 0.69/2, 0.92/2, 0.9/2, 0.0, 0.0, 0.0, get_intensity(p, :skull)),
#        # 2: brain
#        RotatedEllipsoid(0.0, -0.0184/2, 0.0, 0.6624/2, 0.874/2, 0.88/2, 0.0, 0.0, 0.0, get_intensity(p, :brain)),
#        # 3: right big (x=0.22)
#        RotatedEllipsoid(0.22/2, 0.0, -0.25/2, 0.31/2, 0.11/2, 0.22/2, 72*π/180, 0.0, 0.0, get_intensity(p, :right_big)),
#        # 4: left big (x=-0.22)
#        RotatedEllipsoid(-0.22/2, 0.0, -0.25/2, 0.41/2, 0.16/2, 0.21/2, -72*π/180, 0.0, 0.0, get_intensity(p, :left_big)),
#        # 5: top
#        RotatedEllipsoid(0.0, 0.35/2, -0.25/2, 0.21/2, 0.25/2, 0.35/2, 0.0, 0.0, 0.0, get_intensity(p, :top)),
#        # 6: middle high
#        RotatedEllipsoid(0.0, 0.1/2, -0.25/2, 0.046/2, 0.046/2, 0.046/2, 0.0, 0.0, 0.0, get_intensity(p, :middle_high)),
#        # 7: bottom left
#        RotatedEllipsoid(-0.08/2, -0.605/2, -0.25/2, 0.046/2, 0.023/2, 0.02/2, 0.0, 0.0, 0.0, get_intensity(p, :bottom_left)),
#        # 8: middle low
#        RotatedEllipsoid(0.0, -0.1/2, -0.25/2, 0.046/2, 0.046/2, 0.046/2, 0.0, 0.0, 0.0, get_intensity(p, :middle_low)),
#        # 9: bottom center
#        RotatedEllipsoid(0.0, -0.605/2, -0.25/2, 0.023/2, 0.023/2, 0.023/2, 0.0, 0.0, 0.0, get_intensity(p, :bottom_center)),
#        # 10: bottom right
#        RotatedEllipsoid(0.06/2, -0.605/2, -0.25/2, 0.046/2, 0.023/2, 0.02/2, -90*π/180, 0.0, 0.0, get_intensity(p, :bottom_right)),
#        # 11: 
#        RotatedEllipsoid(0.06/2, -0.105/2, 0.0625/2, 0.056/2, 0.04/2, 0.1/2, -90*π/180, 0.0, 0.0, get_intensity(p, :extra_1)),
#        # 12: 
#        RotatedEllipsoid(0.0, 0.1/2, 0.625/2, 0.056/2, 0.056/2, 0.1/2, 0.0, 0.0, 0.0, get_intensity(p, :extra_2))
#    )
#end
