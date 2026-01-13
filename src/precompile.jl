using PrecompileTools

@compile_workload begin
    # Physiological signal generation
    # Keep durations short (1.0 second) for fast precompilation
    generate_respiratory_signal(1.0, 100.0, 15.0)
    generate_cardiac_signals(1.0, 500.0, 70.0)

    # 2D phantom creation - Float32 (default)
    # Test different orientations with small dimensions
    create_torso_phantom(128, 128, :axial)
    create_torso_phantom(128, 128, :coronal)
    create_torso_phantom(128, 128, :sagittal)

    # 2D phantom creation - Float64
    create_torso_phantom(128, 128, :axial; eltype=Float64)

    # 2D phantom creation - ComplexF32
    create_torso_phantom(128, 128, :axial; eltype=ComplexF32)

    # 2D phantom creation - ComplexF64
    create_torso_phantom(128, 128, :axial; eltype=ComplexF64)

    # 3D phantom creation - Float32 (default)
    # Keep dimensions small (64^3) for fast precompilation
    create_torso_phantom(64, 64, 64)

    # 3D phantom creation - Float64
    create_torso_phantom(64, 64, 64; eltype=Float64)

    # 3D phantom creation - ComplexF32
    create_torso_phantom(64, 64, 64; eltype=ComplexF32)

    # 3D phantom creation - ComplexF64
    create_torso_phantom(64, 64, 64; eltype=ComplexF64)
end
