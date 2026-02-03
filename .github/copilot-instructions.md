# Copilot Instructions for GeometricMedicalPhantoms.jl

This is a Julia package for creating geometric medical phantoms used in medical imaging simulations. The package provides tools for generating various phantom types including Shepp-Logan, torso phantoms, and tubes phantoms, along with physiological signal generation capabilities.

## Code Standards

### Julia Best Practices
- Follow Julia naming conventions: lowercase with underscores for functions, CamelCase for types
- Write type-stable code to ensure good performance
- Use multiple dispatch effectively for different geometry types
- Prefer immutable structs when possible
- Document public APIs with docstrings
- Keep functions focused and composable

### Testing Requirements
- Write comprehensive tests for all new functionality
- Use `@testset` to organize related tests
- Follow the existing test structure in the `test/` directory
- Tests should be deterministic and reproducible
- Include edge cases and boundary conditions
- Run quality assurance tests (Aqua.jl and JET.jl) to ensure code quality and type stability

## Development Workflow

### Building and Testing
- **Install dependencies**: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
- **Run tests**: `julia --project=test -e 'using Pkg; Pkg.test()'`
- **Run specific test file**: `julia --project=test test/runtests.jl` or individual test files
- **Test with coverage**: Tests automatically generate coverage via CI

### Package Structure
- `src/`: Source code organized by functionality
  - `geometries/`: Geometric primitives (ellipsoids, cylinders, superellipsoids)
  - `physiological_signals/`: Signal generation for cardiac and respiratory motion
  - `shepp_logan/`: Shepp-Logan phantom implementation
  - `torso_phantom/`: Torso phantom with anatomical structures
  - `tubes_phantom/`: Tubes phantom implementation
  - `precompile.jl`: Precompilation directives for faster loading
- `test/`: Comprehensive test suite with unit tests and quality assurance tests
- `benchmark/`: Performance benchmarks
- `Project.toml`: Package dependencies and metadata

### Key Design Patterns
- Geometry types are immutable structs that define phantom elements
- `draw!` function mutates arrays in-place for memory efficiency
- Multi-threading is used for performance (via `Base.Threads`)
- Separate intensity and mask structs for different phantom representations

## Project-Specific Guidelines

1. **Geometry Types**: When adding new geometries, create immutable struct types and implement appropriate `draw!` methods
2. **Phantom Creation**: New phantom types should follow the pattern: geometry definitions, intensities, and creation functions
3. **Type Stability**: Always ensure type-stable code - run JET.jl tests to verify
4. **Thread Safety**: Be aware of multi-threading in `draw!` functions
5. **Memory Efficiency**: Use in-place operations where possible to minimize allocations
6. **Documentation**: Update README.md when adding new phantom types or significant features
7. **Version Compatibility**: Support Julia 1.10+ as specified in Project.toml

## Common Tasks

### Adding a New Phantom Type
1. Create a new directory under `src/` (e.g., `src/new_phantom/`)
2. Define geometry structs and intensity structs
3. Implement creation functions following existing patterns
4. Add corresponding tests in `test/`
5. Export public API in `src/GeometricMedicalPhantoms.jl`
6. Update documentation

### Adding a New Geometry
1. Add geometry struct in `src/geometries/`
2. Implement `draw!` method for the geometry
3. Add unit tests in `test/`
4. Export the type in `src/GeometricMedicalPhantoms.jl`

### Performance Considerations
- Profile code before optimizing
- Use `@inbounds` carefully and only when bounds are guaranteed
- Consider memory layout and cache efficiency
- Leverage Julia's type inference system
- Use multi-threading for independent operations on large arrays
