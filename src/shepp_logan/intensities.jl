"""
    SheppLoganIntensities{T}

Struct to hold intensity values for the 12 ellipsoids in a 3D Shepp-Logan phantom.
For 2D phantoms, only the first 10 values are typically used.

Fields:
- `skull`: Intensity of the skull.
- `brain`: Intensity of the brain.
- `right_big`: Intensity of the right big ellipsoid.
- `left_big`: Intensity of the left big ellipsoid.
- `top`: Intensity of the top ellipsoid.
- `middle_high`: Intensity of the middle high ellipsoid.
- `bottom_left`: Intensity of the bottom left ellipsoid.
- `middle_low`: Intensity of the middle low ellipsoid.
- `bottom_center`: Intensity of the bottom center ellipsoid.
- `bottom_right`: Intensity of the bottom right ellipsoid.
- `extra_1`: Intensity of the extra 1 ellipsoid.
- `extra_2`: Intensity of the extra 2 ellipsoid.

Note:
All intensities are additive values, so the total intensity at a given point is the sum of the intensities of all ellipsoids that contain that point.
"""
Base.@kwdef struct SheppLoganIntensities{T}
    skull::T = 0.0
    brain::T = 0.0
    right_big::T = 0.0
    left_big::T = 0.0
    top::T = 0.0
    middle_high::T = 0.0
    bottom_left::T = 0.0
    middle_low::T = 0.0
    bottom_center::T = 0.0
    bottom_right::T = 0.0
    extra_1::T = 0.0
    extra_2::T = 0.0
end

"""
    CTSheppLoganIntensities()

Create a `SheppLoganIntensities` object with original CT version values.

# Attribution
The intensities are fetched from the original paper [1].

# References
[1] L. A. Shepp and B. F. Logan, “The Fourier reconstruction of a head section,” IEEE Trans. Nucl. Sci., vol. 21, no. 3, pp. 21–43, Jun. 1974, doi: 10.1109/TNS.1974.6499235.
"""
function CTSheppLoganIntensities()
    return SheppLoganIntensities(
        skull = 2.0, brain = -0.98, right_big = -0.02, left_big = -0.02, top = 0.01,
        middle_high = 0.01, bottom_left = 0.01, middle_low = 0.01, bottom_center = 0.01, bottom_right = 0.01,
        extra_1 = 0.02, extra_2 = -0.02
    )
end

"""
    MRISheppLoganIntensities()

Create a `SheppLoganIntensities` object with MRI (Toft's) version values.

# Attribution
The intensities are from the PhD thesis of Peter Aundal Toft [1].

# References
[1] P. A. Toft, “The Radon Transform - Theory and Implementation,” PhD Thesis, Technical University of Denmark, Kgs. Lyngby, Denmark, 1996. [Online]. Available: https://orbit.dtu.dk/files/5529668/Binder1.pdf
"""
function MRISheppLoganIntensities()
    return SheppLoganIntensities(
        skull = 1.0, brain = -0.8, right_big = -0.2, left_big = -0.2, top = 0.1,
        middle_high = 0.1, bottom_left = 0.1, middle_low = 0.1, bottom_center = 0.1, bottom_right = 0.1,
        extra_1 = 0.1, extra_2 = -0.1 # Extended with similar contrast for 3D
    )
end

"""
    SheppLoganMask(; kwargs...)

Create a `SheppLoganIntensities{Bool}` object for masking specific ellipsoids.
Defaults to all `false`. Use keyword arguments to set specific ellipsoids to `true`.
"""
function SheppLoganMask(; kwargs...)
    return SheppLoganIntensities{Bool}(; kwargs...)
end

"""
Helper function to get intensity.
"""
@inline function get_intensity(ti::SheppLoganIntensities, field::Symbol)
    return AdditiveIntensityValue(getfield(ti, field))
end

@inline function get_intensity(ti::SheppLoganIntensities{Bool}, field::Symbol)
    return MaskingIntensityValue(getfield(ti, field))
end
