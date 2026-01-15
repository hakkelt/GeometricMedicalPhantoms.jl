
@doc raw"""
    RotatedEllipsoid

Struct to store the parameters of a rotated ellipsoid.

The points (x, y, z) inside the ellipsoid satisfy the equation:
    ``(R^{-1} (P - C))^T D (R^{-1} (P - C)) \leq 1``
where R is the rotation matrix (Z-Y-X order), C is the center, and D is the diagonal matrix of inverse radii squared.

Fields:
- `cx, cy, cz::Real`: Center coordinates
- `rx, ry, rz::Real`: Radii
- `phi, theta, psi::Real`: Rotation angles in radians (Z-Y-X order)
- `intensity::Real`: Intensity value
"""
struct RotatedEllipsoid{T,T2} <: Shape
    cx::T
    cy::T
    cz::T
    rx::T
    ry::T
    rz::T
    phi::T
    theta::T
    psi::T
    intensity::T2
end

# Rotations for torso phantom (not strictly needed for Shepp-Logan but good for consistency)
rotate_coronal(s::RotatedEllipsoid) = RotatedEllipsoid(s.cx, s.cz, s.cy, s.rx, s.rz, s.ry, s.phi, s.psi, s.theta, s.intensity)
rotate_sagittal(s::RotatedEllipsoid) = RotatedEllipsoid(s.cy, s.cz, s.cx, s.ry, s.rz, s.rx, s.theta, s.psi, s.phi, s.intensity)

function get_rotation_matrix(phi, theta, psi)
    # R = Rz(phi) * Ry(theta) * Rx(psi)
    c1, s1 = cos(phi), sin(phi)
    c2, s2 = cos(theta), sin(theta)
    c3, s3 = cos(psi), sin(psi)

    # R matrix elements
    r11 = c1*c2
    r12 = c1*s2*s3 - s1*c3
    r13 = c1*s2*c3 + s1*s3
    r21 = s1*c2
    r22 = s1*s2*s3 + c1*c3
    r23 = s1*s2*c3 - c1*s3
    r31 = -s2
    r32 = c2*s3
    r33 = c2*c3

    return (r11, r12, r13, r21, r22, r23, r31, r32, r33)
end

function draw!(phantom::AbstractArray{T,3}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::AbstractVector,
                               se::RotatedEllipsoid) where T
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    phi, theta, psi = se.phi, se.theta, se.psi
    intensity = se.intensity

    # Compute bounding box using the property: rx_bbox = sqrt((R * D_inv * R^T)_11)
    # where D_inv = diag(rx^2, ry^2, rz^2)
    R = get_rotation_matrix(phi, theta, psi)
    r11, r12, r13, r21, r22, r23, r31, r32, r33 = R

    rx2, ry2, rz2 = rx^2, ry^2, rz^2
    
    # Bounding box radii
    brx = sqrt(r11^2 * rx2 + r12^2 * ry2 + r13^2 * rz2)
    bry = sqrt(r21^2 * rx2 + r22^2 * ry2 + r23^2 * rz2)
    brz = sqrt(r31^2 * rx2 + r32^2 * ry2 + r33^2 * rz2)

    ix_min, ix_max = idx_bounds(ax_x, cx, brx)
    iy_min, iy_max = idx_bounds(ax_y, cy, bry)
    iz_min, iz_max = idx_bounds(ax_z, cz, brz)
    
    if ix_min == -1 || iy_min == -1 || iz_min == -1
        return
    end

    inv_rx2 = 1.0 / rx2
    inv_ry2 = 1.0 / ry2
    inv_rz2 = 1.0 / rz2

    # Rotation matrix from global to local is R^T
    # P_local = R^T * (P_global - C)
    # x_loc = r11*(x-cx) + r21*(y-cy) + r31*(z-cz)
    # y_loc = r12*(x-cx) + r22*(y-cy) + r32*(z-cz)
    # z_loc = r13*(x-cx) + r23*(y-cy) + r33*(z-cz)

    @inbounds for k in iz_min:iz_max
        dz = ax_z[k] - cz
        # Precompute terms depending only on z
        t1z = r31 * dz
        t2z = r32 * dz
        t3z = r33 * dz
        for j in iy_min:iy_max
            dy = ax_y[j] - cy
            # Precompute terms depending on y and z
            t1yz = r21 * dy + t1z
            t2yz = r22 * dy + t2z
            t3yz = r23 * dy + t3z
            for i in ix_min:ix_max
                dx = ax_x[i] - cx
                
                x_loc = r11 * dx + t1yz
                y_loc = r12 * dx + t2yz
                z_loc = r13 * dx + t3yz

                if (x_loc^2 * inv_rx2 + y_loc^2 * inv_ry2 + z_loc^2 * inv_rz2) <= 1.0
                    draw_pixel!(phantom, intensity, i, j, k)
                end
            end
        end
    end
end

function draw!(phantom::AbstractArray{T,2}, ax_x::AbstractVector, ax_y::AbstractVector, ax_z::Real,
                               se::RotatedEllipsoid) where T
    cx, cy, cz = se.cx, se.cy, se.cz
    rx, ry, rz = se.rx, se.ry, se.rz
    phi, theta, psi = se.phi, se.theta, se.psi
    intensity = se.intensity

    R = get_rotation_matrix(phi, theta, psi)
    r11, r12, r13, r21, r22, r23, r31, r32, r33 = R
    rx2, ry2, rz2 = rx^2, ry^2, rz^2
    
    brx = sqrt(r11^2 * rx2 + r12^2 * ry2 + r13^2 * rz2)
    bry = sqrt(r21^2 * rx2 + r22^2 * ry2 + r23^2 * rz2)
    brz = sqrt(r31^2 * rx2 + r32^2 * ry2 + r33^2 * rz2)

    if abs(ax_z - cz) > brz
        return
    end

    ix_min, ix_max = idx_bounds(ax_x, cx, brx)
    iy_min, iy_max = idx_bounds(ax_y, cy, bry)

    if ix_min == -1 || iy_min == -1
        return
    end

    inv_rx2 = 1.0 / rx2
    inv_ry2 = 1.0 / ry2
    inv_rz2 = 1.0 / rz2

    dz = ax_z - cz
    t1z = r31 * dz
    t2z = r32 * dz
    t3z = r33 * dz

    @inbounds for j in iy_min:iy_max
        dy = ax_y[j] - cy
        t1yz = r21 * dy + t1z
        t2yz = r22 * dy + t2z
        t3yz = r23 * dy + t3z
        for i in ix_min:ix_max
            dx = ax_x[i] - cx
            
            x_loc = r11 * dx + t1yz
            y_loc = r12 * dx + t2yz
            z_loc = r13 * dx + t3yz

            if (x_loc^2 * inv_rx2 + y_loc^2 * inv_ry2 + z_loc^2 * inv_rz2) <= 1.0
                draw_pixel!(phantom, intensity, i, j)
            end
        end
    end
end
