"""
    TissueIntensities

Struct to hold tissue intensity values for different anatomical structures in the torso phantom.

Fields:
- `lung::Float32`: Intensity value for lung tissue
- `heart::Float32`: Intensity value for heart muscle
- `vessels_blood::Float32`: Intensity value for blood in vessels
- `bones::Float32`: Intensity value for bone tissue
- `liver::Float32`: Intensity value for liver tissue
- `stomach::Float32`: Intensity value for stomach tissue
- `body::Float32`: Intensity value for general body tissue
- `lv_blood::Float32`: Intensity value for left ventricle blood
- `rv_blood::Float32`: Intensity value for right ventricle blood
- `la_blood::Float32`: Intensity value for left atrium blood
- `ra_blood::Float32`: Intensity value for right atrium blood
"""
Base.@kwdef struct TissueIntensities
    lung::Float32 = 0.08f0
    heart::Float32 = 0.65f0
    vessels_blood::Float32 = 1.00f0
    bones::Float32 = 0.85f0
    liver::Float32 = 0.55f0
    stomach::Float32 = 0.90f0
    body::Float32 = 0.25f0
    lv_blood::Float32 = 0.98f0
    rv_blood::Float32 = 0.99f0
    la_blood::Float32 = 0.97f0
    ra_blood::Float32 = 0.96f0
end

"""
    tissue_mask(ti::TissueIntensities, field::Symbol) -> TissueIntensities

Create a binary mask TissueIntensities object where all fields are set to 0.0f0 
except the specified field, which is set to 1.0f0.

# Arguments
- `ti::TissueIntensities`: The source TissueIntensities object (values ignored)
- `field::Symbol`: The field name to set to 1.0f0 (e.g., :lung, :heart, :lv_blood)

# Returns
- `TissueIntensities`: A new TissueIntensities with all fields zero except the specified one

# Example
```julia
ti = TissueIntensities()
lung_mask = tissue_mask(ti, :lung)  # Creates mask with lung=1.0f0, all others=0.0f0
```
"""
function tissue_mask(ti::TissueIntensities, field::Symbol)
    # Get all field names from TissueIntensities
    fields = fieldnames(TissueIntensities)
    
    # Create keyword arguments with all zeros except the specified field
    kwargs = Dict{Symbol, Float32}()
    for f in fields
        kwargs[f] = (f == field) ? 1.0f0 : 0.0f0
    end
    
    return TissueIntensities(; kwargs...)
end
