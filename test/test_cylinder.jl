using Test
using GeometricMedicalPhantoms
using GeometricMedicalPhantoms: Cylinder, CylinderZ, CylinderX, CylinderY, draw!

function test_slice_for_circle(slice, ax_x, ax_y, cx, cy, r, intensity)
    nx, ny = size(slice)

    # Iterate through every pixel
    for i in 1:nx
        for j in 1:ny
            # 1. GET EXACT COORDINATES
            # Use the actual axis values used during drawing
            x = ax_x[i]
            y = ax_y[j]

            # 2. CHECK GEOMETRY
            # Use squared distance to avoid sqrt precision issues
            # We use a tiny epsilon for float comparison safety at the edge,
            # though <= r^2 is usually fine.
            dist_sq = (x - cx)^2 + (y - cy)^2
            is_inside = dist_sq <= r^2

            # 3. VERIFY PIXEL VALUE
            # Note: access slice[i, j] to match draw! logic (x=row, y=col)
            val = slice[i, j]

            if is_inside
                if val == 0
                    return "Error at indices ($i, $j): Coords ($x, $y) are INSIDE (d^2=$dist_sq <= $r^2), but pixel is empty."
                elseif !(val ≈ intensity)
                    return "Error at indices ($i, $j): Wrong intensity."
                end
            else
                if val != 0
                    return "Error at indices ($i, $j): Coords ($x, $y) are OUTSIDE (d^2=$dist_sq > $r^2), but pixel is filled."
                end
            end
        end
    end
    return "ok"
end

function test_slice_for_rectangle(slice, ax_x, ax_y, cx, cy, width, height, intensity)
    nx, ny = size(slice)

    half_w = width / 2
    half_h = height / 2

    # Iterate using the dimensions of the slice
    for i in 1:nx
        for j in 1:ny
            # 1. Get exact coordinates from the passed axes
            x = ax_x[i]
            y = ax_y[j]

            # 2. Check geometry (Point inside Rectangle)
            # We use abs() <= half_dim to check bounds from center
            inside = (abs(x - cx) <= half_w) && (abs(y - cy) <= half_h)

            # 3. Verify pixel value
            # Access slice[i, j] (Row i = x, Col j = y)
            val = slice[i, j]

            if inside
                if val == 0
                    return "inside not filled for index ($i, $j) at coord ($x, $y)"
                elseif !(val ≈ intensity)
                    return "inside wrong intensity for index ($i, $j)"
                end
            else
                if val != 0
                    return "outside not empty for index ($i, $j) at coord ($x, $y)"
                end
            end
        end
    end
    return "ok"
end

@testset "Cylinder Tests" begin
    @testset "3D draw! - cylinder outside canvas bounds" begin
        # Create a 3D phantom array
        phantom = zeros(Float32, 10, 10, 10)

        # Define axes for a small region
        ax_x = range(-1.0, 1.0, length = 10)
        ax_y = range(-1.0, 1.0, length = 10)
        ax_z = range(-1.0, 1.0, length = 10)

        # Create a cylinder that is completely outside the canvas bounds
        cylinder_outside = Cylinder(
            10.0,   # cx - far right
            10.0,   # cy - far away
            0.5,    # cz - in z range but far in x-y
            0.5,    # r
            1.0,    # height
            1.0     # intensity
        )

        # Draw the cylinder (should return early without modifying phantom)
        draw!(phantom, ax_x, ax_y, ax_z, cylinder_outside)

        # Verify that phantom remains all zeros
        @test all(phantom .== 0.0f0)
    end

    @testset "3D draw! - cylinder at origin" begin
        # Create a 3D phantom array
        nx, ny, nz = 21, 21, 21
        phantom = zeros(Float32, nx, ny, nz)

        # Define axes centered at origin
        ax_x = range(-1.0, 1.0, length = nx)
        ax_y = range(-1.0, 1.0, length = ny)
        ax_z = range(-1.0, 1.0, length = nz)

        # Create a cylinder centered at origin
        r, height, intensity = 0.6, 0.8, 0.8
        cylinder = Cylinder(0.0, 0.0, 0.0, r, height, intensity)

        # Draw the cylinder
        draw!(phantom, ax_x, ax_y, ax_z, cylinder)

        # Verify that the middle axial slice contains the expected circle
        @test test_slice_for_circle(phantom[:, :, 11], ax_x, ax_y, 0.0, 0.0, r, intensity) == "ok"

        # Verify that the middle coronal and sagittal slice contains the expected rectangle
        @test test_slice_for_rectangle(phantom[:, 11, :], ax_x, ax_z, 0.0, 0.0, 2r, height, intensity) == "ok"
        @test test_slice_for_rectangle(phantom[11, :, :], ax_y, ax_z, 0.0, 0.0, 2r, height, intensity) == "ok"
    end

    @testset "3D draw! - CylinderY and CylinderX" begin
        ax = range(-1.0, 1.0, length = 11)
        phantom_y = zeros(Float32, 11, 11, 11)
        draw!(phantom_y, ax, ax, ax, CylinderY(0.1, -0.1, 0.0, 0.4, 0.6, 0.2))
        @test maximum(phantom_y) == 0.2f0

        phantom_x = zeros(Float32, 11, 11, 11)
        draw!(phantom_x, ax, ax, ax, CylinderX(-0.1, 0.1, 0.0, 0.4, 0.6, 0.4))
        @test maximum(phantom_x) == 0.4f0
    end

    @testset "3D draw! - CylinderY outside bounds" begin
        ax = range(-1.0, 1.0, length = 11)
        phantom_outside = zeros(Float32, 11, 11, 11)
        draw!(phantom_outside, ax, ax, ax, CylinderY(5.0, 0.0, 0.0, 0.3, 1.0, 1.0))
        @test all(phantom_outside .== 0.0f0)
    end

    @testset "3D draw! - CylinderX outside bounds" begin
        ax = range(-1.0, 1.0, length = 11)
        phantom_outside = zeros(Float32, 11, 11, 11)
        draw!(phantom_outside, ax, ax, ax, CylinderX(0.0, 5.0, 0.0, 0.3, 1.0, 1.0))
        @test all(phantom_outside .== 0.0f0)
    end

    @testset "2D draw! - cylinder axial slice" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 21, 21)

        # Define axes
        ax_x = range(-1.0, 1.0, length = 21)
        ax_y = range(-1.0, 1.0, length = 21)

        # Create a cylinder
        cylinder = Cylinder(0.0, 0.0, 0.0, 0.5, 1.0, 1.0)

        # Draw at z = 0
        draw!(phantom, ax_x, ax_y, 0.0, cylinder)

        # Check if circle drawn correctly
        @test test_slice_for_circle(phantom, ax_x, ax_y, 0.0, 0.0, 0.5, 1.0) == "ok"
    end

    @testset "2D draw! - cylinder axial slice outside bounds" begin
        phantom = zeros(Float32, 10, 10)
        ax_x = range(5.0, 6.0, length = 10)
        ax_y = range(5.0, 6.0, length = 10)
        draw!(phantom, ax_x, ax_y, 0.0, Cylinder(0.0, 0.0, 0.0, 0.3, 1.0, 1.0))
        @test all(phantom .== 0.0f0)
    end

    @testset "2D draw! - cylinder axial slice with different z" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 21, 21)

        # Define axes
        ax_x = range(-1.0, 1.0, length = 21)
        ax_y = range(-1.0, 1.0, length = 21)

        # Create a cylinder centered at z=0 with height 1.0
        cylinder = Cylinder(0.0, 0.0, 0.0, 0.5, 1.0, 1.0)

        # Draw at z = 0.3 (within height bounds)
        draw!(phantom, ax_x, ax_y, 0.3, cylinder)

        # Check if circle drawn correctly
        @test test_slice_for_circle(phantom, ax_x, ax_y, 0.0, 0.0, 0.5, 1.0) == "ok"

        # Draw at z = 0.6 (outside height bounds)
        phantom_outside = zeros(Float32, 21, 21)
        draw!(phantom_outside, ax_x, ax_y, 0.6, cylinder)

        # Check that nothing was drawn
        @test all(phantom_outside .== 0.0f0)

        # Draw at z = 2.0 (far outside height bounds)
        phantom_far_outside = zeros(Float32, 21, 21)
        draw!(phantom_far_outside, ax_x, ax_y, 2.0, cylinder)

        # Check that nothing was drawn
        @test all(phantom_far_outside .== 0.0f0)
    end

    @testset "2D draw! - cylinder coronal slice" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 21, 21)

        # Define axes
        ax_x = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)

        # Create a cylinder centered at origin
        r, height, intensity = 0.5, 1.0, 0.9
        cylinder = Cylinder(0.0, 0.0, 0.0, r, height, intensity)

        # Draw at y = 0
        draw!(phantom, ax_x, ax_z, 0.0, GeometricMedicalPhantoms.rotate_coronal(cylinder))

        # Check if rectangle drawn correctly
        @test test_slice_for_rectangle(phantom, ax_x, ax_z, 0.0, 0.0, 2r, height, intensity) == "ok"
    end

    @testset "2D draw! - CylinderX coronal view" begin
        phantom = zeros(Float32, 21, 21)
        ax_x = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)
        cylinder = CylinderX(0.0, 0.0, 0.0, 0.4, 1.8, 1.0)
        draw!(phantom, ax_x, ax_z, 0.0, GeometricMedicalPhantoms.rotate_coronal(cylinder))
        @test test_slice_for_rectangle(phantom, ax_x, ax_z, 0.0, 0.0, 1.8, 2 * 0.4, 1.0) == "ok"
    end

    @testset "2D draw! - CylinderY coronal view" begin
        phantom = zeros(Float32, 21, 21)
        ax_x = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)
        cylinder = CylinderY(0.0, 0.0, 0.0, 0.4, 1.8, 1.0)
        draw!(phantom, ax_x, ax_z, 0.0, GeometricMedicalPhantoms.rotate_coronal(cylinder))
        @test test_slice_for_circle(phantom, ax_x, ax_z, 0.0, 0.0, 0.4, 1.0) == "ok"
    end

    @testset "2D draw! - cylinder coronal slice outside bounds" begin
        phantom = zeros(Float32, 10, 10)
        ax_x = range(5.0, 6.0, length = 10)
        ax_z = range(-1.0, 1.0, length = 10)
        draw!(phantom, ax_x, ax_z, 0.0, GeometricMedicalPhantoms.rotate_coronal(Cylinder(0.0, 0.0, 0.0, 0.3, 1.0, 1.0)))
        @test all(phantom .== 0.0f0)
    end

    @testset "2D draw! - cylinder coronal slice with different y" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 21, 21)

        # Define axes
        ax_x = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)

        # Create a cylinder centered at origin
        r, height, intensity = 0.5, 1.0, 0.9
        cylinder = Cylinder(0.0, 0.0, 0.0, r, height, intensity)

        # Draw at y = 0.3 (within height bounds)
        draw!(phantom, ax_x, ax_z, 0.3, GeometricMedicalPhantoms.rotate_coronal(cylinder))

        # Check if rectangle drawn correctly
        chord_length = 2 * sqrt(r^2 - 0.3^2)
        @test test_slice_for_rectangle(phantom, ax_x, ax_z, 0.0, 0.0, chord_length, height, intensity) == "ok"

        # Draw at y = 0.6 (outside height bounds)
        phantom_outside = zeros(Float32, 21, 21)
        draw!(phantom_outside, ax_x, ax_z, 0.6, GeometricMedicalPhantoms.rotate_coronal(cylinder))

        # Check that nothing was drawn
        @test all(phantom_outside .== 0.0f0)

        # Draw at y = -2.0 (far outside height bounds)
        phantom_far_outside = zeros(Float32, 21, 21)
        draw!(phantom_far_outside, ax_x, ax_z, -2.0, GeometricMedicalPhantoms.rotate_coronal(cylinder))

        # Check that nothing was drawn
        @test all(phantom_far_outside .== 0.0f0)
    end

    @testset "2D draw! - cylinder sagittal slice" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 21, 21)

        # Define axes
        ax_y = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)

        # Create a cylinder centered at origin
        r, height, intensity = 0.5, 1.0, 0.7
        cylinder = Cylinder(0.0, 0.0, 0.0, r, height, intensity)

        # Draw at x = 0
        draw!(phantom, ax_y, ax_z, 0.0, GeometricMedicalPhantoms.rotate_sagittal(cylinder))

        # Check if rectangle drawn correctly
        @test test_slice_for_rectangle(phantom, ax_y, ax_z, 0.0, 0.0, 2r, height, intensity) == "ok"
    end

    @testset "2D draw! - CylinderX sagittal view" begin
        phantom = zeros(Float32, 21, 21)
        ax_y = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)
        cylinder = CylinderX(0.0, 0.0, 0.0, 0.4, 1.8, 1.0)
        cylinder_x = GeometricMedicalPhantoms.rotate_sagittal(cylinder)
        draw!(phantom, ax_y, ax_z, 0.0, cylinder_x)
        @test test_slice_for_rectangle(phantom, ax_y, ax_z, 0.0, 0.0, 2 * 0.4, 1.8, 1.0) == "ok"
    end

    @testset "2D draw! - CylinderY sagittal view" begin
        phantom = zeros(Float32, 21, 21)
        ax_y = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)
        cylinder = CylinderY(0.0, 0.0, 0.0, 0.4, 1.8, 1.0)
        cylinder_y = GeometricMedicalPhantoms.rotate_sagittal(cylinder)
        draw!(phantom, ax_y, ax_z, 0.0, cylinder_y)
        @test test_slice_for_rectangle(phantom, ax_y, ax_z, 0.0, 0.0, 1.8, 2 * 0.4, 1.0) == "ok"
    end

    @testset "2D draw! - cylinder sagittal slice outside bounds" begin
        phantom = zeros(Float32, 10, 10)
        ax_y = range(5.0, 6.0, length = 10)
        ax_z = range(-1.0, 1.0, length = 10)
        draw!(phantom, ax_y, ax_z, 0.0, GeometricMedicalPhantoms.rotate_sagittal(Cylinder(0.0, 0.0, 0.0, 0.3, 1.0, 1.0)))
        @test all(phantom .== 0.0f0)
    end

    @testset "2D draw! - cylinder sagittal slice with different x" begin
        # Create a 2D phantom array
        phantom = zeros(Float32, 21, 21)

        # Define axes
        ax_y = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)

        # Create a cylinder centered at origin
        r, height, intensity = 0.5, 1.0, 0.7
        cylinder = Cylinder(0.0, 0.0, 0.0, r, height, intensity)

        # Draw at x = 0.3 (within height bounds)
        draw!(phantom, ax_y, ax_z, 0.3, GeometricMedicalPhantoms.rotate_sagittal(cylinder))

        # Check if rectangle drawn correctly
        chord_length = 2 * sqrt(r^2 - 0.3^2)
        @test test_slice_for_rectangle(phantom, ax_y, ax_z, 0.0, 0.0, height, chord_length, intensity) == "ok"

        # Draw at x = 0.6 (outside height bounds)
        phantom_outside = zeros(Float32, 21, 21)
        draw!(phantom_outside, ax_y, ax_z, 0.6, GeometricMedicalPhantoms.rotate_sagittal(cylinder))

        # Check that nothing was drawn
        @test all(phantom_outside .== 0.0f0)

        # Draw at x = -2.0 (far outside height bounds)
        phantom_far_outside = zeros(Float32, 21, 21)
        draw!(phantom_far_outside, ax_y, ax_z, -2.0, GeometricMedicalPhantoms.rotate_sagittal(cylinder))

        # Check that nothing was drawn
        @test all(phantom_far_outside .== 0.0f0)
    end

    @testset "Cylinder volume check" begin
        # Create a cylinder and verify reasonable volume
        phantom_cylinder = zeros(Float32, 41, 41, 41)

        ax_x = range(-2.0, 2.0, length = 41)
        ax_y = range(-2.0, 2.0, length = 41)
        ax_z = range(-2.0, 2.0, length = 41)

        # Create a cylinder with radius 1.0 and height 2.0
        cylinder = Cylinder(0.0, 0.0, 0.0, 1.0, 2.0, 1.0)

        draw!(phantom_cylinder, ax_x, ax_y, ax_z, cylinder)

        # The cylinder should fill a reasonable portion
        volume = sum(phantom_cylinder .!= 0.0f0)

        # Verify reasonable volume was drawn
        @test volume > 0
        @test volume < 41 * 41 * 41  # Not the entire volume
    end

    @testset "Cylinder with zero radius (edge case)" begin
        # Test cylinder with zero radius (degenerate case - should be empty or very small)
        phantom = zeros(Float32, 21, 21, 21)

        ax_x = range(-1.0, 1.0, length = 21)
        ax_y = range(-1.0, 1.0, length = 21)
        ax_z = range(-1.0, 1.0, length = 21)

        # Cylinder with zero radius (should not draw anything)
        cylinder = Cylinder(0.0, 0.0, 0.0, 0.0, 1.0, 1.0)

        draw!(phantom, ax_x, ax_y, ax_z, cylinder)

        # Should remain all zeros or nearly all zeros
        @test sum(phantom .!= 0.0f0) <= 1
    end

    @testset "Cylinder offset from origin in x" begin
        # Test cylinder that is offset from origin
        phantom = zeros(Float32, 30, 30, 30)

        ax_x = range(-1.5, 1.5, length = 30)
        ax_y = range(-1.5, 1.5, length = 30)
        ax_z = range(-1.5, 1.5, length = 30)

        # Cylinder offset in x
        cylinder = Cylinder(0.75, 0.0, 0.0, 0.5, 1.0, 1.0)

        draw!(phantom, ax_x, ax_y, ax_z, cylinder)

        # Check if a circle is drawn at the correct offset in the middle axial slice
        @test test_slice_for_circle(phantom[:, :, 15], ax_x, ax_y, 0.75, 0.0, 0.5, 1.0) == "ok"
        # Check if rectangle is drawn at the correct offset in the middle coronal slice
        @test test_slice_for_rectangle(phantom[:, 15, :], ax_x, ax_z, 0.75, 0.0, 1.0, 1.0, 1.0) == "ok"
        # Check if rectangle is drawn at the correct offset in the middle sagittal slice
        circle_center_x = findfirst(x -> x >= 0.75, ax_x)
        @test test_slice_for_rectangle(phantom[circle_center_x, :, :], ax_y, ax_z, 0.0, 0.0, 1.0, 1.0, 1.0) == "ok"
    end

    @testset "Cylinder offset from origin in y and z" begin
        # Test cylinder that is offset from origin in y and z
        phantom = zeros(Float32, 30, 30, 30)

        ax_x = range(-1.5, 1.5, length = 30)
        ax_y = range(-1.5, 1.5, length = 30)
        ax_z = range(-1.5, 1.5, length = 30)

        # Cylinder offset in y and z
        cylinder = Cylinder(0.0, -0.75, 0.5, 0.5, 1.0, 1.0)

        draw!(phantom, ax_x, ax_y, ax_z, cylinder)

        # Check if a circle is drawn at the correct offset in the middle axial slice
        center_slice_z = findfirst(z -> z >= 0.5, ax_z)
        @test test_slice_for_circle(phantom[:, :, center_slice_z], ax_x, ax_y, 0.0, -0.75, 0.5, 1.0) == "ok"
        # Check if rectangle is drawn at the correct offset in the middle coronal slice
        circle_center_y = findfirst(y -> y >= -0.75, ax_y)
        @test test_slice_for_rectangle(phantom[:, circle_center_y, :], ax_x, ax_z, 0.0, 0.5, 1.0, 1.0, 1.0) == "ok"
        # Check if rectangle is drawn at the correct offset in the middle sagittal slice
        @test test_slice_for_rectangle(phantom[15, :, :], ax_y, ax_z, -0.75, 0.5, 1.0, 1.0, 1.0) == "ok"
    end

    @testset "TubesMask helper" begin
        mask = TubesMask()
        @test mask.outer_cylinder == true
        @test mask.tube_wall == true
        @test mask.tube_fillings == fill(true, 6)

        mask_custom = TubesMask(outer_cylinder = false, tube_wall = false, tube_fillings = fill(false, 6))
        @test mask_custom.outer_cylinder == false
        @test mask_custom.tube_wall == false
        @test count(mask_custom.tube_fillings) == 0
    end
end
