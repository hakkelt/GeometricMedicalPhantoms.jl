"""
example.py — demonstration of the GeometricMedicalPhantoms Python wrapper.

Run from the lib/python directory after building the shared library:

    python example.py /path/to/build/lib/libgeomphantoms.so
"""

import sys
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

from geometric_medical_phantoms import (
    GMPLib,
    AXIS_AXIAL,
    AXIS_CORONAL,
    AXIS_SAGITTAL,
)


def main(lib_path: str) -> None:
    lib = GMPLib(lib_path)
    print(f"Library version: {lib.version()}")

    # ------------------------------------------------------------------
    # Shepp-Logan 3-D phantom
    # ------------------------------------------------------------------
    ti = lib.shepp_logan_ct_default()
    sl = lib.create_shepp_logan_phantom_3d(128, 128, 128, ti)
    print(f"Shepp-Logan 3-D shape: {sl.shape}, dtype: {sl.dtype}")

    # Plot three orthogonal views
    fig, axes = plt.subplots(1, 3, figsize=(12, 4))
    axes[0].imshow(sl[:, :, 64].T, cmap="gray", origin="lower")
    axes[0].set_title("Axial (z=64)")
    axes[1].imshow(sl[:, 64, :].T, cmap="gray", origin="lower")
    axes[1].set_title("Coronal (y=64)")
    axes[2].imshow(sl[64, :, :].T, cmap="gray", origin="lower")
    axes[2].set_title("Sagittal (x=64)")
    fig.suptitle("Shepp-Logan Phantom")
    fig.savefig("shepp_logan_3d.png", dpi=100, bbox_inches="tight")
    plt.close(fig)

    # ------------------------------------------------------------------
    # Respiratory signal
    # ------------------------------------------------------------------
    phys = lib.respiratory_physiology_default()
    phys.rr_var_amp = 0.05   # increase variability
    t, sig = lib.generate_respiratory_signal(60.0, 50.0, 15.0, phys)
    print(f"Respiratory signal: {len(t)} samples, range [{sig.min():.3f}, {sig.max():.3f}] L")

    fig, ax = plt.subplots(figsize=(10, 3))
    ax.plot(t, sig)
    ax.set(xlabel="Time (s)", ylabel="Lung volume (L)", title="Respiratory Signal")
    fig.savefig("respiratory_signal.png", dpi=100, bbox_inches="tight")
    plt.close(fig)

    # ------------------------------------------------------------------
    # Cardiac signals
    # ------------------------------------------------------------------
    cphys = lib.cardiac_physiology_default()
    tc, lv, rv, la, ra = lib.generate_cardiac_signals(10.0, 500.0, 70.0, cphys)
    print(f"Cardiac signals: {len(tc)} samples")

    fig, ax = plt.subplots(figsize=(10, 4))
    for label, arr in [("LV", lv), ("RV", rv), ("LA", la), ("RA", ra)]:
        ax.plot(tc, arr, label=label)
    ax.set(xlabel="Time (s)", ylabel="Volume (mL)", title="Cardiac Chamber Volumes")
    ax.legend()
    fig.savefig("cardiac_signals.png", dpi=100, bbox_inches="tight")
    plt.close(fig)

    # ------------------------------------------------------------------
    # Dynamic torso phantom (axial slice, 10 frames)
    # ------------------------------------------------------------------
    ti_torso = lib.tissue_intensities_default()
    # Use first 10 samples of resp signal as the motion signal
    resp10 = sig[:10]

    torso = lib.create_torso_phantom_2d(
        128, 128,
        axis=AXIS_AXIAL,
        slice_position=0.0,
        resp_signal=resp10,
        tissue=ti_torso,
    )
    print(f"Torso 2-D dynamic shape: {torso.shape}")

    fig, axes = plt.subplots(1, 5, figsize=(20, 4))
    for i, ax in enumerate(axes):
        frame_idx = i * 2
        ax.imshow(torso[:, :, frame_idx].T, cmap="gray", origin="lower")
        ax.set_title(f"Frame {frame_idx}")
    fig.suptitle("Torso Phantom – Axial Slice (10 frames, showing every 2nd)")
    fig.savefig("torso_dynamic.png", dpi=100, bbox_inches="tight")
    plt.close(fig)

    # ------------------------------------------------------------------
    # Tubes phantom 2-D
    # ------------------------------------------------------------------
    tg = lib.tubes_geometry_default()
    ti_tubes = lib.tubes_intensities_default(n_tubes=6)
    tubes = lib.create_tubes_phantom_2d(256, 256, axis=AXIS_AXIAL, geometry=tg, intensities=ti_tubes)
    print(f"Tubes 2-D shape: {tubes.shape}")

    fig, ax = plt.subplots(figsize=(5, 5))
    ax.imshow(tubes.T, cmap="gray", origin="lower")
    ax.set_title("Tubes Phantom – Axial")
    fig.savefig("tubes_2d.png", dpi=100, bbox_inches="tight")
    plt.close(fig)

    print("\nAll examples complete.  Images saved to current directory.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: python {sys.argv[0]} <path_to_libgeomphantoms>")
        sys.exit(1)
    main(sys.argv[1])
