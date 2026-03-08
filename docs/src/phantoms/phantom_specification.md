# Torso Phantom Technical Specification

This document provides a detailed mathematical specification of the default Torso Phantom implementation.

## 1. Geometric Primitives

The phantom involves two primary geometric primitives:

**Superellipsoid** defined by:
```math
\left( \left| \frac{x - c_x}{R_x} \right|^{\epsilon_x} + \left| \frac{y - c_y}{R_y} \right|^{\epsilon_y} \right)^{\frac{\epsilon_z}{\epsilon_x}} + \left| \frac{z - c_z}{R_z} \right|^{\epsilon_z} \le 1
```

**Ellipsoid** (Special case of Superellipsoid with ``\epsilon = (2, 2, 2)``):
```math
\left( \frac{x - c_x}{R_x} \right)^2 + \left( \frac{y - c_y}{R_y} \right)^2 + \left( \frac{z - c_z}{R_z} \right)^2 \le 1
```

## 2. Default Tissue Parameters

The default `TissueIntensities` are:

| Tissue | Intensity Value |
|--------|----------------|
| lung | 0.08 |
| heart | 0.65 |
| vessels_blood | 1.00 |
| bones | 0.85 |
| liver | 0.55 |
| stomach | 0.90 |
| body | 0.25 |
| lv_blood | 0.98 |
| rv_blood | 0.99 |
| la_blood | 0.97 |
| ra_blood | 0.96 |

## 3. Rendering Order and Overlap Behavior

**CRITICAL:** The phantom is designed in a way that the order in which anatomical structures are drawn onto the phantom is essential. Later structures overwrite earlier ones at overlapping voxels.

### Rendering Algorithm

The phantom generation follows a two-phase rendering process:

1. **Static Phase:** Structures that do not change with respiratory or cardiac motion are drawn once and copied to all time frames for enhanced efficiency. This includes some parts of the torso shell, arms, and spine.
2. **Dynamic Phase:** For each time frame, motion-dependent structures are drawn on top of the static base image.
3. **Bone Overlay:** Bones are drawn last to ensure they appear on top of all soft tissue structures.

### Exact Drawing Order

**Phase 1: Static Structures (drawn once)**

| Order | Structure | Function | Description |
|-------|-----------|----------|-------------|
| 1 | Static Torso | `draw_torso_static_shapes!(ctx, ti)` | Neck (2 segments), shoulders, arms (left/right, 3 segments each), posterior back coverage (upper/mid/lower) |

**Phase 2: Dynamic Structures (drawn per frame)**

| Order | Structure | Function | Description | Motion Dependencies |
|-------|-----------|----------|-------------|---------------------|
| 2 | Dynamic Torso | `draw_torso_dynamic_parts!(ctx, ...)` | Chest (upper/mid/lower), abdomen (upper/lower) | Respiratory: ``S_{body}``, ``y_{offset}`` |
| 3 | Lungs | `draw_lungs!(ctx, ...)` | Left/right upper and lower lobes, diaphragm domes | Respiratory: scale, diaphragm displacement, ``R_{z,low}`` |
| 4 | Heart Background | `draw_heart_background!(ctx, ...)` | Pericardium/outer heart envelope | Cardiac: max chamber scales |
| 5 | Vessels | `draw_vessels!(ctx, ...)` | Aorta, pulmonary trunk + branches, superior vena cava | Static (no motion) |
| 6 | Heart Chambers | `draw_heart_chambers!(ctx, ...)` | LV/RV/LA/RA myocardium and blood cavities (20 components) | Cardiac: chamber scales, dynamic separation |
| 7 | Ribs | `draw_ribs!(ctx, ...)` | Rib cage with curvature | Respiratory: body scales |
| 8 | Stomach | `draw_stomach!(ctx, ...)` | Body and pyloric antrum | Respiratory: diaphragm displacement, visceral scaling |
| 9 | Liver | `draw_liver!(ctx, ...)` | Main lobe and right lobe | Respiratory: diaphragm displacement, visceral scaling |

**Phase 3: Bone Overlay (drawn last per frame)**

| Order | Structure | Function | Description |
|-------|-----------|----------|-------------|
| 10 | Arm Bones | `draw_arm_bones!(ctx, ...)` | Left and right humerus, radius, ulna segments |
| 11 | Spine | `draw_spine!(ctx, ...)` | Cervical, thoracic, and lumbar vertebrae with spinal curvature |

### Code Reference

The complete rendering sequence is implemented in:
- `src/torso_phantom/create_3D_torso_phantom.jl`: Main rendering loop
- `src/torso_phantom/motion_calculations.jl`: `calculate_motion_parameters(...)` computes per-frame motion parameters; `draw_dynamic_shapes!(ctx, ...)` orchestrates drawing all dynamic structures
- `src/torso_phantom/geometry_definitions.jl`: Individual `draw_*!()` functions for each anatomical structure (e.g. `draw_lungs!`, `draw_heart_chambers!`)

## 4. Static Structures

These structure do not deform with physiological motion.

### Body / Torso Shells (Static)

| Component | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| Neck 1 | 0.0 | 0.165 | 0.85 | 0.312 | 0.336 | 0.264 | (2.5, 2.5, 2.5) | Body |
| Neck 2 | 0.0 | 0.165 | 1.00 | 0.312 | 0.312 | 0.18 | (2.5, 2.5, 2.5) | Body |
| Shoulders | 0.0 | 0.165 | 0.70 | 0.8 | 0.28 | 0.25 | (2.5, 2.5, 2.5) | Body |
| Spine (Upper) | 0.0 | 0.28 | 0.35 | 0.70 | 0.43 | 0.50 | (2.5, 2.5, 2.5) | Body |
| Spine (Mid) | 0.0 | 0.28 | -0.10 | 0.75 | 0.47 | 0.55 | (2.5, 2.5, 2.5) | Body |
| Spine (Lower)| 0.0 | 0.15 | -0.60 | 0.78 | 0.48 | 0.55 | (2.5, 2.5, 2.5) | Body |

### Arms

| Component | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| L Arm (Up) | -0.68 | 0.165 | 0.62 | 0.18 | 0.18 | 0.28 | (2.5, 2.5, 2.5) | Body |
| L Arm (Mid)| -0.88 | 0.165 | 0.50 | 0.17 | 0.17 | 0.26 | (2.5, 2.5, 2.5) | Body |
| L Arm (Low)| -1.05 | 0.165 | 0.38 | 0.16 | 0.16 | 0.24 | (2.5, 2.5, 2.5) | Body |
| R Arm (Up) | 0.68 | 0.165 | 0.62 | 0.18 | 0.18 | 0.28 | (2.5, 2.5, 2.5) | Body |
| R Arm (Mid)| 0.88 | 0.165 | 0.50 | 0.17 | 0.17 | 0.26 | (2.5, 2.5, 2.5) | Body |
| R Arm (Low)| 1.05 | 0.165 | 0.38 | 0.16 | 0.16 | 0.24 | (2.5, 2.5, 2.5) | Body |

## 5. Dynamic Motion Model

### Respiratory Parameters

Given respiratory signal ``S_{resp}`` (Liters), default range [1.2, 6.0].
Normalized signal ``\hat{r}``:
```math
\hat{r} = \frac{S_{resp} - 1.2}{6.0 - 1.2}
```

Polynomial Coefficients:  
```math
\begin{aligned}
a &= (0.598, 0.842, -0.175, -0.0320625) \\
b &= (1.819140625, 0.831375, -1.7111875, 1.24575)
\end{aligned}
```

Global Scaling Factors:
```math
\begin{aligned}
S_{scale} &= a_0 + a_1\hat{r} + a_2\hat{r}^2 + a_3\hat{r}^3 \\
S_{lower\_rz} &= b_0 + b_1\hat{r} + b_2\hat{r}^2 + b_3\hat{r}^3
\end{aligned}
```

Derived Parameters:
```math
\begin{aligned}
S_{body} &= 0.4 + 0.63 \cdot S_{scale} \\
y_{offset} &= -0.40 + S_{body} \cdot 0.45 \\
\Delta z_{dia} &= -0.5 \cdot (S_{lower\_rz} - 1.0) \\
S_{dia} &= S_{lower\_rz}
\end{aligned}
```

### Dynamic Torso Shells (Main Body)

| Component | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| Chest (Upper) | 0.0 | ``-y_{offset}`` | 0.45 | ``0.86 S_{body}`` | ``0.69 S_{body}`` | 0.35 | (2.5, 2.5, 2.5) | Body |
| Chest (Mid) | 0.0 | ``-y_{offset}`` | 0.17 | ``0.93 S_{body}`` | ``0.72 S_{body}`` | 0.32 | (2.5, 2.5, 3.5) | Body |
| Chest (Lower) | 0.0 | ``-y_{offset}`` | -0.11 | ``0.91 S_{body}`` | ``0.71 S_{body}`` | 0.32 | (2.5, 2.5, 3.5) | Body |
| Abd (Upper) | 0.0 | ``-y_{offset}`` | -0.45 | ``0.87 S_{body}`` | ``0.67 S_{body}`` | 0.40 | (2.5, 2.5, 3.5) | Body |
| Abd (Lower) | 0.0 | ``-y_{offset}`` | -0.85 | ``0.83 \sqrt{S_{body}}`` | ``0.62 \sqrt{S_{body}}`` | 0.45 | (2.5, 2.5, 3.5) | Body |

### Lungs

**Constants:**
```math
\begin{aligned}
x_{off} &= 0.32 \text{(Lung Center Offset)} \\
R_{top} &= 0.25 + 0.22 S_{scale} \\
R_{low} &= 0.430 S_{scale} \\
R_{z,low} &= 0.480 S_{lower\_rz}
\end{aligned}
```

| Component | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| L Upper | ``-(x_{off}-0.1)`` | ``-y_{offset}`` | ``-0.1 - 0.5 \Delta z_{dia}`` | ``R_{top}`` | ``R_{low}`` | 0.70 | (2, 2, 1.2) | Lung |
| L Lower | ``-x_{off}`` | ``-y_{offset}`` | ``-0.17 + 0.5 \Delta z_{dia}`` | ``R_{low}`` | ``R_{low}`` | ``R_{z,low}`` | (2, 2, 2.5) | Lung |
| R Upper | ``x_{off} - 0.1`` | ``-y_{offset}`` | ``-0.1 - 0.5 \Delta z_{dia}`` | ``R_{top}`` | ``R_{low}`` | 0.70 | (2, 2, 1.2) | Lung |
| R Lower | ``x_{off}`` | ``-y_{offset}`` | ``-0.17 + 0.5 \Delta z_{dia}`` | ``R_{low}`` | ``R_{low}`` | ``R_{z,low}`` | (2, 2, 2.5) | Lung |
| L Diaphragm | ``-x_{off}`` | ``-y_{offset}`` | ``-0.50 + \Delta z_{dia}`` | ``R_{low}`` | ``R_{low}`` | 0.40 | (2.5, 2.5, 1.5) | Body |
| R Diaphragm | ``x_{off}`` | ``-y_{offset}`` | ``-0.50 + \Delta z_{dia}`` | ``R_{low}`` | ``R_{low}`` | 0.40 | (2.5, 2.5, 1.5) | Body |

## 6. Heart

### Motion Parameters

Given chamber scales ``s_{LV}, s_{RV}, s_{LA}, s_{RA}``:

Corrected cavity scales:
```math
s'_{LV} = 1.10 s_{LV}, \quad s'_{RV} = 1.06 s_{RV}, \quad s'_{LA} = 0.95 s_{LA}, \quad s'_{RA} = 1.00 s_{RA}
```

Displacements:
```math
\begin{aligned}
dx_{LV} &= 0.45 \cdot 0.251 \cdot (s_{LV} - 1.0) \\
dx_{RV} &= 0.45 \cdot 0.209 \cdot (s_{RV} - 1.0) \\
dx_{LA} &= 0.15048 \cdot (s_{LA} - 1.0) \\
dx_{RA} &= 0.15048 \cdot (s_{RA} - 1.0) \\
dz_{LV} &= 0.209(s_{LV}-1), \quad dz_{LA} = 0.188(s_{LA}-1) \\
dz_{RV} &= 0.195(s_{RV}-1), \quad dz_{RA} = 0.188(s_{RA}-1) \\
z_{sep, L} &= 0.9(dz_{LV} + dz_{LA}) \\
z_{sep, R} &= 0.9(dz_{RV} + dz_{RA})
\end{aligned}
```
Constants: ``z_{off} = 0.2``.

### Heart Components Table

The heart is composed of 20 ellipsoids/superellipsoids.

Tuning parameters used in the cavity definitions:
```math
\begin{aligned}
\text{myocardium\_bottom\_z\_scale} &= 1.2 \\
\text{lv\_rad\_offset} &= 0.006 \\
\text{rv\_rad\_offset} &= 0.004, \\
\text{la\_rad\_offset} &= -0.001 \\
\text{ra\_rad\_offset} &= 0.0005 \\
\text{lv\_c\_base\_factor} &= 1.02 \\
\text{rv\_c\_base\_factor} &= 0.98
\end{aligned}
```

Define cavity scales ``s_{LV,c}, s_{RV,c}, s_{LA,c}, s_{RA,c}`` as:
```math
s_{LV,c} = 1.10 s_{LV},\quad s_{RV,c} = 1.06 s_{RV},\quad s_{LA,c} = 0.95 s_{LA},\quad s_{RA,c} = 1.00 s_{RA}
```

| Component | Type | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|------|-------|-------|-------|-------|-------|-------|-----------|-----------|
| LV outer myocardium (base) | Ellipsoid | ``-0.06-dx_{LV}`` | ``0.02-y_{offset}`` | ``-0.1+z_{off}`` | ``0.1595 s_{LV}`` | ``0.2145 s_{LV}`` | ``0.242 s_{LV}`` | ``(2,2,2)`` | heart |
| RV outer myocardium (base) | Ellipsoid | ``0.14+dx_{RV}`` | ``0.0-y_{offset}`` | ``-0.1+z_{off}`` | ``0.1595 s_{RV}`` | ``0.2145 s_{RV}`` | ``0.242 s_{RV}`` | ``(2,2,2)`` | heart |
| LV outer myocardium (mid) | Superellipsoid | ``-0.06-dx_{LV}`` | ``0.02-y_{offset}`` | ``0.0+z_{off}`` | ``0.1485 s_{LV}`` | ``0.2035 s_{LV}`` | ``0.1782 s_{LV}`` | ``(2.5,2.5,2.5)`` | heart |
| RV outer myocardium (mid) | Superellipsoid | ``0.14+dx_{RV}`` | ``0.0-y_{offset}`` | ``0.0+z_{off}`` | ``0.1485 s_{RV}`` | ``0.2035 s_{RV}`` | ``0.1782 s_{RV}`` | ``(2.5,2.5,2.5)`` | heart |
| LV myocardium (base) | Superellipsoid | ``-0.063-dx_{LV}`` | ``0.02-y_{offset}`` | ``(0.0+z_{off})-z_{sep,L}`` | ``0.251 s_{LV}`` | ``0.251 s_{LV}`` | ``(0.209 s_{LV})\,\text{myocardium\_bottom\_z\_scale}`` | ``(2,2,2)`` | heart |
| LV myocardium (mid) | Superellipsoid | ``-0.063-dx_{LV}`` | ``0.02-y_{offset}`` | ``(0.08+z_{off})-z_{sep,L}`` | ``0.195 s_{LV}`` | ``0.195 s_{LV}`` | ``0.157 s_{LV}`` | ``(3,3,2)`` | heart |
| LV cavity (base) | Superellipsoid | ``-0.06-dx_{LV}`` | ``0.02-y_{offset}`` | ``(-0.1+z_{off})-z_{sep,L}`` | ``(0.112125 s_{LV,c}+\text{lv\_rad\_offset})\,\text{lv\_c\_base\_factor}`` | ``(0.160875 s_{LV,c}+\text{lv\_rad\_offset})\,\text{lv\_c\_base\_factor}`` | ``(0.156 s_{LV,c})\,\text{lv\_c\_base\_factor}`` | ``(2,2,2)`` | lv_blood |
| LV cavity (mid A) | Superellipsoid | ``-0.06-dx_{LV}`` | ``0.02-y_{offset}`` | ``(0.0+z_{off})-z_{sep,L}`` | ``0.102375 s_{LV,c}+\text{lv\_rad\_offset}`` | ``0.151125 s_{LV,c}+\text{lv\_rad\_offset}`` | ``0.1404 s_{LV,c}`` | ``(2.5,2.5,2.5)`` | lv_blood |
| LV cavity (mid B) | Superellipsoid | ``-0.06-dx_{LV}`` | ``0.02-y_{offset}`` | ``(0.0+z_{off})-z_{sep,L}`` | ``0.193288 s_{LV,c}`` | ``0.193288 s_{LV,c}`` | ``0.14366 s_{LV,c}`` | ``(2,2,2)`` | lv_blood |
| LV cavity (apex) | Superellipsoid | ``-0.06-dx_{LV}`` | ``0.02-y_{offset}`` | ``(0.04+z_{off})-z_{sep,L}`` | ``0.151496 s_{LV,c}`` | ``0.151496 s_{LV,c}`` | ``0.094032 s_{LV,c}`` | ``(3,3,2)`` | lv_blood |
| RV myocardium (base) | Superellipsoid | ``0.143+dx_{RV}`` | ``0.0-y_{offset}`` | ``(0.0+z_{off})-z_{sep,R}`` | ``0.209 s_{RV}`` | ``0.209 s_{RV}`` | ``(0.195 s_{RV})\,\text{myocardium\_bottom\_z\_scale}`` | ``(2,2,2)`` | heart |
| RV myocardium (mid) | Superellipsoid | ``0.143+dx_{RV}`` | ``0.0-y_{offset}`` | ``(0.08+z_{off})-z_{sep,R}`` | ``0.167 s_{RV}`` | ``0.167 s_{RV}`` | ``0.136 s_{RV}`` | ``(3,3,2)`` | heart |
| RV cavity (base) | Superellipsoid | ``0.14+dx_{RV}`` | ``0.0-y_{offset}`` | ``(-0.1+z_{off})-z_{sep,R}`` | ``(0.11822 s_{RV,c}+\text{rv\_rad\_offset})\,\text{rv\_c\_base\_factor}`` | ``(0.16962 s_{RV,c}+\text{rv\_rad\_offset})\,\text{rv\_c\_base\_factor}`` | ``(0.16448 s_{RV,c})\,\text{rv\_c\_base\_factor}`` | ``(2,2,2)`` | rv_blood |
| RV cavity (mid A) | Superellipsoid | ``0.14+dx_{RV}`` | ``0.0-y_{offset}`` | ``(0.0+z_{off})-z_{sep,R}`` | ``0.10794 s_{RV,c}+\text{rv\_rad\_offset}`` | ``0.15934 s_{RV,c}+\text{rv\_rad\_offset}`` | ``0.148032 s_{RV,c}`` | ``(2.5,2.5,2.5)`` | rv_blood |
| RV cavity (mid B) | Superellipsoid | ``0.14+dx_{RV}`` | ``0.0-y_{offset}`` | ``(0.0+z_{off})-z_{sep,R}`` | ``0.172112 s_{RV,c}`` | ``0.172112 s_{RV,c}`` | ``0.133248 s_{RV,c}`` | ``(2,2,2)`` | rv_blood |
| RV cavity (apex) | Superellipsoid | ``0.14+dx_{RV}`` | ``0.0-y_{offset}`` | ``(0.04+z_{off})-z_{sep,R}`` | ``0.1388 s_{RV,c}`` | ``0.1388 s_{RV,c}`` | ``0.094384 s_{RV,c}`` | ``(3,3,2)`` | rv_blood |
| LA myocardium | Superellipsoid | ``-0.101-dx_{LA}`` | ``-0.05-y_{offset}`` | ``(0.25+z_{off})+z_{sep,L}`` | ``0.15 s_{LA}`` | ``0.15 s_{LA}`` | ``0.188 s_{LA}`` | ``(2.2,2.2,2.2)`` | heart |
| LA cavity | Superellipsoid | ``-0.101`` | ``-0.05-y_{offset}`` | ``(0.25+z_{off})+z_{sep,L}`` | ``0.134352 s_{LA,c}+\text{la\_rad\_offset}`` | ``0.134352 s_{LA,c}+\text{la\_rad\_offset}`` | ``0.16794 s_{LA,c}`` | ``(2.2,2.2,2.2)`` | la_blood |
| RA myocardium | Superellipsoid | ``0.161+dx_{RA}`` | ``-0.07-y_{offset}`` | ``(0.25+z_{off})+z_{sep,R}`` | ``0.15 s_{RA}`` | ``0.15 s_{RA}`` | ``0.188 s_{RA}`` | ``(2.2,2.2,2.2)`` | heart |
| RA cavity | Superellipsoid | ``0.161`` | ``-0.07-y_{offset}`` | ``(0.25+z_{off})+z_{sep,R}`` | ``0.126468 s_{RA,c}+\text{ra\_rad\_offset}`` | ``0.126468 s_{RA,c}+\text{ra\_rad\_offset}`` | ``0.158085 s_{RA,c}`` | ``(2.2,2.2,2.2)`` | ra_blood |

## 7. Abdominal Organs

### Liver

The liver is positioned in the left upper abdomen and moves with diaphragm motion. It consists of two lobes with respiratory-dependent positioning.

**Constants:**
- Moves with: ``\Delta z_{dia}`` (diaphragm vertical displacement)
- Size scaling: ``xy_{scale}`` (respiratory-dependent transverse scaling)

| Component | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| Main Lobe | -0.3 | ``-0.15 - y_{offset}`` | ``-0.55 + \Delta z_{dia}`` | ``0.385 \cdot xy_{scale}`` | ``0.33 \cdot xy_{scale}`` | 0.3 | (2.5, 2.5, 2.5) | Liver |
| Right Lobe | -0.05 | ``-0.12 - y_{offset}`` | ``-0.5 + \Delta z_{dia}`` | ``0.35 \cdot xy_{scale}`` | ``0.275 \cdot xy_{scale}`` | 0.25 | (1.5, 2.5, 2.5) | Liver |

### Stomach

The stomach is positioned in the right upper abdomen and moves with diaphragm motion. It consists of the body and pyloric antrum.

| Component | ``c_x`` | ``c_y`` | ``c_z`` | ``R_x`` | ``R_y`` | ``R_z`` | ``\epsilon`` | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| Body | 0.45 | ``0.0 - y_{offset}`` | ``-0.55 + \Delta z_{dia}`` | ``0.176 \cdot xy_{scale}`` | ``0.176 \cdot xy_{scale}`` | 0.3 | (2.5, 2.5, 2.5) | Stomach |
| Pyloric Antrum | 0.25 | ``-0.02 - y_{offset}`` | ``-0.65 + \Delta z_{dia}`` | ``0.12 \cdot xy_{scale}`` | ``0.115 \cdot xy_{scale}`` | 0.16 | (2.5, 2.5, 2.5) | Stomach |

## 8. Major Vessels

Major blood vessels are modeled as curved tubular structures using superellipsoids positioned along parameterized centerlines. All vessel structures use static positioning (no cardiac or respiratory motion).

### Vessel Centerline Functions

Vessels follow 3D curved paths defined by sinusoidal functions to simulate anatomical curvature:

**Aorta (Ascending):**
```math
\begin{aligned}
x_{aorta}(z) &= -0.08 + 0.03 \sin(\pi (z - 0.2)) \\
y_{aorta}(z) &= -0.05 + 0.035 \sin(0.7\pi (z - 0.2) + 0.4)
\end{aligned}
```

**Pulmonary Trunk:**
```math
\begin{aligned}
x_{pulm}(z) &= -0.05 + 0.02 \sin(\pi (z - 0.22) + 0.2) \\
y_{pulm}(z) &= -0.05 + 0.03 \sin(0.9\pi (z - 0.22) - 0.3)
\end{aligned}
```

**Superior Vena Cava:**
```math
\begin{aligned}
x_{svc}(z) &= 0.1 + 0.05 \sin(0.8\pi (z - 0.3)) \\
y_{svc}(z) &= -0.05 + 0.03 \sin(0.6\pi (z - 0.3) + 0.2)
\end{aligned}
```

**Constants:** ``z_{offset} = 0.2`` (vertical offset for vessel centerlines)

### Aorta (Ascending)

The aorta is composed of superellipsoid segments along its curved centerline. Radius: 0.04.

| Segment | ``z_{center}`` | Height ``R_z`` | Notes |
|---------|--------------|--------------|-------|
| 1 | 1.0 | 0.08 | Upper thoracic |
| 2 | 0.95 | 0.08 | |
| 3 | 0.9 | 0.08 | |
| 4 | 0.75 | 0.12 | Aortic arch region |
| 5 | 0.6 | 0.12 | |
| 6 | 0.45 | 0.12 | |
| 7 | 0.32 | 0.1 | Descending (heart base) |

### Pulmonary Arteries

The pulmonary circulation consists of a main trunk that bifurcates into left and right branches extending laterally toward the lungs.

**Main Pulmonary Trunk:**

| Segment | ``z_{center}`` | Height ``R_z`` | Radius ``R_x, R_y`` |
|---------|--------------|--------------|-------------------|
| 1 | 0.34 | 0.12 | 0.05 |
| 2 | 0.3 | 0.1 | 0.05 |

**Left Pulmonary Branch:**

The left branch follows a curved arc trajectory (rising then leveling to horizontal) extending from the bifurcation at ``(x, y, z) = (-0.05, -0.05, 0.48 + z_{offset})`` to the left lung at ``(-0.31, -0.01, 0.59 + z_{offset})``.

| Segment | ``z`` (rel) | ``c_x`` | ``c_y`` | ``R_{xy}`` | ``R_z`` |
|---------|-----------|-------|-------|----------|-------|
| 1 | 0.48 | -0.05 | ``-0.05 - y_{offset}`` | 0.045 | 0.06 |
| 2 | 0.53 | -0.09 | ``-0.04 - y_{offset}`` | 0.043 | 0.06 |
| 3 | 0.57 | -0.14 | ``-0.035 - y_{offset}`` | 0.041 | 0.06 |
| 4 | 0.60 | -0.19 | ``-0.03 - y_{offset}`` | 0.039 | 0.06 |
| 5 | 0.61 | -0.23 | ``-0.025 - y_{offset}`` | 0.037 | 0.06 |
| 6 | 0.61 | -0.26 | ``-0.02 - y_{offset}`` | 0.035 | 0.06 |
| 7 | 0.60 | -0.29 | ``-0.015 - y_{offset}`` | 0.033 | 0.06 |
| 8 | 0.59 | -0.31 | ``-0.01 - y_{offset}`` | 0.031 | 0.06 |

**Right Pulmonary Branch:**

The right branch mirrors the left branch trajectory, extending from ``(0.0, -0.05, 0.48 + z_{offset})`` to the right lung at ``(0.26, -0.01, 0.59 + z_{offset})``.

| Segment | ``z`` (rel) | ``c_x`` | ``c_y`` | ``R_{xy}`` | ``R_z`` |
|---------|-----------|-------|-------|----------|-------|
| 1 | 0.48 | 0.00 | ``-0.05 - y_{offset}`` | 0.045 | 0.06 |
| 2 | 0.53 | 0.04 | ``-0.04 - y_{offset}`` | 0.043 | 0.06 |
| 3 | 0.57 | 0.09 | ``-0.035 - y_{offset}`` | 0.041 | 0.06 |
| 4 | 0.60 | 0.14 | ``-0.03 - y_{offset}`` | 0.039 | 0.06 |
| 5 | 0.61 | 0.18 | ``-0.025 - y_{offset}`` | 0.037 | 0.06 |
| 6 | 0.61 | 0.21 | ``-0.02 - y_{offset}`` | 0.035 | 0.06 |
| 7 | 0.60 | 0.24 | ``-0.015 - y_{offset}`` | 0.033 | 0.06 |
| 8 | 0.59 | 0.26 | ``-0.01 - y_{offset}`` | 0.031 | 0.06 |

All pulmonary branch segments use ``\epsilon = (2.5, 2.5, 2.5)``. The z-coordinates show an arc pattern: initially rising (0.48→0.61), then leveling and slightly descending (0.61→0.59), creating a curved trajectory that converges toward horizontal as the branches extend laterally to the lungs.

### Superior Vena Cava

The superior vena cava extends from the upper thorax to the right atrium. Radius: 0.04.

| Segment | ``z_{center}`` | Height ``R_z`` | Notes |
|---------|--------------|--------------|-------|
| 1 | 1.0 | 0.08 | Upper thoracic |
| 2 | 0.95 | 0.08 | |
| 3 | 0.82 | 0.1 | |
| 4 | 0.68 | 0.12 | Mid thoracic |
| 5 | 0.55 | 0.12 | |
| 6 | 0.45 | 0.08 | Approaches right atrium |

All vessel segments use intensity value `vessels_blood` (1.00) and ``\epsilon = (2.5, 2.5, 2.5)`` for smooth, rounded tubular geometry.

## 9. Physiological Signal Generation

### Respiratory Signal

The default respiratory signal ``S_{resp}(t)`` (in Liters) is generated with a fundamental frequency ``f_{resp} = RR/60`` Hz.

1. **Phase Evolution** (with Rate Variability ``A_{rr}, f_{rr}``):
```math
\theta(t) = 2\pi f_{resp} t - \frac{f_{resp} A_{rr}}{f_{rr}} (\cos(2\pi f_{rr} t) - 1)
```
2. **Base Waveform** (Asymmetric):
```math
W(t) = \sin(\theta(t)) + A_{asym} \sin(2\theta(t))
```
3. **Amplitude Modulation** (Depth Variability ``A_{am}, f_{am}``):
```math
\begin{aligned}
&M(t) = 1 + A_{am} \sin(2\pi f_{am} t) \\
&S_{raw}(t) = W(t) \cdot M(t)
\end{aligned}
```
4. **Normalization:**
```math
\begin{aligned}
S_{norm} &= \frac{S_{raw}(t) - \min(S_{raw})}{\max(S_{raw}) - \min(S_{raw})} \\
S_{resp}(t) &= physiology.minL .+ (physiology.maxL - physiology.minL) .* S_{norm}
\end{aligned}
```

where `physiology` refers to the respiratory signal generation parameters defined, defaulting to `minL = 1.2` and `maxL = 6.0` Liters. For more details, see [API Reference](../api.md).

### Cardiac Signals

The function `generate_cardiac_signals(duration, fs, HR; physiology=CardiacPhysiology())` generates chamber-volume time series for LV, RV, LA, and RA (mL).

Given sampling frequency ``f_s`` and duration ``D``, the time axis is:
```math
t_n = n/f_s, \quad n=0,1,\dots,\lfloor D f_s \rfloor-1
```

Heart rate and cycle period are:
```math
f_{HR} = HR/60, \qquad T = 1/f_{HR}
```

### Phase Model and Time-Varying Systole Fraction

To model mild beat-to-beat variability, the implementation uses a warped time variable:
```math
t_{var}(t) = t + A_{HR}\sin(2\pi f_{HR,var} t)
```
where ``A_{HR} = physiology.hr\_var\_amp`` and ``f_{HR,var} = physiology.hr\_var\_freq``.

Phase is then:
```math
\phi(t) = (t_{var}(t) \bmod T)/T \in [0,1)
```

Systole fraction is not constant; it oscillates around ``s\_frac\_base``:
```math
\gamma(t) = s_{frac,base}\left(1 + 0.08\sin(2\pi\cdot0.1\,t)\right)
```
with ``s_{frac,base} = physiology.s\_frac\_base`` (default 0.35).

Normalized coordinates in each phase are:
```math
x_s = \mathrm{clamp}(\phi/\gamma,\,0,1), \qquad
x_d = \mathrm{clamp}((\phi-\gamma)/(1-\gamma),\,0,1)
```

### Ventricular Volumes (LV, RV)

Define stroke ranges:
```math
\Delta V_{LV} = V_{LV,ED} - V_{LV,ES}, \qquad
\Delta V_{RV} = V_{RV,ED} - V_{RV,ES}
```

**Systole (ejection, both ventricles):**
```math
V_{LV,s} = V_{LV,ED} - \Delta V_{LV}\left(1-(1-x_s)^3\right)
```
```math
V_{RV,s} = V_{RV,ED} - \Delta V_{RV}\left(1-(1-x_s)^3\right)
```

**Diastole (passive filling + late atrial kick):**
```math
V_{LV,d} = V_{LV,ES} + \Delta V_{LV}x_d^{2.2}
+ A_{LV,kick}\,\Delta V_{LV}\exp\!\left[-\left(\frac{x_d-\mu_{LV,kick}}{\sigma_{LV,kick}}\right)^2\right]
```
```math
V_{RV,d} = V_{RV,ES} + \Delta V_{RV}x_d^{2.0}
+ A_{RV,kick}\,\Delta V_{RV}\exp\!\left[-\left(\frac{x_d-\mu_{RV,kick}}{\sigma_{RV,kick}}\right)^2\right]
```

with
``A_{LV,kick}=physiology.lv\_kick\_amp\_frac``,
``\mu_{LV,kick}=physiology.lv\_kick\_center``,
``\sigma_{LV,kick}=physiology.lv\_kick\_width``
and analogous RV parameters.

The final piecewise ventricular signals are:
```math
V_{LV}(t)=\begin{cases}
V_{LV,s}, & \phi < \gamma\\
V_{LV,d}, & \phi \ge \gamma
\end{cases},
\qquad
V_{RV}(t)=\begin{cases}
V_{RV,s}, & \phi < \gamma\\
V_{RV,d}, & \phi \ge \gamma
\end{cases}
```

### Atrial Volumes (LA, RA)

Define atrial ranges:
```math
\Delta V_{LA} = V_{LA,max} - V_{LA,min}, \qquad
\Delta V_{RA} = V_{RA,max} - V_{RA,min}
```

**Systole (atria filling while ventricles eject):**
```math
V_{LA,s} = V_{LA,min} + \Delta V_{LA}x_s^{1.5}, \qquad
V_{RA,s} = V_{RA,min} + \Delta V_{RA}x_s^{1.5}
```

**Diastole (atria emptying + contraction notch):**
```math
V_{LA,d} = V_{LA,max} - \Delta V_{LA}\left(1-(1-x_d)^3\right)
- A_{LA,contr}\,\Delta V_{LA}\exp\!\left[-\left(\frac{x_d-\mu_{LA,contr}}{\sigma_{LA,contr}}\right)^2\right]
```
```math
V_{RA,d} = V_{RA,max} - \Delta V_{RA}\left(1-(1-x_d)^3\right)
- A_{RA,contr}\,\Delta V_{RA}\exp\!\left[-\left(\frac{x_d-\mu_{RA,contr}}{\sigma_{RA,contr}}\right)^2\right]
```

with contraction parameters from
`la_contr_amp_frac`, `la_contr_center`, `la_contr_width` and
`ra_contr_amp_frac`, `ra_contr_center`, `ra_contr_width`.

Piecewise atrial signals are:
```math
V_{LA}(t)=\begin{cases}
V_{LA,s}, & \phi < \gamma\\
V_{LA,d}, & \phi \ge \gamma
\end{cases},
\qquad
V_{RA}(t)=\begin{cases}
V_{RA,s}, & \phi < \gamma\\
V_{RA,d}, & \phi \ge \gamma
\end{cases}
```

### Slow Modulation and Baseline Wander

After piecewise synthesis, slow modulations are applied:
```math
M_V(t)=1 + A_V\sin(2\pi f_V t), \qquad
M_A(t)=1 + A_A\sin(2\pi f_A t + 0.7)
```
```math
B(t)=A_{BW}\sin(2\pi f_{BW} t)
```
where
``A_V=physiology.v\_amp\_amp``, ``f_V=physiology.v\_amp\_freq``,
``A_A=physiology.a\_amp\_amp``, ``f_A=physiology.a\_amp\_freq``,
``A_{BW}=physiology.bw\_amp``, and ``f_{BW}=physiology.bw\_freq``.

Final output signals are:
```math
\widetilde V_{LV}=V_{LV}M_V + B, \qquad \widetilde V_{RV}=V_{RV}M_V + B
```
```math
\widetilde V_{LA}=V_{LA}M_A + 0.8B, \qquad \widetilde V_{RA}=V_{RA}M_A + 0.8B
```

The function returns ``(t, (lv=\widetilde V_{LV}, rv=\widetilde V_{RV}, la=\widetilde V_{LA}, ra=\widetilde V_{RA}))``.
