# API Reference

Complete reference for all public functions and types in GeometricMedicalPhantoms.

## Shepp-Logan Phantom

Everything related to the Shepp-Logan phantom.

```@docs
create_shepp_logan_phantom
CTSheppLoganIntensities
MRISheppLoganIntensities
SheppLoganIntensities
SheppLoganMask
```

## Torso Phantom

Everything related to the Torso phantom, including physiological motion.

```@docs
create_torso_phantom
TissueIntensities
TissueMask
RespiratoryPhysiology
generate_respiratory_signal
CardiacPhysiology
generate_cardiac_signals
```

## Tubes Phantom

Everything related to the Tubes phantom.

```@docs
create_tubes_phantom
TubesGeometry
TubesIntensities
TubesMask
```

## Geometric Primitives

Building blocks for custom phantoms.

### Ellipsoids
```@docs
Ellipsoid
SuperEllipsoid
RotatedEllipsoid
```

### Cylinders
```@docs
CylinderX
CylinderY
CylinderZ
```
