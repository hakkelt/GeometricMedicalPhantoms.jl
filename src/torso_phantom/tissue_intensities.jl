"""
    TissueIntensities

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
Base.@kwdef struct TissueIntensities
    lung::Float64 = 0.08
    heart::Float64 = 0.65
    vessels_blood::Float64 = 1.00
    bones::Float64 = 0.85
    liver::Float64 = 0.55
    stomach::Float64 = 0.90
    body::Float64 = 0.25
    lv_blood::Float64 = 0.98
    rv_blood::Float64 = 0.99
    la_blood::Float64 = 0.97
    ra_blood::Float64 = 0.96
end

"""
    tissue_mask(ti::TissueIntensities, field::Symbol) -> TissueIntensities

Create a binary mask TissueIntensities object where all fields are set to 0.0 
except the specified field, which is set to 1.0.

# Arguments
- `ti::TissueIntensities`: The source TissueIntensities object (values ignored)
- `field::Symbol`: The field name to set to 1.0 (e.g., :lung, :heart, :lv_blood)

# Returns
- `TissueIntensities`: A new TissueIntensities with all fields zero except the specified one

# Example
```julia
ti = TissueIntensities()
lung_mask = tissue_mask(ti, :lung)  # Creates mask with lung=1.0, all others=0.0
```
"""
function tissue_mask(ti::TissueIntensities, field::Symbol)
    # Get all field names from TissueIntensities
    fields = fieldnames(TissueIntensities)
    
    # Create keyword arguments with all zeros except the specified field
    kwargs = Dict{Symbol, Float64}()
    for f in fields
        kwargs[f] = (f == field) ? 1.0 : 0.0
    end
    
    return TissueIntensities(; kwargs...)
end
