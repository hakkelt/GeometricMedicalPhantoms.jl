# GeometricMedicalPhantoms.jl

[![Documentation][docs-img]](docs-url)
[![CI Status][ci-img]](ci-url)
[![codecov][codecov-img]](codecov-url)
[![Aqua QA][aqua-img]][aqua-url]
[![Tested with JET][jet-img]][jet-url]
[![code style: runic][runic-img]](runic-url)
[![license][license-img]](license-url)

**GeometricMedicalPhantoms.jl** provides anatomically realistic digital phantoms for medical imaging research. Built on precise geometric primitives, these phantoms enable realistic simulation of MRI acquisition, reconstruction algorithm development, and validation of motion correction techniques.

## Features

- **Standard Phantoms**: Shepp-Logan (2D/3D), anatomical Torso phantom, geometric Tubes phantom
- **Physiological Motion**: Realistic cardiac and respiratory motion simulation
- **Flexible Geometry**: Ellipsoids, cylinders, and custom primitives with masking/additive modes
- **Easy Customization**: Control tissue intensities, FOV, resolution, and motion parameters
- **High Performance**: Multi-threaded rendering with efficient memory usage

## Installation

```julia
using Pkg
Pkg.add("GeometricMedicalPhantoms")
```

## Quick Start

### Shepp-Logan Phantom

```julia
using GeometricMedicalPhantoms
using MIRTjim: jim

# Create a 2D Shepp-Logan phantom
phantom = create_shepp_logan_phantom(256, 256, :axial)
jim(phantom; title="Shepp-Logan Phantom")
```

### Torso Phantom with Motion

```julia
# Generate respiratory signal (10 seconds at 24 Hz)
fs = 24.0
duration = 10.0
resp_signal = range(1.2, 6.0, length=Int(fs*duration))

# Create 4D phantom with respiratory motion
phantom_4d = create_torso_phantom(128, 128, 128; 
    respiratory_signal=resp_signal)

# Shape: (128, 128, 128, 240) - spatial + temporal
```

### Tubes Phantom

```julia
# Create validation phantom with custom intensities
phantom = create_tubes_phantom(256, 256, 256;
    ti=TubesIntensities(
        outer_cylinder=0.3,
        tube_fillings=[0.2, 0.4, 0.6, 0.8, 1.0]
    ))
```

## Documentation

For comprehensive guides, API reference, and advanced examples, see the [full documentation](https://hakkelt.github.io/GeometricMedicalPhantoms.jl/stable/).

## Citation

If you use this package in your research, please cite:

```bibtex
@software{geometricmedicalphantoms2024,
  author = {Hakkelt, Tibor},
  title = {GeometricMedicalPhantoms.jl: Digital Phantoms for Medical Imaging},
  year = {2024},
  url = {https://github.com/hakkelt/GeometricMedicalPhantoms.jl}
}
```

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.

[aqua-img]: https://img.shields.io/badge/Aqua.jl-%F0%9F%8C%A2-aqua.svg
[aqua-url]: https://github.com/JuliaTesting/Aqua.jl
[ci-img]: https://github.com/hakkelt/GeometricMedicalPhantoms.jl/actions/workflows/CI.yml/badge.svg?branch=master
[ci-url]: https://github.com/hakkelt/GeometricMedicalPhantoms.jl/actions/workflows/CI.yml?query=branch%3Amaster
[codecov-img]: https://codecov.io/gh/hakkelt/GeometricMedicalPhantoms.jl/branch/master/graph/badge.svg
[codecov-url]: https://codecov.io/gh/hakkelt/GeometricMedicalPhantoms.jl
[docs-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-url]: https://hakkelt.github.io/GeometricMedicalPhantoms.jl/stable/
[jet-img]: https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-233f9a
[jet-url]: https://github.com/aviatesk/JET.jl
[license-img]: https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat
[license-url]: LICENSE
[runic-img]: https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black
[runic-url]: https://github.com/fredrikekre/Runic.jl
