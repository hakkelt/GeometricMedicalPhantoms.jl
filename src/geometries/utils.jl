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
    return image[idx...] += intensity.value
end

@inline function draw_pixel!(image, intensity::MaskingIntensityValue, idx...)
    return image[idx...] = intensity.value
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
Drawing context for 3D phantom rendering.
Holds the image array and normalized axes for type-stable dispatch.
"""
struct DrawContext3D{I <: AbstractArray, AX <: AbstractVector}
    image::I
    ax_x::AX
    ax_y::AX
    ax_z::AX
end

"""
Drawing context for 2D phantom slice rendering.
The axis orientation `A` is encoded as a type parameter for compile-time dispatch.
"""
struct DrawContext2D{A, I <: AbstractArray, AX <: AbstractVector, T <: Real}
    image::I
    ax_1::AX
    ax_2::AX
    ax_3_val::T
    function DrawContext2D{A}(image::I, ax_1::AX, ax_2::AX, ax_3_val::T) where {A, I <: AbstractArray, AX <: AbstractVector, T <: Real}
        return new{A, I, AX, T}(image, ax_1, ax_2, ax_3_val)
    end
end

@inline function draw_shape!(ctx::DrawContext3D, shape::Shape)
    draw!(ctx.image, ctx.ax_x, ctx.ax_y, ctx.ax_z, shape)
    return nothing
end

@inline function draw_shape!(ctx::DrawContext2D{:axial}, shape::Shape)
    draw!(ctx.image, ctx.ax_1, ctx.ax_2, ctx.ax_3_val, shape)
    return nothing
end

@inline function draw_shape!(ctx::DrawContext2D{:coronal}, shape::Shape)
    rotated = rotate_coronal(shape)
    draw!(ctx.image, ctx.ax_1, ctx.ax_2, ctx.ax_3_val, rotated)
    return nothing
end

@inline function draw_shape!(ctx::DrawContext2D{:sagittal}, shape::Shape)
    rotated = rotate_sagittal(shape)
    draw!(ctx.image, ctx.ax_1, ctx.ax_2, ctx.ax_3_val, rotated)
    return nothing
end

# Area sampling: the mean of `supersample^D` point-sampled renderings, each on the voxel grid
# shifted by a sub-voxel offset. `render(offset)` returns the phantom with every voxel centre
# moved by `offset[d]` voxels along dimension `d`; the offsets are the centres of a regular
# `supersample^D` grid inside the voxel.
function render_supersampled(render, supersample::Integer, ::Val{D}) where {D}
    supersample >= 1 || throw(ArgumentError("supersample must be a positive integer, got $supersample"))
    supersample == 1 && return render(ntuple(_ -> 0.0, Val(D)))
    shifts = ((k - (supersample + 1) / 2) / supersample for k in 1:supersample)
    offsets = Iterators.product(ntuple(_ -> shifts, Val(D))...)
    acc = render(first(offsets))
    for offset in Iterators.drop(offsets, 1)
        acc .+= render(offset)
    end
    acc ./= supersample^D
    return acc
end

function check_supersample_eltype(supersample::Integer, is_mask::Bool)
    supersample == 1 || !is_mask ||
        throw(ArgumentError("supersample > 1 averages intensities and does not apply to a mask phantom"))
    return nothing
end
