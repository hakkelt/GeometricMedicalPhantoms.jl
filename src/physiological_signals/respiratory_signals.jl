"""
RespiratoryPhysiology

Physiology constants controlling simulated respiratory signal (liters).

Fields
- `minL`, `maxL`: Minimum and maximum lung volume in liters
- `asym_amp`: Amplitude of asymmetry harmonic (fraction of main amplitude)
- `amp_mod_amp`, `amp_mod_freq`: Amplitude modulation amplitude (fraction) and frequency (Hz)
- `rr_var_amp`, `rr_var_freq`: Respiratory rate variability amplitude (fraction of base) and frequency (Hz)

Usage
Create with keyword overrides and pass as `physiology` to `generate_respiratory_signal`.
"""
Base.@kwdef struct RespiratoryPhysiology
    minL::Float64 = 2.4
    maxL::Float64 = 3.0
    asym_amp::Float64 = 0.2
    amp_mod_amp::Float64 = 0.15
    amp_mod_freq::Float64 = 0.05
    rr_var_amp::Float64 = 0.03
    rr_var_freq::Float64 = 0.03
end

"""
    generate_respiratory_signal(duration=60.0, fs=50.0, rr=15.0; physiology::RespiratoryPhysiology=RespiratoryPhysiology()) -> (Vector{Float64}, Vector{Float64})

Generate a simplified respiratory signal in liters.

# Arguments
- `duration::Float64=60.0`: Duration of signal in seconds
- `fs::Float64=50.0`: Sampling frequency in Hz
- `rr::Float64=15.0`: Respiratory rate in breaths per minute
- `physiology::RespiratoryPhysiology=RespiratoryPhysiology()`: Optional physiology constants

# Returns
- Tuple of (time_vector, respiratory_signal_liters)

# Description
Generates a synthetic respiratory signal with:
- Sinusoidal breathing pattern
- Asymmetric inspiration/expiration
- Amplitude modulation (breathing depth variation)

# Example
```julia
t, resp_L = generate_respiratory_signal(60.0, 50.0, 15.0)
# resp_L is in liters
```
"""
function generate_respiratory_signal(duration=60.0, fs=50.0, rr=15.0; physiology::RespiratoryPhysiology=RespiratoryPhysiology())
    # Time vector
    t = 0:1/fs:duration-1/fs
    
    # Respiratory rate in Hz
    rr_hz = rr / 60.0

    # Slight sinusoidal variation in respiratory rate via phase modulation
    fm = physiology.rr_var_freq
    varm = physiology.rr_var_amp
    if fm > 0 && varm != 0
        θ = 2π .* rr_hz .* t .- (rr_hz * varm / fm) .* (cos.(2π .* fm .* t) .- 1.0)
    else
        θ = 2π .* rr_hz .* t
    end

    # Main respiratory component with asymmetric harmonic
    resp = sin.(θ)
    resp .+= physiology.asym_amp .* sin.(2 .* θ)

    # Add slight variation in amplitude (breathing depth changes)
    amplitude_mod = 1.0 .+ physiology.amp_mod_amp .* sin.(2π .* physiology.amp_mod_freq .* t)
    resp .*= amplitude_mod

    # Normalize to 0..1, then map to liters [minL, maxL]
    resp_norm = (resp .- minimum(resp)) ./ (maximum(resp) - minimum(resp))
    resp_liters = physiology.minL .+ (physiology.maxL - physiology.minL) .* resp_norm

    return collect(t), resp_liters
end
