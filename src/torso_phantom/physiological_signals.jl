"""
CardiacPhysiology

Physiology constants controlling simulated cardiac chamber volumes (mL) and slow modulations.

Fields
- `lv_edv`: Left ventricle end-diastolic volume (mL)
- `lv_esv`: Left ventricle end-systolic volume (mL)
- `rv_edv`: Right ventricle end-diastolic volume (mL)
- `rv_esv`: Right ventricle end-systolic volume (mL)
- `la_min`, `la_max`: Left atrium min/max volumes (mL)
- `ra_min`, `ra_max`: Right atrium min/max volumes (mL)
- `hr_var_amp`, `hr_var_freq`: Heart rate variability amplitude (fraction) and frequency (Hz)
- `v_amp_amp`, `v_amp_freq`: Ventricular amplitude modulation amplitude (fraction) and frequency (Hz)
- `a_amp_amp`, `a_amp_freq`: Atrial amplitude modulation amplitude (fraction) and frequency (Hz)
- `bw_amp`, `bw_freq`: Baseline wander amplitude (mL) and frequency (Hz)
- `s_frac_base`: Base systole fraction (0..1)
- `lv_kick_amp_frac`, `lv_kick_center`, `lv_kick_width`: Left ventricle atrial kick amplitude fraction, center, and width
- `rv_kick_amp_frac`, `rv_kick_center`, `rv_kick_width`: Right ventricle atrial kick amplitude fraction, center, and width
- `la_contr_amp_frac`, `la_contr_center`, `la_contr_width`: Left atrium contraction amplitude fraction, center, and width
- `ra_contr_amp_frac`, `ra_contr_center`, `ra_contr_width`: Right atrium contraction amplitude fraction, center, and width

Usage
Create with keyword overrides and pass as `physiology` to `generate_cardiac_signals` to customize volumes and modulations.

# Example
```julia
phys = CardiacPhysiology(lv_edv=130.0, lv_esv=55.0, rv_edv=140.0, rv_esv=65.0)
t, vols = generate_cardiac_signals(10.0, 500.0, 70.0; physiology=phys)
```
"""
Base.@kwdef struct CardiacPhysiology
    lv_edv::Float64 = 130.0
    lv_esv::Float64 = 55.0
    rv_edv::Float64 = 140.0
    rv_esv::Float64 = 65.0
    la_min::Float64 = 30.0
    la_max::Float64 = 60.0
    ra_min::Float64 = 30.0
    ra_max::Float64 = 60.0
    # Modulation and wander parameters
    hr_var_amp::Float64 = 0.0
    hr_var_freq::Float64 = 0.1
    v_amp_amp::Float64 = 0.0
    v_amp_freq::Float64 = 0.08
    a_amp_amp::Float64 = 0.02
    a_amp_freq::Float64 = 0.09
    bw_amp::Float64 = 0.0
    bw_freq::Float64 = 0.03
    s_frac_base::Float64 = 0.35
    # Ventricular atrial kick parameters (fractions relative to stroke/amplitude)
    lv_kick_amp_frac::Float64 = 0.07
    lv_kick_center::Float64 = 0.92
    lv_kick_width::Float64 = 0.04
    rv_kick_amp_frac::Float64 = 0.06
    rv_kick_center::Float64 = 0.92
    rv_kick_width::Float64 = 0.05
    # Atrial contraction parameters
    la_contr_amp_frac::Float64 = 0.15
    la_contr_center::Float64 = 0.95
    la_contr_width::Float64 = 0.03
    ra_contr_amp_frac::Float64 = 0.12
    ra_contr_center::Float64 = 0.95
    ra_contr_width::Float64 = 0.03
end

"""
    generate_cardiac_signals(duration=10.0, fs=500.0, hr=70.0; physiology::CardiacPhysiology=CardiacPhysiology()) -> (Vector{Float64}, NamedTuple)

Simulate cardiac chamber volumes (mL) for left/right ventricles and atria.

# Arguments
- `duration::Float64=10.0`: Duration of signal in seconds
- `fs::Float64=500.0`: Sampling frequency in Hz
- `hr::Float64=70.0`: Heart rate in beats per minute
- `physiology::CardiacPhysiology=CardiacPhysiology()`: Optional physiology constants

# Returns
- Tuple of (time_vector, volumes::NamedTuple{(:lv,:rv,:la,:ra)}) where each field is Vector{Float64}

# Description
- Generates four periodic time series of chamber volumes in milliliters.
- The ventricles are high during diastole and low during systole; atria are approximately in opposite phase.
- Default physiology constants are set to plausible values but can be tuned via `physiology`.
- It includes slight heart rate variability, amplitude modulation, and baseline wander.

# Example
```julia
t, vols = generate_cardiac_signals(10.0, 500.0, 70.0)
# vols.lv, vols.rv, vols.la, vols.ra are in mL
```
"""
function generate_cardiac_signals(duration=10.0, fs=500.0, hr::Real=70.0;
    physiology::CardiacPhysiology=CardiacPhysiology())

    # Time vector
    t = collect(0:1/fs:duration-1/fs)
    # Heart rate in Hz and cycle period
    hr_hz = hr / 60.0
    T = 1.0 / hr_hz
    # Slight variation in heart rate over time
    t_var = t .+ physiology.hr_var_amp .* sin.(2π .* physiology.hr_var_freq .* t)
    # Phase in [0,1) for each sample
    ϕ = (t_var .% T) ./ T

    # Systole fraction (approximate)
    s_frac_base = physiology.s_frac_base
    s_frac_t = s_frac_base .* (1 .+ 0.08 .* sin.(2π .* 0.1 .* t))
    mask_s = ϕ .< s_frac_t
    x_s = clamp.(ϕ ./ s_frac_t, 0.0, 1.0)
    x_d = clamp.((ϕ .- s_frac_t) ./ (1 .- s_frac_t), 0.0, 1.0)

    # Ventricles: fast ejection, slower filling with atrial kick
    lv = zeros(length(t))
    rv = zeros(length(t))

    lv_range = physiology.lv_edv - physiology.lv_esv
    rv_range = physiology.rv_edv - physiology.rv_esv

    lv_s = physiology.lv_edv .- lv_range .* (1 .- (1 .- x_s).^3)
    rv_s = physiology.rv_edv .- rv_range .* (1 .- (1 .- x_s).^3)

    lv_d_base = physiology.lv_esv .+ lv_range .* (x_d .^ 2.2)
    rv_d_base = physiology.rv_esv .+ rv_range .* (x_d .^ 2.0)
    lv_kick = physiology.lv_kick_amp_frac .* lv_range .* exp.(-((x_d .- physiology.lv_kick_center) ./ physiology.lv_kick_width).^2)
    rv_kick = physiology.rv_kick_amp_frac .* rv_range .* exp.(-((x_d .- physiology.rv_kick_center) ./ physiology.rv_kick_width).^2)

    lv_d = lv_d_base .+ lv_kick
    rv_d = rv_d_base .+ rv_kick

    lv[mask_s] .= lv_s[mask_s]
    lv[.!mask_s] .= lv_d[.!mask_s]

    rv[mask_s] .= rv_s[mask_s]
    rv[.!mask_s] .= rv_d[.!mask_s]

    # Atria: fill during ventricular systole, empty during diastole with atrial contraction
    la = zeros(length(t))
    ra = zeros(length(t))

    la_range = physiology.la_max - physiology.la_min
    ra_range = physiology.ra_max - physiology.ra_min

    la_s = physiology.la_min .+ la_range .* (x_s .^ 1.5)
    ra_s = physiology.ra_min .+ ra_range .* (x_s .^ 1.5)

    la_d_base = physiology.la_max .- la_range .* (1 .- (1 .- x_d).^3)
    ra_d_base = physiology.ra_max .- ra_range .* (1 .- (1 .- x_d).^3)
    la_contr = physiology.la_contr_amp_frac .* la_range .* exp.(-((x_d .- physiology.la_contr_center) ./ physiology.la_contr_width).^2)
    ra_contr = physiology.ra_contr_amp_frac .* ra_range .* exp.(-((x_d .- physiology.ra_contr_center) ./ physiology.ra_contr_width).^2)

    la_d = la_d_base .- la_contr
    ra_d = ra_d_base .- ra_contr

    la[mask_s] .= la_s[mask_s]
    la[.!mask_s] .= la_d[.!mask_s]

    ra[mask_s] .= ra_s[mask_s]
    ra[.!mask_s] .= ra_d[.!mask_s]

    # Slow amplitude modulation and baseline wander
    v_amp = 1 .+ physiology.v_amp_amp .* sin.(2π .* physiology.v_amp_freq .* t)
    a_amp = 1 .+ physiology.a_amp_amp .* sin.(2π .* physiology.a_amp_freq .* t .+ 0.7)
    bw = physiology.bw_amp .* sin.(2π .* physiology.bw_freq .* t)
    lv .= lv .* v_amp .+ bw
    rv .= rv .* v_amp .+ bw
    la .= la .* a_amp .+ 0.8 .* bw
    ra .= ra .* a_amp .+ 0.8 .* bw

    return t, (lv=lv, rv=rv, la=la, ra=ra)
end

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
