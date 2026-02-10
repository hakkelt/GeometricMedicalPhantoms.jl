"""
    count_voxels(frame::AbstractArray, intensity::Real; tolerance=1f-6) -> Int

Count the number of voxels in a frame with a specific intensity value.

# Arguments
- `frame::AbstractArray`: The phantom frame to analyze
- `intensity::Real`: The target intensity value to count
- `tolerance::Real=1f-6`: Tolerance for intensity matching

# Returns
- `Int`: Number of voxels matching the intensity

# Example
```julia
frame = phantom[:, :, :, 1]
lung_count = count_voxels(frame, 0.08f0)
```
"""
function count_voxels(frame::AbstractArray, intensity::Real; tolerance = 1.0f-6)
    return count(x -> abs(real(x) - intensity) < tolerance, frame)
end

"""
    count_voxels(frame::AbstractArray, intensity_range::Tuple{Real, Real}) -> Int

Count the number of voxels in a frame within a specific intensity range.

# Arguments
- `frame::AbstractArray`: The phantom frame to analyze
- `intensity_range::Tuple{Real, Real}`: Min and max intensity values (inclusive)

# Returns
- `Int`: Number of voxels within the intensity range

# Example
```julia
frame = phantom[:, :, :, 1]
lung_count = count_voxels(frame, (0.075f0, 0.11f0))
```
"""
function count_voxels(frame::AbstractArray, intensity_range::Tuple{Real, Real})
    min_int, max_int = intensity_range
    return count(x -> (real(x) >= min_int && real(x) <= max_int), frame)
end

"""
    calculate_volume(frame::AbstractArray, intensity, fov::Tuple; kwargs...) -> Float64

Calculate the volume in liters of voxels with a specific intensity or intensity range.

# Arguments
- `frame::AbstractArray`: The phantom frame to analyze
- `intensity`: Either a single intensity value or a tuple (min, max) for range
- `fov::Tuple`: Field of view in cm for (x, y, z) dimensions

# Keywords
- `tolerance::Real=1f-6`: Tolerance for intensity matching (only for single intensity)

# Returns
- `Float64`: Volume in liters

# Example
```julia
frame = phantom[:, :, :, 1]
lung_vol = calculate_volume(frame, (0.075f0, 0.11f0), (30, 30, 30))
```
"""
function calculate_volume(frame::AbstractArray, intensity, fov::Tuple; tolerance = 1.0f-6)
    nx, ny, nz = size(frame)[1:3]
    voxel_vol_cm3 = (fov[1] / nx) * (fov[2] / ny) * (fov[3] / nz)
    voxel_vol_L = voxel_vol_cm3 / 1000.0

    voxel_count = if intensity isa Tuple
        count_voxels(frame, intensity)
    else
        count_voxels(frame, intensity; tolerance = tolerance)
    end

    return voxel_count * voxel_vol_L
end
