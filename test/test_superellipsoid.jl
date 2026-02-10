using Test
using GeometricMedicalPhantoms
using GeometricMedicalPhantoms: SuperEllipsoid, draw!

@testset "SuperEllipsoid Tests" begin
    @testset "3D draw! - superellipsoid outside canvas bounds" begin
        # Create a 3D phantom array
        phantom = zeros(Float32, 10, 10, 10)

        # Define axes for a small region
        ax_x = range(-1.0, 1.0, length = 10)
        ax_y = range(-1.0, 1.0, length = 10)
        ax_z = range(-1.0, 1.0, length = 10)

        # Create a superellipsoid that is completely outside the canvas bounds
        # Place it far away from the defined axes
        se_outside = SuperEllipsoid(
            10.0,  # cx - far right
            10.0,  # cy - far away
            10.0,  # cz - far up
            0.5,   # rx
            0.5,   # ry
            0.5,   # rz
            (2.0, 2.0, 2.0),  # ex
            1.0    # intensity
        )

        # Draw the superellipsoid (should return early without modifying phantom)
        draw!(phantom, ax_x, ax_y, ax_z, se_outside)

        # Verify that phantom remains all zeros (superellipsoid was outside bounds)
        @test all(phantom .== 0.0f0)

        # Test another case: superellipsoid on negative side
        se_outside_neg = SuperEllipsoid(
            -10.0,  # cx - far left
            -10.0,  # cy - far away
            -10.0,  # cz - far down
            0.5,    # rx
            0.5,    # ry
            0.5,    # rz
            (2.0, 2.0, 2.0),  # ex
            1.0     # intensity
        )

        phantom2 = zeros(Float32, 10, 10, 10)
        draw!(phantom2, ax_x, ax_y, ax_z, se_outside_neg)
        @test all(phantom2 .== 0.0f0)

        # Test case where superellipsoid is partially outside but ix_min > ix_max
        # This happens when the ellipsoid center is outside but radius doesn't reach canvas
        phantom3 = zeros(Float32, 10, 10, 10)
        se_edge = SuperEllipsoid(
            5.0,   # cx - outside but close
            5.0,   # cy - outside but close
            5.0,   # cz - outside but close
            0.1,   # rx - small radius, won't reach canvas
            0.1,   # ry - small radius
            0.1,   # rz - small radius
            (2.0, 2.0, 2.0),  # ex
            1.0    # intensity
        )
        draw!(phantom3, ax_x, ax_y, ax_z, se_edge)
        @test all(phantom3 .== 0.0f0)
    end

    @testset "2D draw! - superellipsoid outside canvas bounds" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 10, 10)

        # Define axes for a small region
        ax_x = range(-1.0, 1.0, length = 10)
        ax_y = range(-1.0, 1.0, length = 10)
        ax_z_val = 0.0  # Slice position

        # Create a superellipsoid that is completely outside the 2D canvas bounds
        # Place it far away from the defined axes in x-y plane
        se_outside = SuperEllipsoid(
            10.0,  # cx - far right
            10.0,  # cy - far away
            0.0,   # cz - at slice position
            0.5,   # rx
            0.5,   # ry
            0.5,   # rz
            (2.0, 2.0, 2.0),  # ex
            1.0    # intensity
        )

        # Draw the superellipsoid (should return early without modifying phantom)
        draw!(phantom, ax_x, ax_y, ax_z_val, se_outside)

        # Verify that phantom remains all zeros (superellipsoid was outside bounds)
        @test all(phantom .== 0.0f0)

        # Test another case: superellipsoid on negative side
        se_outside_neg = SuperEllipsoid(
            -10.0,  # cx - far left
            -10.0,  # cy - far away
            0.0,    # cz - at slice position
            0.5,    # rx
            0.5,    # ry
            0.5,    # rz
            (2.0, 2.0, 2.0),  # ex
            1.0     # intensity
        )

        phantom2 = zeros(Float32, 10, 10)
        draw!(phantom2, ax_x, ax_y, ax_z_val, se_outside_neg)
        @test all(phantom2 .== 0.0f0)

        # Test case where ix_min > ix_max or iy_min > iy_max
        phantom3 = zeros(Float32, 10, 10)
        se_edge = SuperEllipsoid(
            5.0,   # cx - outside but close
            5.0,   # cy - outside but close
            0.0,   # cz - at slice position
            0.1,   # rx - small radius, won't reach canvas
            0.1,   # ry - small radius
            0.5,   # rz
            (2.0, 2.0, 2.0),  # ex
            1.0    # intensity
        )
        draw!(phantom3, ax_x, ax_y, ax_z_val, se_edge)
        @test all(phantom3 .== 0.0f0)
    end
end
