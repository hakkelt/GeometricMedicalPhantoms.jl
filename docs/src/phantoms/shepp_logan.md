# Shepp-Logan Phantom

The Shepp-Logan phantom is the classic test phantom in medical imaging. First introduced by Shepp and Logan in 1974, it represents a simplified model of the human head using overlapping ellipses, making it ideal for testing image reconstruction algorithms and understanding imaging physics.

## History and Design Philosophy

The original phantom (Shepp & Logan, 1974) was designed as a synthetic test image for CT reconstruction, composed of 10 ellipses with different attenuation coefficients. In 1988, Kak and Slaney popularized its use in the context of filtered backprojection algorithms, and defined a 3D version using ellipsoids. It became the standard test case because:

- **Simplicity**: Easy to generate and understand
- **Reproducibility**: Well-defined mathematical structure enables precise comparisons

The MRI variant (Toft, 1996) adapted intensity values for nuclear magnetic resonance instead of X-ray attenuation, scaling to realistic MRI signal ranges.

Compared to Kak & Slaney's implementation, GeometricMedicalPhantoms differs by the following design choices:
- **Additional ellipsoids**: Includes two extra ellipsoids to approximately match with the original 2D Shepp & Logan design (suggested by Lei Shu <leizhu@stanford.edu>).
- **Shift in z-axis** by 0.25: This adjustment makes the connection between the original 2D phantom and the 3D volume more intuitive by centering the axial slice that matches the 2D phantom.

### Comparison with ImagePhantoms.jl

Both the 2D and the 3D Shepp-Logan phantoms are also available in the ImagePhantoms.jl package. For higher precision, one might prefer ImagePhantoms.jl, which samples the analytical definition in Fourier or Randon space directly. GeometricMedicalPhantoms.jl, however, provides more flexibility over geometry and intensity customization, and have been optimized for fast voxel-based rendering.

## Basic Usage

```@setup imports
using GeometricMedicalPhantoms
using MIRTjim: jim
using Plots
```

### 2D Slices

Generate a 2D Shepp-Logan phantom at any orientation:

```@example imports
# Create axial (horizontal) slice
phantom_axial = create_shepp_logan_phantom(256, 256, :axial)
jim(phantom_axial; title="Axial View", clim=(0.95, 1.05), yflip=false)
savefig("shepp_logan_axial.png"); nothing # hide
```

![shepp_logan_axial.png](shepp_logan_axial.png)

```@example imports
# Create coronal (front-to-back) slice
phantom_coronal = create_shepp_logan_phantom(256, 256, :coronal)
jim(phantom_coronal; title="Coronal View", clim=(0.95, 1.05), yflip=false)
savefig("shepp_logan_coronal.png"); nothing # hide
```

![shepp_logan_coronal.png](shepp_logan_coronal.png)

```@example imports
# Create sagittal (left-right) slice
phantom_sagittal = create_shepp_logan_phantom(256, 256, :sagittal)
jim(phantom_sagittal; title="Sagittal View", clim=(0.95, 1.05), yflip=false)
savefig("shepp_logan_sagittal.png"); nothing # hide
```

![shepp_logan_sagittal.png](shepp_logan_sagittal.png)

### 3D Volume

Generate a full 3D phantom:

```@example imports
phantom_3d = create_shepp_logan_phantom(128, 128, 128)
println("Phantom shape: $(size(phantom_3d))")
println("Min value: $(minimum(phantom_3d))")
println("Max value: $(maximum(phantom_3d))")
nothing # hide
```

Create spatial slicing GIF showing all slices through the volume:

```@example imports
using FileIO, ImageIO, ImageMagick

# Create axial slices GIF (loop through z-axis)
nx, ny, nz = size(phantom_3d)
frames_axial = zeros(UInt8, nx, ny, nz)

for i in 1:nz
    slice = abs.(phantom_3d[:, :, i])
    frames_axial[:, :, i] = map(x -> UInt8(round((clamp(x, 0.95, 1.05) - 0.95) / 0.1 * 255)), slice)
end

save("shepp_logan_axial_slices.gif", frames_axial, fps=10)
nothing # hide
```

![shepp_logan_axial_slices.gif](shepp_logan_axial_slices.gif)

```@example imports
# Create coronal slices GIF (loop through y-axis)
frames_coronal = zeros(UInt8, nx, nz, ny)
for i in 1:ny
    slice = abs.(phantom_3d[:, i, :])
    frames_coronal[:, :, i] = map(x -> UInt8(round((clamp(x, 0.95, 1.05) - 0.95) / 0.1 * 255)), slice)
end

save("shepp_logan_coronal_slices.gif", frames_coronal, fps=10)
nothing # hide
```

![shepp_logan_coronal_slices.gif](shepp_logan_coronal_slices.gif)

```@example imports
# Create sagittal slices GIF (loop through x-axis)
frames_sagittal = zeros(UInt8, ny, nz, nx)
for i in 1:nx
    slice = abs.(phantom_3d[i, :, :])
    frames_sagittal[:, :, i] = map(x -> UInt8(round((clamp(x, 0.95, 1.05) - 0.95) / 0.1 * 255)), slice)
end

save("shepp_logan_sagittal_slices.gif", frames_sagittal, fps=10)
nothing # hide
```

![shepp_logan_sagittal_slices.gif](shepp_logan_sagittal_slices.gif)

## Intensity Variants

The package provides different intensity scaling options:

### CT Intensities (Original Shepp-Logan)

```@example imports
phantom_ct = create_shepp_logan_phantom(256, 256, :axial; ti=CTSheppLoganIntensities())
jim(phantom_ct; title="CT Shepp-Logan", clim=(0.95, 1.05), yflip=false)
savefig("shepp_logan_ct.png"); nothing # hide
```

![shepp_logan_ct.png](shepp_logan_ct.png)

This uses the original Shepp & Logan (1974) attenuation coefficients adapted for CT imaging.

### MRI Intensities (Toft 1996)

```@example imports
phantom_mri = create_shepp_logan_phantom(256, 256, :axial; ti=MRISheppLoganIntensities())
jim(phantom_mri; title="MRI Shepp-Logan", yflip=false)
savefig("shepp_logan_mri.png"); nothing # hide
```

![shepp_logan_mri.png](shepp_logan_mri.png)

The MRI version from Toft's PhD thesis (1996) provides intensity values suited for nuclear magnetic resonance imaging.

### Custom Intensities

You can create custom intensity values:

```@example imports
using GeometricMedicalPhantoms: SheppLoganIntensities

# Create custom intensities with your own values
custom_intensities = SheppLoganIntensities(
    skull=1.5,
    brain=0.5,
    right_big=-0.1,
    left_big=-0.1,
    top=0.2,
    middle_high=0.2,
    bottom_left=0.2,
    middle_low=0.2,
    bottom_center=0.2,
    bottom_right=0.2,
    extra_1=0.3,
    extra_2=-0.1
)

phantom_custom = create_shepp_logan_phantom(256, 256, :axial; ti=custom_intensities)
jim(phantom_custom; title="Custom Intensities", yflip=false)
savefig("shepp_logan_custom.png"); nothing # hide
```

![shepp_logan_custom.png](shepp_logan_custom.png)

## Tissue Masking

Extract masks for specific anatomical regions:

```@example imports
# Create mask of the skull
skull_mask = create_shepp_logan_phantom(256, 256, :axial; ti=SheppLoganMask(skull=true))
jim(skull_mask; title="Skull Mask", yflip=false)
savefig("shepp_logan_skull_mask.png"); nothing # hide
```

![shepp_logan_skull_mask.png](shepp_logan_skull_mask.png)

```@example imports
# Create mask of the brain
brain_mask = create_shepp_logan_phantom(256, 256, :axial; ti=SheppLoganMask(brain=true))
jim(brain_mask; title="Brain Mask", yflip=false)
savefig("shepp_logan_brain_mask.png"); nothing # hide
```

![shepp_logan_brain_mask.png](shepp_logan_brain_mask.png)

```@example imports
# Create combined mask of brain structures
structures_mask = create_shepp_logan_phantom(256, 256, :axial; 
    ti=SheppLoganMask(brain=true, right_big=true, left_big=true))
jim(structures_mask; title="Brain Structures", yflip=false)
savefig("shepp_logan_structures_mask.png"); nothing # hide
```

![shepp_logan_structures_mask.png](shepp_logan_structures_mask.png)

## Advanced Parameters

### Resolution and Field of View

Control the resolution and spatial extent:

```@example imports
# Low resolution
phantom_low = create_shepp_logan_phantom(64, 64, :axial)

# High resolution
phantom_high = create_shepp_logan_phantom(512, 512, :axial)

p1 = jim(phantom_low; title="Low Res (64×64)", clim=(0.95, 1.05), yflip=false)
p2 = jim(phantom_high; title="High Res (512×512)", clim=(0.95, 1.05), yflip=false)
plot(p1, p2, layout=(1,2), size=(1000,400))
savefig("shepp_logan_resolution.png"); nothing # hide
```

![shepp_logan_resolution.png](shepp_logan_resolution.png)

### Custom Field of View

```@example imports
# Smaller FOV (zoomed in)
phantom_small_fov = create_shepp_logan_phantom(256, 256, :axial; fovs=(10.0, 10.0))

# Larger FOV (zoomed out)
phantom_large_fov = create_shepp_logan_phantom(256, 256, :axial; fovs=(30.0, 30.0))

p1 = jim(phantom_small_fov; title="Small FOV (10cm)", clim=(0.95, 1.05), yflip=false)
p2 = jim(phantom_large_fov; title="Large FOV (30cm)", clim=(0.95, 1.05), yflip=false)
plot(p1, p2, layout=(1,2), size=(1000,400))
savefig("shepp_logan_fov.png"); nothing # hide
```

![shepp_logan_fov.png](shepp_logan_fov.png)

### Data Type

Control the output data type and create specific masks:

```@example imports
phantom_f32 = create_shepp_logan_phantom(256, 256, :axial; eltype=Float32)
phantom_f64 = create_shepp_logan_phantom(256, 256, :axial; eltype=Float64)
# Create a mask where only skull and top ellipsoids are selected
phantom_mask = create_shepp_logan_phantom(256, 256, :axial; ti=SheppLoganMask(skull=true, top=true))

println("Float32: $(typeof(phantom_f32))")
println("Float64: $(typeof(phantom_f64))")
println("Mask (Bool): $(typeof(phantom_mask))")

jim(phantom_mask; title="Skull + Top Mask", yflip=false)
savefig("shepp_logan_mask_example.png"); nothing # hide
```

![shepp_logan_mask_example.png](shepp_logan_mask_example.png)


