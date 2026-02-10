"""
    TubesIntensities

Intensity parameters for the tubes phantom.

# Fields
- `outer_cylinder::Float64`: Intensity of the outer cylinder (default: 0.25)
- `tube_wall::Float64`: Intensity of tube walls (default: 0.0)
- `tube_fillings::Vector{Float64}`: Intensities for tube fillings (default: [0.1, 0.3, 0.5, 0.7, 0.9, 1.0])
"""
Base.@kwdef struct TubesIntensities{T}
    outer_cylinder::T = 0.25
    tube_wall::T = 0.0
    tube_fillings::Vector{T} = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0]
end

"""
    TubesMask(; kwargs...)

Create a boolean mask for the tubes phantom.

# Example
```julia
mask = TubesMask(outer_cylinder=true, tube_wall=false, tube_fillings=[true, true, true, true, true, true])
```
"""
function TubesMask(;
        outer_cylinder::Bool = true,
        tube_wall::Bool = true,
        tube_fillings::Vector{Bool} = fill(true, 6)
    )
    return TubesIntensities{Bool}(
        outer_cylinder = outer_cylinder,
        tube_wall = tube_wall,
        tube_fillings = tube_fillings
    )
end
