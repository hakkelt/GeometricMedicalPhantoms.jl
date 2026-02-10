using Test
using GeometricMedicalPhantoms
using LinearAlgebra

# Import the internal types for testing
const RotatedEllipsoid = GeometricMedicalPhantoms.RotatedEllipsoid
const MaskingIntensityValue = GeometricMedicalPhantoms.MaskingIntensityValue

"""
    test_slice_for_ellipse(slice, ax_x, ax_y, cx, cy, rx, ry, R_2d, intensity)

Check that every pixel in a 2D slice matches the expected ellipse geometry.
Uses the rotation matrix R_2d (2×2) to account for in-plane rotation.
Allows small tolerance at boundaries due to discretization.
"""
function test_slice_for_ellipse(slice, ax_x, ax_y, cx, cy, rx, ry, R_2d, intensity; boundary_tol = 0.05)
    nx, ny = size(slice)

    for i in 1:nx
        for j in 1:ny
            # Get exact coordinates
            x = ax_x[i]
            y = ax_y[j]

            # Transform to ellipse coordinate system
            dx = x - cx
            dy = y - cy

            # Apply inverse rotation (R' = R^-1 for rotation matrices)
            dx_rot = R_2d[1, 1] * dx + R_2d[2, 1] * dy
            dy_rot = R_2d[1, 2] * dx + R_2d[2, 2] * dy

            # Check distance from ellipse center in normalized coordinates
            dist_normalized = (dx_rot / rx)^2 + (dy_rot / ry)^2
            is_inside = dist_normalized <= 1.0
            is_near_boundary = abs(dist_normalized - 1.0) < boundary_tol

            # Verify pixel value
            val = slice[i, j]

            if is_inside && !is_near_boundary
                # Deep inside ellipse - must be filled
                if val == 0
                    return "Error at ($i, $j): Deep inside ellipse (dist²=$dist_normalized) but pixel empty"
                elseif !isapprox(val, intensity, atol = 1.0e-6)
                    return "Error at ($i, $j): Wrong intensity (got $val, expected $intensity)"
                end
            elseif !is_inside && !is_near_boundary
                # Far outside ellipse - must be empty
                if val != 0
                    return "Error at ($i, $j): Outside ellipse (dist²=$dist_normalized) but pixel filled (val=$val)"
                end
            end
            # Near boundary - allow either filled or empty due to discretization
        end
    end
    return "ok"
end

@testset "RotatedEllipsoid Tests" begin

    @testset "get_rotation_matrix - invalid plane (line 76)" begin
        @test_throws ErrorException GeometricMedicalPhantoms.get_rotation_matrix(0.0, 0.0, 0.0, :invalid_plane)
    end

    @testset "get_rotation_matrix - Z-Y-X Euler angles" begin
        # Test rotation matrices against analytical formulas
        # Z-Y-X Euler convention: R = Rz(phi) * Ry(theta) * Rx(psi)

        phi, theta, psi = 0.3, 0.5, 0.7

        # Compute individual rotation matrices
        cphi, sphi = cos(phi), sin(phi)
        ctheta, stheta = cos(theta), sin(theta)
        cpsi, spsi = cos(psi), sin(psi)

        # Individual rotation matrices for Z-Y-X convention
        Rz = [cphi -sphi 0; sphi cphi 0; 0 0 1]
        Ry = [ctheta 0 stheta; 0 1 0; -stheta 0 ctheta]
        Rx = [1 0 0; 0 cpsi -spsi; 0 spsi cpsi]

        # Combined rotation: Rz(phi) * Ry(theta) * Rx(psi)
        R_expected = Rz * Ry * Rx

        # Test axial plane (standard orientation)
        R_axial = GeometricMedicalPhantoms.get_rotation_matrix(phi, theta, psi, :axial)
        R_axial_matrix = reshape(collect(R_axial), 3, 3)'
        @test R_axial_matrix ≈ R_expected atol = 1.0e-10

        # Test coronal plane (permutation: [1, 3, 2] → swap y and z)
        R_coronal = GeometricMedicalPhantoms.get_rotation_matrix(phi, theta, psi, :coronal)
        R_coronal_matrix = reshape(collect(R_coronal), 3, 3)'
        R_expected_coronal = R_expected[[1, 3, 2], :]
        @test R_coronal_matrix ≈ R_expected_coronal atol = 1.0e-10

        # Test sagittal plane (permutation: [2, 3, 1] → x→z, y→x, z→y)
        R_sagittal = GeometricMedicalPhantoms.get_rotation_matrix(phi, theta, psi, :sagittal)
        R_sagittal_matrix = reshape(collect(R_sagittal), 3, 3)'
        R_expected_sagittal = R_expected[[2, 3, 1], :]
        @test R_sagittal_matrix ≈ R_expected_sagittal atol = 1.0e-10
    end

    @testset "get_rotation_matrix - identity rotation" begin
        # Zero angles should give identity matrix
        R_identity = GeometricMedicalPhantoms.get_rotation_matrix(0.0, 0.0, 0.0, :axial)
        R_identity_matrix = reshape(collect(R_identity), 3, 3)'
        @test R_identity_matrix ≈ I(3) atol = 1.0e-10
    end

    @testset "3D draw - unrotated ellipsoid center slice" begin
        nx, ny, nz = 32, 32, 32
        phantom = zeros(Float32, nx, ny, nz)
        ax_x = collect(range(-1.0, 1.0, length = nx))
        ax_y = collect(range(-1.0, 1.0, length = ny))
        ax_z = collect(range(-1.0, 1.0, length = nz))

        # Draw an unrotated ellipsoid
        rx, ry, rz = 0.5, 0.3, 0.2
        ellipsoid = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, rz, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax_x, ax_y, ax_z, ellipsoid)

        # Check center slice using helper function (no rotation → identity matrix)
        mid = div(nz, 2) + 1
        @test test_slice_for_ellipse(phantom[:, :, mid], ax_x, ax_y, 0.0, 0.0, rx, ry, I(2), 1.0) == "ok"
    end

    @testset "3D draw - out of bounds (line 104)" begin
        nx, ny, nz = 32, 32, 32
        phantom = zeros(Float32, nx, ny, nz)
        ax_x = collect(range(-1.0, 1.0, length = nx))
        ax_y = collect(range(-1.0, 1.0, length = ny))
        ax_z = collect(range(-1.0, 1.0, length = nz))

        # Ellipsoid completely outside bounds (triggers line 104)
        ellipsoid_outside = RotatedEllipsoid(10.0, 10.0, 10.0, 0.5, 0.3, 0.2, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax_x, ax_y, ax_z, ellipsoid_outside)

        @test all(phantom .== 0)
    end

    @testset "3D draw - rotated ellipsoid center slice" begin
        nx, ny, nz = 64, 64, 64
        phantom = zeros(Float32, nx, ny, nz)
        ax_x = collect(range(-1.0, 1.0, length = nx))
        ax_y = collect(range(-1.0, 1.0, length = ny))
        ax_z = collect(range(-1.0, 1.0, length = nz))

        # Draw a rotated ellipsoid (phi rotation only - around z-axis)
        phi = π / 4
        rx, ry, rz = 0.5, 0.3, 0.2
        ellipsoid = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, rz, phi, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax_x, ax_y, ax_z, ellipsoid)

        # For phi rotation only (around z), the x-y plane rotates
        mid = div(nz, 2) + 1
        R_2d = [cos(phi) -sin(phi); sin(phi) cos(phi)]
        @test test_slice_for_ellipse(phantom[:, :, mid], ax_x, ax_y, 0.0, 0.0, rx, ry, R_2d, 1.0) == "ok"
    end

    @testset "3D draw - different plane orientations" begin
        nx, ny, nz = 32, 32, 32
        ax = collect(range(-1.0, 1.0, length = 32))
        rx, ry, rz = 0.5, 0.3, 0.2

        # Axial: z-axis is "up", ellipsoid unrotated
        phantom_axial = zeros(Float32, nx, ny, nz)
        ellipsoid_axial = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, rz, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0), :axial)
        GeometricMedicalPhantoms.draw!(phantom_axial, ax, ax, ax, ellipsoid_axial)
        mid = div(nz, 2) + 1
        @test test_slice_for_ellipse(phantom_axial[:, :, mid], ax, ax, 0.0, 0.0, rx, ry, I(2), 1.0) == "ok"

        # Coronal and sagittal just verify non-zero volume
        phantom_coronal = zeros(Float32, nx, ny, nz)
        ellipsoid_coronal = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, rz, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0), :coronal)
        GeometricMedicalPhantoms.draw!(phantom_coronal, ax, ax, ax, ellipsoid_coronal)
        @test sum(phantom_coronal .> 0) > 0

        phantom_sagittal = zeros(Float32, nx, ny, nz)
        ellipsoid_sagittal = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, rz, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0), :sagittal)
        GeometricMedicalPhantoms.draw!(phantom_sagittal, ax, ax, ax, ellipsoid_sagittal)
        @test sum(phantom_sagittal .> 0) > 0
    end

    @testset "2D draw - unrotated ellipse" begin
        nx, ny = 64, 64
        phantom = zeros(Float32, nx, ny)
        ax_x = collect(range(-1.0, 1.0, length = nx))
        ax_y = collect(range(-1.0, 1.0, length = ny))

        rx, ry = 0.5, 0.3
        ellipsoid = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, 0.2, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax_x, ax_y, 0.0, ellipsoid)

        @test test_slice_for_ellipse(phantom, ax_x, ax_y, 0.0, 0.0, rx, ry, I(2), 1.0) == "ok"
    end

    @testset "2D draw - slice outside ellipsoid (line 160)" begin
        nx, ny = 64, 64
        phantom = zeros(Float32, nx, ny)
        ax_x = collect(range(-1.0, 1.0, length = nx))
        ax_y = collect(range(-1.0, 1.0, length = ny))

        # Draw at z position far outside the ellipsoid (triggers line 160)
        ellipsoid = RotatedEllipsoid(0.0, 0.0, 0.0, 0.5, 0.3, 0.2, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax_x, ax_y, 10.0, ellipsoid)

        @test all(phantom .== 0)
    end

    @testset "2D draw - offset slice positions" begin
        nx, ny = 64, 64
        ax = collect(range(-1.0, 1.0, length = 64))

        rx, ry, rz = 0.5, 0.3, 0.2
        ellipsoid = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, rz, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0))

        # Center slice
        phantom_center = zeros(Float32, nx, ny)
        GeometricMedicalPhantoms.draw!(phantom_center, ax, ax, 0.0, ellipsoid)
        @test test_slice_for_ellipse(phantom_center, ax, ax, 0.0, 0.0, rx, ry, I(2), 1.0) == "ok"

        # Off-center slice (smaller ellipse)
        phantom_offset = zeros(Float32, nx, ny)
        z_offset = 0.1
        GeometricMedicalPhantoms.draw!(phantom_offset, ax, ax, z_offset, ellipsoid)
        # Compute effective radii at this z position
        scale = sqrt(1 - (z_offset / rz)^2)
        @test test_slice_for_ellipse(phantom_offset, ax, ax, 0.0, 0.0, rx * scale, ry * scale, I(2), 1.0) == "ok"
    end

    @testset "2D draw - rotated ellipse (phi only)" begin
        nx, ny = 64, 64
        phantom = zeros(Float32, nx, ny)
        ax = collect(range(-1.0, 1.0, length = 64))

        # Rotate only around z-axis (phi)
        phi = π / 6
        rx, ry = 0.5, 0.3
        ellipsoid = RotatedEllipsoid(0.0, 0.0, 0.0, rx, ry, 0.2, phi, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax, ax, 0.0, ellipsoid)

        R_2d = [cos(phi) -sin(phi); sin(phi) cos(phi)]
        @test test_slice_for_ellipse(phantom, ax, ax, 0.0, 0.0, rx, ry, R_2d, 1.0) == "ok"
    end

    @testset "2D draw - out of x-y bounds" begin
        nx, ny = 32, 32
        phantom = zeros(Float32, nx, ny)
        ax_x = collect(range(-0.5, 0.5, length = nx))
        ax_y = collect(range(-0.5, 0.5, length = ny))

        # Ellipsoid with center outside x-y bounds
        ellipsoid = RotatedEllipsoid(5.0, 5.0, 0.0, 0.5, 0.3, 0.2, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0))
        GeometricMedicalPhantoms.draw!(phantom, ax_x, ax_y, 0.0, ellipsoid)

        @test all(phantom .== 0)
    end

    @testset "Different intensity values" begin
        nx, ny = 32, 32
        ax = collect(range(-1.0, 1.0, length = 32))

        # Test with intensity 0.5
        phantom1 = zeros(Float32, nx, ny)
        ellipsoid1 = RotatedEllipsoid(0.0, 0.0, 0.0, 0.4, 0.3, 0.2, 0.0, 0.0, 0.0, MaskingIntensityValue(0.5))
        GeometricMedicalPhantoms.draw!(phantom1, ax, ax, 0.0, ellipsoid1)
        @test test_slice_for_ellipse(phantom1, ax, ax, 0.0, 0.0, 0.4, 0.3, I(2), 0.5) == "ok"

        # Test with complex intensity
        phantom2 = zeros(ComplexF32, nx, ny)
        ellipsoid2 = RotatedEllipsoid(0.0, 0.0, 0.0, 0.4, 0.3, 0.2, 0.0, 0.0, 0.0, MaskingIntensityValue(1.0 + 0.5im))
        GeometricMedicalPhantoms.draw!(phantom2, ax, ax, 0.0, ellipsoid2)
        @test sum(abs.(phantom2) .> 0) > 0
        @test maximum(real(phantom2)) ≈ 1.0f0
        @test maximum(imag(phantom2)) ≈ 0.5f0
    end

end
