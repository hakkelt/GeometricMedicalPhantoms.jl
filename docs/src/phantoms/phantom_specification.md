# Torso Phantom Technical Specification

This document provides a detailed mathematical specification of the default Torso Phantom implementation.

## 1. Geometric Primitives

The phantom involves two primary geometric primitives:

**Superellipsoid** defined by:
```latex
\left( \left| \frac{x - c_x}{R_x} \right|^{\epsilon_x} + \left| \frac{y - c_y}{R_y} \right|^{\epsilon_y} \right)^{\frac{\epsilon_z}{\epsilon_x}} + \left| \frac{z - c_z}{R_z} \right|^{\epsilon_z} \le 1
```

**Ellipsoid** (Special case of Superellipsoid with $\epsilon = (2, 2, 2)$):
```latex
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

## 3. Static Structures

These structure do not deform with physiological motion.

### Body / Torso Shells (Static)

| Component | $c_x$ | $c_y$ | $c_z$ | $R_x$ | $R_y$ | $R_z$ | $\epsilon$ | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| Neck 1 | 0.0 | 0.165 | 0.85 | 0.312 | 0.336 | 0.264 | (2.5, 2.5, 2.5) | Body |
| Neck 2 | 0.0 | 0.165 | 1.00 | 0.312 | 0.312 | 0.18 | (2.5, 2.5, 2.5) | Body |
| Shoulders | 0.0 | 0.165 | 0.70 | 0.8 | 0.28 | 0.25 | (2.5, 2.5, 2.5) | Body |
| Spine (Upper) | 0.0 | 0.28 | 0.35 | 0.70 | 0.43 | 0.50 | (2.5, 2.5, 2.5) | Body |
| Spine (Mid) | 0.0 | 0.28 | -0.10 | 0.75 | 0.47 | 0.55 | (2.5, 2.5, 2.5) | Body |
| Spine (Lower)| 0.0 | 0.15 | -0.60 | 0.78 | 0.48 | 0.55 | (2.5, 2.5, 2.5) | Body |

### Arms

| Component | $c_x$ | $c_y$ | $c_z$ | $R_x$ | $R_y$ | $R_z$ | $\epsilon$ | Intensity |
|-----------|-------|-------|-------|-------|-------|-------|------------|-----------|
| L Arm (Up) | -0.68 | 0.165 | 0.62 | 0.18 | 0.18 | 0.28 | (2.5, 2.5, 2.5) | Body |
| L Arm (Mid)| -0.88 | 0.165 | 0.50 | 0.17 | 0.17 | 0.26 | (2.5, 2.5, 2.5) | Body |
| L Arm (Low)| -1.05 | 0.165 | 0.38 | 0.16 | 0.16 | 0.24 | (2.5, 2.5, 2.5) | Body |
| R Arm (Up) | 0.68 | 0.165 | 0.62 | 0.18 | 0.18 | 0.28 | (2.5, 2.5, 2.5) | Body |
| R Arm (Mid)| 0.88 | 0.165 | 0.50 | 0.17 | 0.17 | 0.26 | (2.5, 2.5, 2.5) | Body |
| R Arm (Low)| 1.05 | 0.165 | 0.38 | 0.16 | 0.16 | 0.24 | (2.5, 2.5, 2.5) | Body |

## 4. Dynamic Motion Model

### Respiratory Parameters

Given respiratory signal $S_{resp}$ (Liters), default range [1.2, 6.0].
Normalized signal $\hat{r}$:
```latex
\hat{r} = \frac{S_{resp} - 1.2}{6.0 - 1.2}
```

Polynomial Coefficients:
$a = (0.598, 0.842, -0.175, -0.0320625)$
$b = (1.819140625, 0.831375, -1.7111875, 1.24575)$

Global Scaling Factors:
```latex
S_{scale} = a_0 + a_1\hat{r} + a_2\hat{r}^2 + a_3\hat{r}^3
S_{lower\_rz} = b_0 + b_1\hat{r} + b_2\hat{r}^2 + b_3\hat{r}^3
```

Derived Parameters:
```latex
S_{body} = 0.4 + 0.63 \cdot S_{scale}
y_{offset} = -0.40 + S_{body} \cdot 0.45
\Delta z_{dia} = -0.5 \cdot (S_{lower\_rz} - 1.0)
S_{dia} = S_{lower\_rz}
```

### Dynamic Torso Shells (Main Body)

| Component | $c_x$ | $c_y$ | $c_z$ | $R_x$ | $R_y$ | $R_z$ | $\epsilon$ |
|-----------|-------|-------|-------|-------|-------|-------|------------|
| Chest (Upper) | 0.0 | $-y_{offset}$ | 0.45 | $0.86 S_{body}$ | $0.69 S_{body}$ | 0.35 | (2.5, 2.5, 2.5) |
| Chest (Mid) | 0.0 | $-y_{offset}$ | 0.17 | $0.93 S_{body}$ | $0.72 S_{body}$ | 0.32 | (2.5, 2.5, 3.5) |
| Chest (Lower) | 0.0 | $-y_{offset}$ | -0.11 | $0.91 S_{body}$ | $0.71 S_{body}$ | 0.32 | (2.5, 2.5, 3.5) |
| Abd (Upper) | 0.0 | $-y_{offset}$ | -0.45 | $0.87 S_{body}$ | $0.67 S_{body}$ | 0.40 | (2.5, 2.5, 3.5) |
| Abd (Lower) | 0.0 | $-y_{offset}$ | -0.85 | $0.83 \sqrt{S_{body}}$ | $0.62 \sqrt{S_{body}}$ | 0.45 | (2.5, 2.5, 3.5) | 

### Lungs

**Constants:**
$x_{off} = 0.32$ (Lung Center Offset)
$R_{top} = 0.25 + 0.22 S_{scale}$
$R_{low} = 0.430 S_{scale}$
$R_{z,low} = 0.480 S_{lower\_rz}$

| Component | $c_x$ | $c_y$ | $c_z$ | $R_x$ | $R_y$ | $R_z$ | $\epsilon$ |
|-----------|-------|-------|-------|-------|-------|-------|------------|
| L Upper | $-(x_{off}-0.1)$ | $-y_{offset}$ | $-0.1 - 0.5 \Delta z_{dia}$ | $R_{top}$ | $R_{low}$ | 0.70 | (2, 2, 1.2) |
| L Lower | $-x_{off}$ | $-y_{offset}$ | $-0.17 + 0.5 \Delta z_{dia}$ | $R_{low}$ | $R_{low}$ | $R_{z,low}$ | (2, 2, 2.5) |
| R Upper | $x_{off} - 0.1$ | $-y_{offset}$ | $-0.1 - 0.5 \Delta z_{dia}$ | $R_{top}$ | $R_{low}$ | 0.70 | (2, 2, 1.2) |
| R Lower | $x_{off}$ | $-y_{offset}$ | $-0.17 + 0.5 \Delta z_{dia}$ | $R_{low}$ | $R_{low}$ | $R_{z,low}$ | (2, 2, 2.5) |
| L Diaphragm | $-x_{off}$ | $-y_{offset}$ | $-0.50 + \Delta z_{dia}$ | $R_{low}$ | $R_{low}$ | 0.40 | (2.5, 2.5, 1.5) |
| R Diaphragm | $x_{off}$ | $-y_{offset}$ | $-0.50 + \Delta z_{dia}$ | $R_{low}$ | $R_{low}$ | 0.40 | (2.5, 2.5, 1.5) |

## 5. Heart

### Motion Parameters

Given chamber scales $s_{LV}, s_{RV}, s_{LA}, s_{RA}$:

Corrected cavity scales:
```latex
s'_{LV} = 1.10 s_{LV}, \quad s'_{RV} = 1.06 s_{RV}, \quad s'_{LA} = 0.95 s_{LA}, \quad s'_{RA} = 1.00 s_{RA}
```

Displacements:
```latex
dx_{LV} = 0.45 \cdot 0.251 \cdot (s_{LV} - 1.0)
dx_{RV} = 0.45 \cdot 0.209 \cdot (s_{RV} - 1.0)
dx_{LA} = 0.15048 \cdot (s_{LA} - 1.0)
dx_{RA} = 0.15048 \cdot (s_{RA} - 1.0)
dz_{LV} = 0.209(s_{LV}-1), \quad dz_{LA} = 0.188(s_{LA}-1)
dz_{RV} = 0.195(s_{RV}-1), \quad dz_{RA} = 0.188(s_{RA}-1)
z_{sep, L} = 0.9(dz_{LV} + dz_{LA})
z_{sep, R} = 0.9(dz_{RV} + dz_{RA})
```
Constants: $z_{off} = 0.2$.

### Heart Components Table

The heart is composed of 20 ellipsoids/superellipsoids.

Tuning parameters used in the cavity definitions:
$$
\begin{aligned}
&\text{myocardium\_bottom\_z\_scale} = 1.2,\quad \text{lv\_rad\_offset} = 0.006,\quad \text{rv\_rad\_offset} = 0.004,\\
&\text{la\_rad\_offset} = -0.001,\quad \text{ra\_rad\_offset} = 0.0005,\quad \text{lv\_c\_base\_factor} = 1.02,\quad \text{rv\_c\_base\_factor} = 0.98
\end{aligned}
$$

Define cavity scales $s_{LV,c}, s_{RV,c}, s_{LA,c}, s_{RA,c}$ as:
$$
s_{LV,c} = 1.10 s_{LV},\quad s_{RV,c} = 1.06 s_{RV},\quad s_{LA,c} = 0.95 s_{LA},\quad s_{RA,c} = 1.00 s_{RA}
$$

For ellipsoids, $\epsilon = (2, 2, 2)$. Intensities map to the tissue labels in Section 2.

| Component | Type | $c_x$ | $c_y$ | $c_z$ | $R_x$ | $R_y$ | $R_z$ | $\epsilon$ | Intensity |
|-----------|------|-------|-------|-------|-------|-------|-------|-----------|-----------|
| LV outer myocardium (base) | Ellipsoid | $-0.06-dx_{LV}$ | $0.02-y_{offset}$ | $-0.1+z_{off}$ | $0.1595 s_{LV}$ | $0.2145 s_{LV}$ | $0.242 s_{LV}$ | $(2,2,2)$ | heart |
| RV outer myocardium (base) | Ellipsoid | $0.14+dx_{RV}$ | $0.0-y_{offset}$ | $-0.1+z_{off}$ | $0.1595 s_{RV}$ | $0.2145 s_{RV}$ | $0.242 s_{RV}$ | $(2,2,2)$ | heart |
| LV outer myocardium (mid) | Superellipsoid | $-0.06-dx_{LV}$ | $0.02-y_{offset}$ | $0.0+z_{off}$ | $0.1485 s_{LV}$ | $0.2035 s_{LV}$ | $0.1782 s_{LV}$ | $(2.5,2.5,2.5)$ | heart |
| RV outer myocardium (mid) | Superellipsoid | $0.14+dx_{RV}$ | $0.0-y_{offset}$ | $0.0+z_{off}$ | $0.1485 s_{RV}$ | $0.2035 s_{RV}$ | $0.1782 s_{RV}$ | $(2.5,2.5,2.5)$ | heart |
| LV myocardium (base) | Superellipsoid | $-0.063-dx_{LV}$ | $0.02-y_{offset}$ | $(0.0+z_{off})-z_{sep,L}$ | $0.251 s_{LV}$ | $0.251 s_{LV}$ | $(0.209 s_{LV})\,\text{myocardium\_bottom\_z\_scale}$ | $(2,2,2)$ | heart |
| LV myocardium (mid) | Superellipsoid | $-0.063-dx_{LV}$ | $0.02-y_{offset}$ | $(0.08+z_{off})-z_{sep,L}$ | $0.195 s_{LV}$ | $0.195 s_{LV}$ | $0.157 s_{LV}$ | $(3,3,2)$ | heart |
| LV cavity (base) | Superellipsoid | $-0.06-dx_{LV}$ | $0.02-y_{offset}$ | $(-0.1+z_{off})-z_{sep,L}$ | $(0.112125 s_{LV,c}+\text{lv\_rad\_offset})\,\text{lv\_c\_base\_factor}$ | $(0.160875 s_{LV,c}+\text{lv\_rad\_offset})\,\text{lv\_c\_base\_factor}$ | $(0.156 s_{LV,c})\,\text{lv\_c\_base\_factor}$ | $(2,2,2)$ | lv_blood |
| LV cavity (mid A) | Superellipsoid | $-0.06-dx_{LV}$ | $0.02-y_{offset}$ | $(0.0+z_{off})-z_{sep,L}$ | $0.102375 s_{LV,c}+\text{lv\_rad\_offset}$ | $0.151125 s_{LV,c}+\text{lv\_rad\_offset}$ | $0.1404 s_{LV,c}$ | $(2.5,2.5,2.5)$ | lv_blood |
| LV cavity (mid B) | Superellipsoid | $-0.06-dx_{LV}$ | $0.02-y_{offset}$ | $(0.0+z_{off})-z_{sep,L}$ | $0.193288 s_{LV,c}$ | $0.193288 s_{LV,c}$ | $0.14366 s_{LV,c}$ | $(2,2,2)$ | lv_blood |
| LV cavity (apex) | Superellipsoid | $-0.06-dx_{LV}$ | $0.02-y_{offset}$ | $(0.04+z_{off})-z_{sep,L}$ | $0.151496 s_{LV,c}$ | $0.151496 s_{LV,c}$ | $0.094032 s_{LV,c}$ | $(3,3,2)$ | lv_blood |
| RV myocardium (base) | Superellipsoid | $0.143+dx_{RV}$ | $0.0-y_{offset}$ | $(0.0+z_{off})-z_{sep,R}$ | $0.209 s_{RV}$ | $0.209 s_{RV}$ | $(0.195 s_{RV})\,\text{myocardium\_bottom\_z\_scale}$ | $(2,2,2)$ | heart |
| RV myocardium (mid) | Superellipsoid | $0.143+dx_{RV}$ | $0.0-y_{offset}$ | $(0.08+z_{off})-z_{sep,R}$ | $0.167 s_{RV}$ | $0.167 s_{RV}$ | $0.136 s_{RV}$ | $(3,3,2)$ | heart |
| RV cavity (base) | Superellipsoid | $0.14+dx_{RV}$ | $0.0-y_{offset}$ | $(-0.1+z_{off})-z_{sep,R}$ | $(0.11822 s_{RV,c}+\text{rv\_rad\_offset})\,\text{rv\_c\_base\_factor}$ | $(0.16962 s_{RV,c}+\text{rv\_rad\_offset})\,\text{rv\_c\_base\_factor}$ | $(0.16448 s_{RV,c})\,\text{rv\_c\_base\_factor}$ | $(2,2,2)$ | rv_blood |
| RV cavity (mid A) | Superellipsoid | $0.14+dx_{RV}$ | $0.0-y_{offset}$ | $(0.0+z_{off})-z_{sep,R}$ | $0.10794 s_{RV,c}+\text{rv\_rad\_offset}$ | $0.15934 s_{RV,c}+\text{rv\_rad\_offset}$ | $0.148032 s_{RV,c}$ | $(2.5,2.5,2.5)$ | rv_blood |
| RV cavity (mid B) | Superellipsoid | $0.14+dx_{RV}$ | $0.0-y_{offset}$ | $(0.0+z_{off})-z_{sep,R}$ | $0.172112 s_{RV,c}$ | $0.172112 s_{RV,c}$ | $0.133248 s_{RV,c}$ | $(2,2,2)$ | rv_blood |
| RV cavity (apex) | Superellipsoid | $0.14+dx_{RV}$ | $0.0-y_{offset}$ | $(0.04+z_{off})-z_{sep,R}$ | $0.1388 s_{RV,c}$ | $0.1388 s_{RV,c}$ | $0.094384 s_{RV,c}$ | $(3,3,2)$ | rv_blood |
| LA myocardium | Superellipsoid | $-0.101-dx_{LA}$ | $-0.05-y_{offset}$ | $(0.25+z_{off})+z_{sep,L}$ | $0.15 s_{LA}$ | $0.15 s_{LA}$ | $0.188 s_{LA}$ | $(2.2,2.2,2.2)$ | heart |
| LA cavity | Superellipsoid | $-0.101$ | $-0.05-y_{offset}$ | $(0.25+z_{off})+z_{sep,L}$ | $0.134352 s_{LA,c}+\text{la\_rad\_offset}$ | $0.134352 s_{LA,c}+\text{la\_rad\_offset}$ | $0.16794 s_{LA,c}$ | $(2.2,2.2,2.2)$ | la_blood |
| RA myocardium | Superellipsoid | $0.161+dx_{RA}$ | $-0.07-y_{offset}$ | $(0.25+z_{off})+z_{sep,R}$ | $0.15 s_{RA}$ | $0.15 s_{RA}$ | $0.188 s_{RA}$ | $(2.2,2.2,2.2)$ | heart |
| RA cavity | Superellipsoid | $0.161$ | $-0.07-y_{offset}$ | $(0.25+z_{off})+z_{sep,R}$ | $0.126468 s_{RA,c}+\text{ra\_rad\_offset}$ | $0.126468 s_{RA,c}+\text{ra\_rad\_offset}$ | $0.158085 s_{RA,c}$ | $(2.2,2.2,2.2)$ | ra_blood |

## 6. Physiological Signal Generation

### Respiratory Signal

The default respiratory signal $S_{resp}(t)$ (in Liters) is generated with a fundamental frequency $f_{resp} = RR/60$ Hz.

1. **Phase Evolution** (with Rate Variability $A_{rr}, f_{rr}$):
```latex
\theta(t) = 2\pi f_{resp} t - \frac{f_{resp} A_{rr}}{f_{rr}} (\cos(2\pi f_{rr} t) - 1)
```

2. **Base Waveform** (Asymmetric):
```latex
W(t) = \sin(\theta(t)) + A_{asym} \sin(2\theta(t))
```

3. **Amplitude Modulation** (Depth Variability $A_{am}, f_{am}$):
```latex
M(t) = 1 + A_{am} \sin(2\pi f_{am} t)
S_{raw}(t) = W(t) \cdot M(t)
```

4. **Normalization:**
Map $S_{raw}$ linearly to range $[V_{min}, V_{max}]$.

### Cardiac Signals

The cardiac cycle is modeled as a piecewise function of phase $\phi(t) = (t \pmod T) / T$, where $T = 60/HR$.
Systole duration fraction $\gamma = T_{sys}/T \approx 0.35$.

**Systole ($0 \le \phi < \gamma$):**
Normalized time $x_s = \phi / \gamma$.
Left Ventricle Volume:
```latex
V_{LV}(\phi) = V_{ED} - (V_{ED} - V_{ES}) \cdot (1 - (1 - x_s)^3)
```

**Diastole ($\gamma \le \phi < 1$):**
Normalized time $x_d = (\phi - \gamma) / (1 - \gamma)$.
Left Ventricle Volume (Passive Filling + Atrial Kick):
```latex
V_{LV}(\phi) = V_{ES} + (V_{ED} - V_{ES}) \cdot \left( x_d^{2.2} + A_{kick} \exp\left( - \frac{(x_d - \mu_{kick})^2}{\sigma_{kick}^2} \right) \right)
```

Atrial volumes are modeled similarly in counter-phase (filling during systole, emptying during diastole).
