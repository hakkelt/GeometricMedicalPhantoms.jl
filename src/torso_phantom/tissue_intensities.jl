"""
    AbstractTissueParameters

Abstract supertype for tissue parameters used in phantom generation.
"""
abstract type AbstractTissueParameters end

"""
    TissueIntensities <: AbstractTissueParameters

Struct to hold tissue intensity values for different anatomical structures in the torso phantom.

Fields:
- `lung::Float64`: Intensity value for lung tissue
- `heart::Float64`: Intensity value for heart muscle
- `vessels_blood::Float64`: Intensity value for blood in vessels
- `bones::Float64`: Intensity value for bone tissue
- `liver::Float64`: Intensity value for liver tissue
- `stomach::Float64`: Intensity value for stomach tissue
- `body::Float64`: Intensity value for general body tissue
- `lv_blood::Float64`: Intensity value for left ventricle blood
- `rv_blood::Float64`: Intensity value for right ventricle blood
- `la_blood::Float64`: Intensity value for left atrium blood
- `ra_blood::Float64`: Intensity value for right atrium blood
"""
Base.@kwdef struct TissueIntensities <: AbstractTissueParameters
    lung::Float64 = 0.08
    heart::Float64 = 0.65
    vessels_blood::Float64 = 1.0
    bones::Float64 = 0.85
    liver::Float64 = 0.55
    stomach::Float64 = 0.9
    body::Float64 = 0.25
    lv_blood::Float64 = 0.98
    rv_blood::Float64 = 0.99
    la_blood::Float64 = 0.97
    ra_blood::Float64 = 0.96
end

"""
    TissueMask <: AbstractTissueParameters

Struct to hold tissue mask specification for binary phantom generation.
Only one tissue type should be selected (set to true), all others should be false.

Fields:
- `lung::Bool`: Whether to include lung tissue
- `heart::Bool`: Whether to include heart muscle
- `vessels_blood::Bool`: Whether to include blood in vessels
- `bones::Bool`: Whether to include bone tissue
- `liver::Bool`: Whether to include liver tissue
- `stomach::Bool`: Whether to include stomach tissue
- `body::Bool`: Whether to include general body tissue
- `lv_blood::Bool`: Whether to include left ventricle blood
- `rv_blood::Bool`: Whether to include right ventricle blood
- `la_blood::Bool`: Whether to include left atrium blood
- `ra_blood::Bool`: Whether to include right atrium blood

# Example
```julia
# Create a mask for lung tissue only
lung_mask = TissueMask(lung=true)

# Create a mask for heart muscle only
heart_mask = TissueMask(heart=true)
```
"""
Base.@kwdef struct TissueMask <: AbstractTissueParameters
    lung::Bool = false
    heart::Bool = false
    vessels_blood::Bool = false
    bones::Bool = false
    liver::Bool = false
    stomach::Bool = false
    body::Bool = false
    lv_blood::Bool = false
    rv_blood::Bool = false
    la_blood::Bool = false
    ra_blood::Bool = false
end

"""
Helper function to get the intensity value from tissue parameters.
For TissueIntensities, returns the Float64 value.
For TissueMask, returns 1.0 if the field is true, 0.0 otherwise.
"""
@inline function get_intensity(ti::TissueIntensities, field::Symbol)
    return MaskingIntensityValue(getfield(ti, field))
end

@inline function get_intensity(ti::TissueMask, field::Symbol)
    return MaskingIntensityValue(getfield(ti, field))
end
