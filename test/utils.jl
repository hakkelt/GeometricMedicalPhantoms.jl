# Test utilities and helper functions
const utils_included = true

"""
    count_peaks(signal)

Count number of peaks in a signal by detecting negative sign changes in derivative.
"""
function count_peaks(signal)
    d = diff(signal)
    sign_changes = diff(sign.(d))
    return sum(sign_changes .< 0)
end

"""
    count_zero_crossings(signal)

Count number of zero crossings in a signal (centered around its mean).
"""
function count_zero_crossings(signal)
    m = mean(signal)
    return sum(diff(sign.(signal .- m)) .!= 0)
end
