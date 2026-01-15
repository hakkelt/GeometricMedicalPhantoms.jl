
@doc raw"""
    SuperEllipsoid

Struct to store the parameters of a superellipsoid.

The points (x, y, z) inside the superellipsoid satisfy the equation:

    ``(\frac{|x - cx|}{rx})^{ex[1]} + (\frac{|y - cy|}{ry})^{ex[2]} + (\frac{|z - cz|}{rz})^{ex[3]} \leq 1``

Fields:
- `cx::Real`: X-coordinate of the center
- `cy::Real`: Y-coordinate of the center
- `cz::Real`: Z-coordinate of the center
- `rx::Real`: Radius in x-direction
- `ry::Real`: Radius in y-direction
- `rz::Real`: Radius in z-direction
- `ex::NTuple{3,Real}`: Exponents for (x, y, z) directions
- `intensity::Real`: Intensity value for the superellipsoid
"""
struct SuperEllipsoid{T,T2} <: Shape
    cx::T
    cy::T
    cz::T
    rx::T
    ry::T
    rz::T
    ex::NTuple{3,T}
    intensity::T2
end

rotate_coronal(shape::SuperEllipsoid) = SuperEllipsoid(shape.cx, shape.cz, shape.cy, shape.rx, shape.rz, shape.ry, (shape.ex[1], shape.ex[3], shape.ex[2]), shape.intensity)
rotate_sagittal(shape::SuperEllipsoid) = SuperEllipsoid(shape.cy, shape.cz, shape.cx, shape.ry, shape.rz, shape.rx, (shape.ex[2], shape.ex[3], shape.ex[1]), shape.intensity)

# Draw a 3D superellipsoid defined by a SuperEllipsoid object
# onto phantom using normalized axes ax_x, ax_y, ax_z.
function draw!(phantom::AbstractArray{T,3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                              se::SuperEllipsoid) where T
    # Extract parameters from SuperEllipsoid struct
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    ex = se.ex
    intensity = se.intensity

    ix_min, ix_max = idx_bounds(ax_x, cx, rx)
    iy_min, iy_max = idx_bounds(ax_y, cy, ry)
    iz_min, iz_max = idx_bounds(ax_z, cz, rz)
    
    # Check if superellipsoid is fully outside the canvas
    if ix_min == -1 || iy_min == -1 || iz_min == -1
        return
    end

    inv_rx = 1.0 / rx
    inv_ry = 1.0 / ry
    inv_rz = 1.0 / rz
    exx, exy, exz = ex

    dx = @. (abs(ax_x[ix_min:ix_max] - cx) * inv_rx)^exx
    dy = @. (abs(ax_y[iy_min:iy_max] - cy) * inv_ry)^exy
    dz = @. (abs(ax_z[iz_min:iz_max] - cz) * inv_rz)^exz
    @inbounds for i in ix_min:ix_max
        for j in iy_min:iy_max
            for k in iz_min:iz_max
                if dx[i - ix_min + 1] + dy[j - iy_min + 1] + dz[k - iz_min + 1] <= 1.0
                    draw_pixel!(phantom, intensity, i, j, k)
                end
            end
        end
    end
end

# Draw a 2D slice of a superellipsoid at a specific z-coordinate
# onto phantom using normalized axes ax_x, ax_y and a scalar ax_z.
function draw!(phantom::AbstractArray{T,2}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::Real,
                              se::SuperEllipsoid) where T
    # Extract parameters from SuperEllipsoid struct
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    ex = se.ex
    intensity = se.intensity

    # Check if the slice is outside the superellipsoid's z-range
    if abs(ax_z - cz) > rz
        return
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, rx)
    iy_min, iy_max = idx_bounds(ax_y, cy, ry)
    
    # Check if superellipsoid is fully outside the canvas
    if ix_min == -1 || iy_min == -1
        return
    end

    inv_rx = 1.0 / rx
    inv_ry = 1.0 / ry
    inv_rz = 1.0 / rz
    exx, exy, exz = ex
    
    # Precompute directions
    dx = @. (abs(ax_x[ix_min:ix_max] - cx) * inv_rx)^exx
    dy = @. (abs(ax_y[iy_min:iy_max] - cy) * inv_ry)^exy
    dz = (abs(ax_z - cz) * inv_rz)^exz
    @inbounds for i in ix_min:ix_max
        for j in iy_min:iy_max
            if dx[i - ix_min + 1] + dy[j - iy_min + 1] + dz <= 1.0
                draw_pixel!(phantom, intensity, i, j)
            end
        end
    end
end
