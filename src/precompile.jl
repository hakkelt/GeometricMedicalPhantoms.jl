using PrecompileTools

@compile_workload begin
    # Physiological signal generation
    # Keep durations short (1.0 second) for fast precompilation
    generate_respiratory_signal(1.0, 10.0, 15.0)
    generate_cardiac_signals(1.0, 10.0, 70.0)

    # 2D phantom creation - Float32 (default)
    # Test different orientations with small dimensions
    create_torso_phantom(64, 64, :axial)
    create_torso_phantom(64, 64, :coronal)
    create_torso_phantom(64, 64, :sagittal)

    # 2D phantom creation - Float64
    create_torso_phantom(64, 64, :axial; eltype=Float64)

    # 2D phantom creation - ComplexF32
    create_torso_phantom(64, 64, :axial; eltype=ComplexF32)

    # 2D phantom creation - ComplexF64
    create_torso_phantom(64, 64, :axial; eltype=ComplexF64)

    # 3D phantom creation - Float32 (default)
    # Keep dimensions small (64^3) for fast precompilation
    create_torso_phantom(64, 64, 64)

    # 3D phantom creation - Float64
    create_torso_phantom(64, 64, 64; eltype=Float64)

    # 3D phantom creation - ComplexF32
    create_torso_phantom(64, 64, 64; eltype=ComplexF32)

    # 3D phantom creation - ComplexF64
    create_torso_phantom(64, 64, 64; eltype=ComplexF64)

    # Shepp-Logan phantom generation
    # 2D phantom creation - Float32 (default) with different orientations
    create_shepp_logan_phantom(64, 64, :axial)
    create_shepp_logan_phantom(64, 64, :coronal)
    create_shepp_logan_phantom(64, 64, :sagittal)

    # 2D phantom creation - Float32 with custom FOV
    create_shepp_logan_phantom(64, 64, :axial; fovs=(20.0, 20.0))

    # 2D phantom creation - Float32 with MRI intensities
    create_shepp_logan_phantom(64, 64, :axial; ti=MRISheppLoganIntensities())

    # 2D phantom creation - Float32 with CT intensities
    create_shepp_logan_phantom(64, 64, :axial; ti=CTSheppLoganIntensities())

    # 2D phantom creation - Float32 with masking
    create_shepp_logan_phantom(64, 64, :axial; ti=SheppLoganMask(skull=true))

    # 2D phantom creation - Float64
    create_shepp_logan_phantom(64, 64, :axial; eltype=Float64)

    # 2D phantom creation - ComplexF32
    create_shepp_logan_phantom(64, 64, :axial; eltype=ComplexF32)

    # 2D phantom creation - ComplexF64
    create_shepp_logan_phantom(64, 64, :axial; eltype=ComplexF64)

    # 3D phantom creation - Float32 (default)
    create_shepp_logan_phantom(64, 64, 64)

    # 3D phantom creation - Float32 with custom FOV
    create_shepp_logan_phantom(64, 64, 64; fovs=(20.0, 20.0, 20.0))

    # 3D phantom creation - Float32 with MRI intensities
    create_shepp_logan_phantom(64, 64, 64; ti=MRISheppLoganIntensities())

    # 3D phantom creation - Float32 with CT intensities
    create_shepp_logan_phantom(64, 64, 64; ti=CTSheppLoganIntensities())

    # 3D phantom creation - Float32 with masking
    create_shepp_logan_phantom(64, 64, 64; ti=SheppLoganMask(brain=true))

    # 3D phantom creation - Float64
    create_shepp_logan_phantom(64, 64, 64; eltype=Float64)

    # 3D phantom creation - ComplexF32
    create_shepp_logan_phantom(64, 64, 64; eltype=ComplexF32)

    # 3D phantom creation - ComplexF64
    create_shepp_logan_phantom(64, 64, 64; eltype=ComplexF64)
end
