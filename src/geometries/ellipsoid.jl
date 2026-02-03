
@doc raw"""
    Ellipsoid

Struct to store the parameters of an ellipsoid.

The points (x, y, z) inside the ellipsoid satisfy the equation:
    ``(\frac{|x - cx|}{rx})^2 + (\frac{|y - cy|}{ry})^2 + (\frac{|z - cz|}{rz})^2 \leq 1``

Fields:
- `cx::Real`: X-coordinate of the center
- `cy::Real`: Y-coordinate of the center
- `cz::Real`: Z-coordinate of the center
- `rx::Real`: Radius in x-direction
- `ry::Real`: Radius in y-direction
- `rz::Real`: Radius in z-direction
- `intensity::Real`: Intensity value for the ellipsoid
"""
struct Ellipsoid{T,T2} <: Shape
    cx::T
    cy::T
    cz::T
    rx::T
    ry::T
    rz::T
    intensity::T2
end

rotate_coronal(shape::Ellipsoid) = Ellipsoid(shape.cx, shape.cz, shape.cy, shape.rx, shape.rz, shape.ry, shape.intensity)
rotate_sagittal(shape::Ellipsoid) = Ellipsoid(shape.cy, shape.cz, shape.cx, shape.ry, shape.rz, shape.rx, shape.intensity)
    
# Draw a 3D ellipsoid defined by an Ellipsoid object
# onto phantom using normalized axes ax_x, ax_y, ax_z.
function draw!(phantom::AbstractArray{T,3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                              se::Ellipsoid) where T
    # Extract parameters from Ellipsoid struct
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    intensity = se.intensity

    ix_min, ix_max = idx_bounds(ax_x, cx, rx)
    iy_min, iy_max = idx_bounds(ax_y, cy, ry)
    iz_min, iz_max = idx_bounds(ax_z, cz, rz)
    
    # Check if ellipsoid is fully outside the canvas
    if ix_min == -1 || iy_min == -1 || iz_min == -1
        return
    end

    inv_rx = 1.0 / rx
    inv_ry = 1.0 / ry
    inv_rz = 1.0 / rz

    _dx = @. (ax_x[ix_min:ix_max] - cx) * inv_rx
    dx = _dx .* _dx
    _dy = @. (ax_y[iy_min:iy_max] - cy) * inv_ry
    dy = _dy .* _dy
    _dz = @. (ax_z[iz_min:iz_max] - cz) * inv_rz
    dz = _dz .* _dz
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

# Draw a 2D slice of an ellipsoid at a specific z-coordinate
# onto phantom using normalized axes ax_x, ax_y and a scalar ax_z.
function draw!(phantom::AbstractArray{T,2}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::Real,
                              se::Ellipsoid) where T
    # Extract parameters from Ellipsoid struct
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    intensity = se.intensity

    # Check if the slice is outside the ellipsoid's z-range
    if abs(ax_z - cz) > rz
        return
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, rx)
    iy_min, iy_max = idx_bounds(ax_y, cy, ry)
    
    # Check if ellipsoid is fully outside the canvas
    if ix_min == -1 || iy_min == -1
        return
    end

    inv_rx = 1.0 / rx
    inv_ry = 1.0 / ry
    inv_rz = 1.0 / rz
    
    # Precompute directions
    _dx = @. (ax_x[ix_min:ix_max] - cx) * inv_rx
    dx = _dx .* _dx
    _dy = @. (ax_y[iy_min:iy_max] - cy) * inv_ry
    dy = _dy .* _dy
    _dz = (ax_z - cz) * inv_rz
    dz = _dz * _dz
    @inbounds for i in ix_min:ix_max
        for j in iy_min:iy_max
            if dx[i - ix_min + 1] + dy[j - iy_min + 1] + dz <= 1.0
                draw_pixel!(phantom, intensity, i, j)
            end
        end
    end
end
