
@doc raw"""
    CylinderZ

Struct to store the parameters of a cylinder aligned along the z-axis.

A cylinder is defined by its center (cx, cy, cz), radius, and height. The cylinder is aligned
along the z-axis and extends from cz - height/2 to cz + height/2.

The points (x, y, z) inside the cylinder satisfy the inequalities:
    ``\sqrt{(x - cx)^2 + (y - cy)^2} \leq r`` and ``|z - cz| \leq \text{height}/2``

Fields:
- `cx::Real`: X-coordinate of the center
- `cy::Real`: Y-coordinate of the center
- `cz::Real`: Z-coordinate of the center
- `r::Real`: Radius of the cylinder
- `height::Real`: Height of the cylinder along the z-axis
- `intensity::Real`: Intensity value for the cylinder
"""
struct CylinderZ{T,T2} <: Shape
    cx::T
    cy::T
    cz::T
    r::T
    height::T
    intensity::T2
end

@doc raw"""
    CylinderY

Struct to store the parameters of a cylinder aligned along the y-axis.

A cylinder is defined by its center (cx, cy, cz), radius, and height. The cylinder is aligned
along the y-axis and extends from cy - height/2 to cy + height/2.

The points (x, y, z) inside the cylinder satisfy the inequalities:
    ``\sqrt{(x - cx)^2 + (z - cz)^2} \leq r`` and ``|y - cy| \leq \text{height}/2``

Fields:
- `cx::Real`: X-coordinate of the center
- `cy::Real`: Y-coordinate of the center
- `cz::Real`: Z-coordinate of the center
- `r::Real`: Radius of the cylinder
- `height::Real`: Height of the cylinder along the y-axis
- `intensity::Real`: Intensity value for the cylinder
"""
struct CylinderY{T,T2} <: Shape
    cx::T
    cy::T
    cz::T
    r::T
    height::T
    intensity::T2
end

@doc raw"""
    CylinderX

Struct to store the parameters of a cylinder aligned along the x-axis.

A cylinder is defined by its center (cx, cy, cz), radius, and height. The cylinder is aligned
along the x-axis and extends from cx - height/2 to cx + height/2.

The points (x, y, z) inside the cylinder satisfy the inequalities:
    ``\sqrt{(y - cy)^2 + (z - cz)^2} \leq r`` and ``|x - cx| \leq \text{height}/2``

Fields:
- `cx::Real`: X-coordinate of the center
- `cy::Real`: Y-coordinate of the center
- `cz::Real`: Z-coordinate of the center
- `r::Real`: Radius of the cylinder
- `height::Real`: Height of the cylinder along the x-axis
- `intensity::Real`: Intensity value for the cylinder
"""
struct CylinderX{T,T2} <: Shape
    cx::T
    cy::T
    cz::T
    r::T
    height::T
    intensity::T2
end

# Alias for backward compatibility
const Cylinder = CylinderZ

# Rotation functions for CylinderZ
rotate_coronal(shape::CylinderZ) = CylinderY(shape.cx, shape.cz, shape.cy, shape.r, shape.height, shape.intensity)
rotate_sagittal(shape::CylinderZ) = CylinderX(shape.cy, shape.cz, shape.cx, shape.r, shape.height, shape.intensity)

# Rotation functions for CylinderY
rotate_coronal(shape::CylinderY) = CylinderZ(shape.cx, shape.cz, shape.cy, shape.r, shape.height, shape.intensity)
rotate_sagittal(shape::CylinderY) = CylinderX(shape.cz, shape.cy, shape.cx, shape.r, shape.height, shape.intensity)

# Rotation functions for CylinderX
rotate_coronal(shape::CylinderX) = CylinderX(shape.cx, shape.cz, shape.cy, shape.r, shape.height, shape.intensity)
rotate_sagittal(shape::CylinderX) = CylinderY(shape.cz, shape.cy, shape.cx, shape.r, shape.height, shape.intensity)

# Draw a 3D cylinder (Z-aligned) defined by a CylinderZ object
# onto phantom using normalized axes ax_x, ax_y, ax_z.
function draw!(phantom::AbstractArray{T,3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                              cylinder::CylinderZ) where T
    # Extract parameters from CylinderZ struct
    cx, cy, cz = cylinder.cx, cylinder.cy, cylinder.cz
    r = cylinder.r
    height = cylinder.height
    intensity = MaskingIntensityValue(cylinder.intensity)

    # Compute bounding box for the cylinder
    ix_min, ix_max = idx_bounds(ax_x, cx, r)
    iy_min, iy_max = idx_bounds(ax_y, cy, r)
    iz_min, iz_max = idx_bounds(ax_z, cz, height / 2)
    
    # Check if cylinder is fully outside the canvas
    if ix_min == -1 || iy_min == -1 || iz_min == -1
        return
    end

    inv_r_sq = 1.0 / (r * r)
    half_height = height / 2

    # Precompute x and y distances for efficiency
    _dx = @. (ax_x[ix_min:ix_max] - cx)
    dx = _dx .* _dx .* inv_r_sq
    _dy = @. (ax_y[iy_min:iy_max] - cy)
    dy = _dy .* _dy .* inv_r_sq
    
    @inbounds for i in ix_min:ix_max
        for j in iy_min:iy_max
            r_sq = dx[i - ix_min + 1] + dy[j - iy_min + 1]
            if r_sq <= 1.0  # Within radius
                for k in iz_min:iz_max
                    if abs(ax_z[k] - cz) <= half_height  # Within height bounds
                        draw_pixel!(phantom, intensity, i, j, k)
                    end
                end
            end
        end
    end
end

# Draw a 3D cylinder (Y-aligned) defined by a CylinderY object
# onto phantom using normalized axes ax_x, ax_y, ax_z.
function draw!(phantom::AbstractArray{T,3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                              cylinder::CylinderY) where T
    # Extract parameters from CylinderY struct
    cx, cy, cz = cylinder.cx, cylinder.cy, cylinder.cz
    r = cylinder.r
    height = cylinder.height
    intensity = MaskingIntensityValue(cylinder.intensity)

    # Compute bounding box for the cylinder
    ix_min, ix_max = idx_bounds(ax_x, cx, r)
    iy_min, iy_max = idx_bounds(ax_y, cy, height / 2)
    iz_min, iz_max = idx_bounds(ax_z, cz, r)
    
    # Check if cylinder is fully outside the canvas
    if ix_min == -1 || iy_min == -1 || iz_min == -1
        return
    end

    inv_r_sq = 1.0 / (r * r)
    half_height = height / 2

    # Precompute x and z distances for efficiency
    _dx = @. (ax_x[ix_min:ix_max] - cx)
    dx = _dx .* _dx .* inv_r_sq
    _dz = @. (ax_z[iz_min:iz_max] - cz)
    dz = _dz .* _dz .* inv_r_sq
    
    @inbounds for i in ix_min:ix_max
        for k in iz_min:iz_max
            r_sq = dx[i - ix_min + 1] + dz[k - iz_min + 1]
            if r_sq <= 1.0  # Within radius
                for j in iy_min:iy_max
                    if abs(ax_y[j] - cy) <= half_height  # Within height bounds
                        draw_pixel!(phantom, intensity, i, j, k)
                    end
                end
            end
        end
    end
end

# Draw a 3D cylinder (X-aligned) defined by a CylinderX object
# onto phantom using normalized axes ax_x, ax_y, ax_z.
function draw!(phantom::AbstractArray{T,3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                              cylinder::CylinderX) where T
    # Extract parameters from CylinderX struct
    cx, cy, cz = cylinder.cx, cylinder.cy, cylinder.cz
    r = cylinder.r
    height = cylinder.height
    intensity = MaskingIntensityValue(cylinder.intensity)

    # Compute bounding box for the cylinder
    ix_min, ix_max = idx_bounds(ax_x, cx, height / 2)
    iy_min, iy_max = idx_bounds(ax_y, cy, r)
    iz_min, iz_max = idx_bounds(ax_z, cz, r)
    
    # Check if cylinder is fully outside the canvas
    if ix_min == -1 || iy_min == -1 || iz_min == -1
        return
    end

    inv_r_sq = 1.0 / (r * r)
    half_height = height / 2

    # Precompute y and z distances for efficiency
    _dy = @. (ax_y[iy_min:iy_max] - cy)
    dy = _dy .* _dy .* inv_r_sq
    _dz = @. (ax_z[iz_min:iz_max] - cz)
    dz = _dz .* _dz .* inv_r_sq
    
    @inbounds for j in iy_min:iy_max
        for k in iz_min:iz_max
            r_sq = dy[j - iy_min + 1] + dz[k - iz_min + 1]
            if r_sq <= 1.0  # Within radius
                for i in ix_min:ix_max
                    if abs(ax_x[i] - cx) <= half_height  # Within height bounds
                        draw_pixel!(phantom, intensity, i, j, k)
                    end
                end
            end
        end
    end
end

# Draw a 2D slice of a CylinderZ at a specific z-coordinate
# onto phantom using normalized axes ax_x, ax_y and a scalar ax_z.
function draw!(phantom::AbstractArray{T,2}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::Real,
                              cylinder::CylinderZ) where T
    # Extract parameters from CylinderZ struct
    cx, cy, cz = cylinder.cx, cylinder.cy, cylinder.cz
    r = cylinder.r
    height = cylinder.height
    intensity = MaskingIntensityValue(cylinder.intensity)

    # Check if the slice is outside the cylinder's height bounds
    if abs(ax_z - cz) > height / 2
        return
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, r)
    iy_min, iy_max = idx_bounds(ax_y, cy, r)
    
    # Check if cylinder is fully outside the canvas
    if ix_min == -1 || iy_min == -1
        return
    end

    inv_r_sq = 1.0 / (r * r)
    
    # Precompute x and y distances for efficiency
    _dx = @. (ax_x[ix_min:ix_max] - cx)
    dx = _dx .* _dx .* inv_r_sq
    _dy = @. (ax_y[iy_min:iy_max] - cy)
    dy = _dy .* _dy .* inv_r_sq
    
    @inbounds for i in ix_min:ix_max
        for j in iy_min:iy_max
            r_sq = dx[i - ix_min + 1] + dy[j - iy_min + 1]
            if r_sq <= 1.0  # Within radius
                draw_pixel!(phantom, intensity, i, j)
            end
        end
    end
end

# Draw a 2D slice of a CylinderY at a specific z-coordinate
# onto phantom using normalized axes ax_x, ax_y and a scalar ax_z.
# CylinderY has height along y, so at constant z, we draw a rectangle in x-y plane.
function draw!(phantom::AbstractArray{T,2}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::Real,
                              cylinder::CylinderY) where T
    # Extract parameters from CylinderY struct
    cx, cy, cz = cylinder.cx, cylinder.cy, cylinder.cz
    r = cylinder.r
    height = cylinder.height
    intensity = MaskingIntensityValue(cylinder.intensity)

    # Check if the slice is within the cylinder's z bounds
    dist_from_cz = abs(ax_z - cz)
    if dist_from_cz > r
        return
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, r)
    iy_min, iy_max = idx_bounds(ax_y, cy, height / 2)
    
    # Check if cylinder is fully outside the canvas
    if ix_min == -1 || iy_min == -1
        return
    end

    inv_r_sq = 1.0 / (r * r)
    
    # For CylinderY at constant z, we need to check if z is within the radial bounds
    # Precompute x and z distances for efficiency
    _dx = @. (ax_x[ix_min:ix_max] - cx)
    dx = _dx .* _dx .* inv_r_sq
    z_contrib = dist_from_cz * dist_from_cz * inv_r_sq
    
    @inbounds for i in ix_min:ix_max
        r_sq = dx[i - ix_min + 1] + z_contrib
        if r_sq <= 1.0  # Within radius in x-z plane
            for j in iy_min:iy_max
                if abs(ax_y[j] - cy) <= height / 2  # Within height bounds in y
                    draw_pixel!(phantom, intensity, i, j)
                end
            end
        end
    end
end

# Draw a 2D slice of a CylinderX at a specific z-coordinate
# onto phantom using normalized axes ax_x, ax_y and a scalar ax_z.
# CylinderX has height along x, so at constant z, we draw a rectangle in x-y plane.
function draw!(phantom::AbstractArray{T,2}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::Real,
                              cylinder::CylinderX) where T
    # Extract parameters from CylinderX struct
    cx, cy, cz = cylinder.cx, cylinder.cy, cylinder.cz
    r = cylinder.r
    height = cylinder.height
    intensity = MaskingIntensityValue(cylinder.intensity)

    # Check if the slice is within the cylinder's z bounds
    dist_from_cz = abs(ax_z - cz)
    if dist_from_cz > r
        return
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, height / 2)
    iy_min, iy_max = idx_bounds(ax_y, cy, r)
    
    # Check if cylinder is fully outside the canvas
    if ix_min == -1 || iy_min == -1
        return
    end

    inv_r_sq = 1.0 / (r * r)
    
    # For CylinderX at constant z, we need to check if z is within the radial bounds
    # Precompute y and z distances for efficiency
    _dy = @. (ax_y[iy_min:iy_max] - cy)
    dy = _dy .* _dy .* inv_r_sq
    z_contrib = dist_from_cz * dist_from_cz * inv_r_sq
    
    @inbounds for j in iy_min:iy_max
        r_sq = dy[j - iy_min + 1] + z_contrib
        if r_sq <= 1.0  # Within radius in y-z plane
            for i in ix_min:ix_max
                if abs(ax_x[i] - cx) <= height / 2  # Within height bounds in x
                    draw_pixel!(phantom, intensity, i, j)
                end
            end
        end
    end
end
