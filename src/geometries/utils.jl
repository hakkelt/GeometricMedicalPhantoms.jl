"""
Abstract type for geometric shapes used in medical phantoms.
"""
abstract type Shape end

struct AdditiveIntensityValue{T}
    value::T
end

struct MaskingIntensityValue{T}
    value::T
end

@inline function draw_pixel!(image, intensity::AdditiveIntensityValue, idx...)
    image[idx...] += intensity.value
end

@inline function draw_pixel!(image, intensity::MaskingIntensityValue, idx...)
    image[idx...] = intensity.value
end

# Restrict computation to the enclosing axis-aligned box to avoid full-volume work
@inline function idx_bounds(ax::AbstractVector, c::Real, r::Real)
    n = length(ax)
    step = n > 1 ? (ax[2] - ax[1]) : 1.0
    i_min = floor(Int, 1 + ((c - r) - ax[1]) / step)
    i_max = ceil(Int, 1 + ((c + r) - ax[1]) / step)
    if n < i_min || i_max < 1
        return -1, -1
    end
    if i_min < 1
        i_min = 1
    end
    if n < i_max
        i_max = n
    end
    return i_min, i_max
end

"""
Helper function to draw a shape onto a 2D slice.
Dispatches to the appropriate draw! call based on axis orientation.
"""
function draw_2d!(image::AbstractArray{T,2}, ax_1n, ax_2n, ax_3_val::Real, axis::Symbol, shape::Shape) where T
    if axis == :axial
        # Axial: x-y plane, z is fixed
        draw!(image, ax_1n, ax_2n, ax_3_val, shape)
    elseif axis == :coronal
        # Coronal: x-z plane, y is fixed (swap y and z)
        shape_rotated = rotate_coronal(shape)
        draw!(image, ax_1n, ax_2n, ax_3_val, shape_rotated)
    elseif axis == :sagittal
        # Sagittal: y-z plane, x is fixed (swap x with z, then y with x)
        shape_rotated = rotate_sagittal(shape)
        draw!(image, ax_1n, ax_2n, ax_3_val, shape_rotated)
    end
    return image
end
