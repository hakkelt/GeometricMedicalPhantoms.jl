
"""
    SuperEllipsoid

Struct to store the parameters of a superellipsoid.

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
struct SuperEllipsoid{T,T2}
    cx::T
    cy::T
    cz::T
    rx::T
    ry::T
    rz::T
    ex::NTuple{3,T}
    intensity::T2
end

# === Core drawing primitive ===
# Draw a superellipsoid defined by a SuperEllipsoid object
# onto phantom using normalized axes ax_x, ax_y, ax_z. Avoids creating 3D grids.
function draw_superellipsoid!(phantom::Array{Complex{T},3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                              se::SuperEllipsoid) where {T<:AbstractFloat}
    # Extract parameters from SuperEllipsoid struct
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    ex = se.ex
    intensity = se.intensity
    
    # Restrict computation to the enclosing axis-aligned box to avoid full-volume work
    @inline function idx_bounds(ax::AbstractVector, c::Real, r::Real)
        n = length(ax)
        # Handle both ascending and descending axes
        step = n > 1 ? (ax[2] - ax[1]) : 1.0
        i1 = 1 + ((c - r) - ax[1]) / step
        i2 = 1 + ((c + r) - ax[1]) / step
        i_min = clamp(Int(floor(min(i1, i2))), 1, n)
        i_max = clamp(Int(ceil(max(i1, i2))), 1, n)
        return i_min, i_max
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, rx)
    iy_min, iy_max = idx_bounds(ax_y, cy, ry)
    iz_min, iz_max = idx_bounds(ax_z, cz, rz)

    inv_rx = 1.0 / rx
    inv_ry = 1.0 / ry
    inv_rz = 1.0 / rz
    exx, exy, exz = ex
    val_int = T(intensity)

    @inbounds for i in ix_min:ix_max
        dx = abs(ax_x[i] - cx) * inv_rx
        dxp = dx^exx
        for j in iy_min:iy_max
            dy = abs(ax_y[j] - cy) * inv_ry
            dyp = dy^exy
            for k in iz_min:iz_max
                dz = abs(ax_z[k] - cz) * inv_rz
                dzp = dz^exz
                if dxp + dyp + dzp <= 1.0
                    phantom[i, j, k] = val_int
                end
            end
        end
    end
    return phantom
end
