# geometric-medical-phantoms

Python bindings for the [GeometricMedicalPhantoms](https://github.com/hakkelt/GeometricMedicalPhantoms.jl)
shared library — a Julia-based toolkit for generating synthetic MRI/CT phantoms.

## Supported phantoms

- **Shepp-Logan** — classic ellipsoid head phantom (CT and MRI variants)
- **Tubes** — cylindrical quality-control phantom
- **Torso** — anatomically-motivated torso with respiratory and cardiac motion

## Requirements

- Python ≥ 3.9
- NumPy ≥ 1.20
- The pre-built `libgeomphantoms` shared library (see
  [Releases](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases))

## Installation

```sh
pip install geometric-medical-phantoms
```

Then download the pre-built library bundle for your platform from the
[GitHub Releases](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/releases)
page and extract it.

## Quick start

```python
from geometric_medical_phantoms import GMPLib

lib = GMPLib("/path/to/build/lib/libgeomphantoms.so")  # .dylib / .dll on other platforms

# Shepp-Logan 3-D phantom
ti = lib.shepp_logan_ct_default()
phantom = lib.create_shepp_logan_phantom_3d(128, 128, 128, ti)
# phantom is a (128, 128, 128) float32 numpy array in Fortran (column-major) order

# Respiratory signal
phys = lib.respiratory_physiology_default()
t, sig = lib.generate_respiratory_signal(60.0, 50.0, 15.0, phys)

# Dynamic torso phantom (4-D cine)
torso = lib.create_torso_phantom_3d(64, 64, 64, resp_signal=sig[:50])
# torso.shape == (64, 64, 64, 50)
```

## Documentation

Full API reference and usage guides are available at
<https://hakkelt.github.io/GeometricMedicalPhantoms.jl>.

## License

MIT — see [LICENSE](https://github.com/hakkelt/GeometricMedicalPhantoms.jl/blob/master/LICENSE).
