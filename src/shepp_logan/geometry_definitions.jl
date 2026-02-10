"""
    get_shepp_logan_shapes(p::SheppLoganIntensities)

Return a tuple of 12 `Shape` objects representing the 3D Shepp-Logan phantom
with intensities specified by `p`.

# Attribution
The original 2D Shepp-Logan phantom was introduced by Shepp and Logan in 1974 [1]
as a test object for evaluating image reconstruction algorithms in computed tomography.
The 3D extension of the Shepp-Logan phantom was later developed to provide a more
comprehensive test object for 3D imaging modalities [2,6]. A variant of the 2D phantom
with modified intensities was also proposed to have better contrast for easier visualization
was suggested by Toft in 1996 [3]. Another variant of the 3D phantom with two additional ellipsoids
to better match the original 2D design was suggested in the PhD thesis of Caroline Jacobson
in 1996 [4]. The coefficients in the current implementation are based on the one in [4],
but with a shift in z-axis by 0.25 to make the connection between the original 2D phantom
and the 3D volume more intuitive by centering the axial slice that matches the 2D phantom.

The actual implementation is based on the coefficients from ImagePhantoms.jl [5], which is
a widely used package for generating analytical phantoms.

# References
[1] L. A. Shepp and B. F. Logan, “The Fourier reconstruction of a head section,” IEEE Trans. Nucl. Sci., 1974.  
[2] A. C. Kak and M. Slaney, Principles of Computerized Tomographic Imaging. IEEE Press, 1988.  
[3] P. A. Toft, “The Radon Transform - Theory and Implementation,” PhD Thesis, 1996.  
[4] C. Jacobson, “Fourier Methods in 3D-Reconstruction from Cone-Beam Data,” PhD Thesis, Department of Electrical Engineering, Linköping University, Linköping, Sweden, 1996.  
[5] https://github.com/JuliaImageRecon/ImagePhantoms.jl/blob/main/src/shepplogan.jl
[6] https://www.slaney.org/pct/pct-errata.html
"""
function get_shepp_logan_shapes(p::SheppLoganIntensities)::NTuple{12, Union{Ellipsoid, RotatedEllipsoid}}
    return (
        # 1: skull
        Ellipsoid(+0.0, +0.0, +0.25, +0.69, +0.92, +0.9, get_intensity(p, :skull)),
        # 2: brain
        Ellipsoid(+0.0, -0.0184, +0.25, +0.6624, +0.874, +0.88, get_intensity(p, :brain)),
        # 3: right big
        RotatedEllipsoid(-0.22, +0.0, +0.0, +0.41, +0.16, +0.21, -72 * π / 180, 0.0, 0.0, get_intensity(p, :right_big)),
        # 4: left big
        RotatedEllipsoid(+0.22, +0.0, +0.0, +0.31, +0.11, +0.22, +72 * π / 180, 0.0, 0.0, get_intensity(p, :left_big)),
        # 5: top
        Ellipsoid(+0.0, +0.35, +0.0, +0.21, +0.25, +0.35, get_intensity(p, :top)),
        # 6: middle high
        Ellipsoid(+0.0, +0.1, +0.0, +0.046, +0.046, +0.046, get_intensity(p, :middle_high)),
        # 7: bottom left
        Ellipsoid(-0.08, -0.605, +0.0, +0.046, +0.023, +0.02, get_intensity(p, :bottom_left)),
        # 8: middle low
        Ellipsoid(+0.0, -0.1, +0.0, +0.046, +0.046, +0.046, get_intensity(p, :middle_low)),
        # 9: bottom center
        Ellipsoid(+0.0, -0.605, +0.0, +0.023, +0.023, +0.023, get_intensity(p, :bottom_center)),
        # 10: bottom right
        RotatedEllipsoid(+0.06, -0.605, +0.0, +0.046, +0.023, +0.02, -90 * π / 180, 0.0, 0.0, get_intensity(p, :bottom_right)),
        # 11: extra 1
        RotatedEllipsoid(+0.06, -0.105, +0.3125, +0.056, +0.04, +0.1, -90 * π / 180, 0.0, 0.0, get_intensity(p, :extra_1)),
        # 12: extra 2
        Ellipsoid(+0.0, +0.1, +0.875, +0.056, +0.056, +0.1, get_intensity(p, :extra_2)),
    )
end
