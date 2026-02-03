
"""
    get_shepp_logan_shapes(p::SheppLoganIntensities)

Return a tuple of 12 `Shape` objects representing the 3D Shepp-Logan phantom
with intensities specified by `p`.

# Attribution
- The coefficients were fetched from ImagePhantoms.jl [3].
   - the coefficients of this source is from [2] with modifications because
   the original coefficients in [2] deviate from the original Shepp-Logan phantom:
      - first, there is a duplicated row (errata: [4]), 
      - second, it contains only 10 ellipsoids, while 12 is needed to match the
      original 2D Shepp-Logan phantom in [1] (one from the three ellipses in the
      bottom, and one smaller ellipse in the center is missing if one would render
      a phantom with these coefficients in axial plane at slice position -0.25
      compared to the original) -- this was pointed out by Lei Shu PhD student
      at Stanford (leizhu@stanford.edu)
- the coefficients in the current implementation have another deviation from the one in [3]:
it is shifted by 0.25 in the z-direction, so that the central axial slice equals to the
original 2D Shepp-Logan phantom

# References
[1] L. A. Shepp, “Computerized tomography and nuclear magnetic resonance,” J Comput Assist Tomogr, vol. 4, no. 1, pp. 94–107, Feb. 1980, doi: 10.1097/00004728-198002000-00018.
[2] A. C. Kak and M. Slaney, Principles of Computerized Tomographic Imaging. IEEE Press, 1988. page 102.
[3] https://github.com/JuliaImageRecon/ImagePhantoms.jl/blob/main/src/shepplogan.jl 
[4] https://www.slaney.org/pct/pct-errata.html
"""
function get_shepp_logan_shapes(p::SheppLoganIntensities)::NTuple{12, Union{Ellipsoid, RotatedEllipsoid}}
    return (
        # 1: skull
        Ellipsoid(+0.0000, +0.0000, +0.2500, +0.6900, +0.9200, +0.9000, get_intensity(p, :skull)),
        # 2: brain
        Ellipsoid(+0.0000, -0.0184, +0.2500, +0.6624, +0.8740, +0.8800, get_intensity(p, :brain)),
        # 3: right big
        RotatedEllipsoid(-0.2200, +0.0000, +0.0000, +0.4100, +0.1600, +0.2100, -72*π/180, 0.0, 0.0, get_intensity(p, :right_big)),
        # 4: left big
        RotatedEllipsoid(+0.2200, +0.0000, +0.0000, +0.3100, +0.1100, +0.2200, +72*π/180, 0.0, 0.0, get_intensity(p, :left_big)),
        # 5: top
        Ellipsoid(+0.0000, +0.3500, +0.0000, +0.2100, +0.2500, +0.3500, get_intensity(p, :top)),
        # 6: middle high
        Ellipsoid(+0.0000, +0.1000, +0.0000, +0.0460, +0.0460, +0.0460, get_intensity(p, :middle_high)),
        # 7: bottom left
        Ellipsoid(-0.0800, -0.6050, +0.0000, +0.0460, +0.0230, +0.0200, get_intensity(p, :bottom_left)),
        # 8: middle low
        Ellipsoid(+0.0000, -0.1000, +0.0000, +0.0460, +0.0460, +0.0460, get_intensity(p, :middle_low)),
        # 9: bottom center
        Ellipsoid(+0.0000, -0.6050, +0.0000, +0.0230, +0.0230, +0.0230, get_intensity(p, :bottom_center)),
        # 10: bottom right
        RotatedEllipsoid(+0.0600, -0.6050, +0.0000, +0.0460, +0.0230, +0.0200, -90*π/180, 0.0, 0.0, get_intensity(p, :bottom_right)),
        # 11: extra 1
        RotatedEllipsoid(+0.0600, -0.1050, +0.3125, +0.0560, +0.0400, +0.1000, -90*π/180, 0.0, 0.0, get_intensity(p, :extra_1)),
        # 12: extra 2
        Ellipsoid(+0.0000, +0.1000, +0.8750, +0.0560, +0.0560, +0.1000, get_intensity(p, :extra_2))
    )
end
