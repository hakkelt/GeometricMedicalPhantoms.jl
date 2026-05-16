/**
 * geometric_medical_phantoms.h
 *
 * C API for the GeometricMedicalPhantoms shared library.
 *
 * DATA LAYOUT
 * -----------
 * All multi-dimensional arrays (phantom output, signals) use column-major
 * (Fortran / Julia) memory layout:
 *
 *   3-D phantom:   out[x + nx*(y + ny*z)]
 *   4-D phantom:   out[x + nx*(y + ny*(z + nz*t))]
 *   2-D phantom:   out[x + nx*y]
 *   3-D (2D+t):    out[x + nx*(y + ny*t)]
 *
 * All phantom values are 32-bit floats (float).
 * Signal arrays (time, volumes, respiratory) are 64-bit doubles (double).
 *
 * AXIS CONSTANTS
 * --------------
 *   GMP_AXIS_AXIAL    = 0  — x/y plane (slice along z)
 *   GMP_AXIS_CORONAL  = 1  — x/z plane (slice along y)
 *   GMP_AXIS_SAGITTAL = 2  — y/z plane (slice along x)
 *
 * ERROR CODES
 * -----------
 *   0   — success
 *  -1   — general error (exception caught inside Julia)
 *  -2   — invalid axis value
 *
 * MEMORY OWNERSHIP
 * ----------------
 * The caller is responsible for allocating (and freeing) all buffers passed
 * to these functions.  The library never allocates memory visible to the
 * caller.
 *
 * THREAD SAFETY
 * -------------
 * Julia's runtime is NOT re-entrant.  Call these functions from a single
 * thread, or use appropriate synchronization if calling from multiple threads.
 *
 * INITIALISATION
 * --------------
 * Call gmp_init() once after loading the library and before calling any
 * other function.  Call gmp_cleanup() when done (optional; the Julia runtime
 * is also cleaned up when the library is unloaded).
 *
 * Failing to call gmp_init() first results in a segfault when the calling
 * thread is not recognised by Julia's threading subsystem.
 */

#ifndef GEOMETRIC_MEDICAL_PHANTOMS_H
#define GEOMETRIC_MEDICAL_PHANTOMS_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

/* -------------------------------------------------------------------------
 * Axis constants
 * ---------------------------------------------------------------------- */

#define GMP_AXIS_AXIAL    0
#define GMP_AXIS_CORONAL  1
#define GMP_AXIS_SAGITTAL 2

/* -------------------------------------------------------------------------
 * Parameter structs
 *
 * Each struct mirrors the corresponding Julia struct in
 * lib/src/GeometricMedicalPhantomsLib.jl.  Field order, types and alignment
 * must match exactly.  All fields are native double / int on 64-bit targets.
 * ---------------------------------------------------------------------- */

/**
 * RespiratoryPhysiology — controls the shape of the simulated breathing
 * signal.  Populate with gmp_respiratory_physiology_default(), then
 * modify any field before passing to gmp_generate_respiratory_signal().
 */
typedef struct {
    double minL;          /**< Minimum lung volume (liters, default 2.4)   */
    double maxL;          /**< Maximum lung volume (liters, default 3.0)   */
    double asym_amp;      /**< Asymmetry harmonic amplitude (frac, def 0.2)*/
    double amp_mod_amp;   /**< Amplitude modulation amplitude (frac, 0.15) */
    double amp_mod_freq;  /**< Amplitude modulation frequency (Hz, 0.05)   */
    double rr_var_amp;    /**< RR-rate variability amplitude (frac, 0.03)  */
    double rr_var_freq;   /**< RR-rate variability frequency (Hz, 0.03)    */
} GmpRespiratoryPhysiology;

/**
 * CardiacPhysiology — controls cardiac chamber volumes and modulation.
 * Populate with gmp_cardiac_physiology_default(), then modify as needed.
 */
typedef struct {
    double lv_edv;            /**< LV end-diastolic volume (mL, 130)   */
    double lv_esv;            /**< LV end-systolic volume  (mL,  55)   */
    double rv_edv;            /**< RV end-diastolic volume (mL, 140)   */
    double rv_esv;            /**< RV end-systolic volume  (mL,  65)   */
    double la_min;            /**< LA minimum volume (mL, 30)          */
    double la_max;            /**< LA maximum volume (mL, 60)          */
    double ra_min;            /**< RA minimum volume (mL, 30)          */
    double ra_max;            /**< RA maximum volume (mL, 60)          */
    double hr_var_amp;        /**< HR variability amplitude (frac, .03)*/
    double hr_var_freq;       /**< HR variability frequency (Hz)       */
    double v_amp_amp;         /**< Ventricular amp-mod amplitude       */
    double v_amp_freq;        /**< Ventricular amp-mod frequency (Hz)  */
    double a_amp_amp;         /**< Atrial amp-mod amplitude            */
    double a_amp_freq;        /**< Atrial amp-mod frequency (Hz)       */
    double bw_amp;            /**< Baseline wander amplitude (mL)      */
    double bw_freq;           /**< Baseline wander frequency (Hz)      */
    double s_frac_base;       /**< Base systole fraction (0..1, 0.35)  */
    double s_frac_mod_amp;    /**< Systole-fraction modulation amp     */
    double s_frac_mod_freq;   /**< Systole-fraction modulation freq    */
    double ventricular_ejection_power; /**< Ventricular emptying exponent */
    double lv_filling_power;  /**< LV filling exponent                 */
    double rv_filling_power;  /**< RV filling exponent                 */
    double atrial_fill_power; /**< Atrial filling exponent             */
    double atrial_emptying_power; /**< Atrial emptying exponent        */
    double atrial_phase_shift;/**< Atrial modulation phase shift       */
    double atrial_bw_coupling;/**< Atrial baseline-wander coupling     */
    double lv_kick_amp_frac;  /**< LV atrial kick amplitude fraction   */
    double lv_kick_center;    /**< LV atrial kick center (phase, 0..1) */
    double lv_kick_width;     /**< LV atrial kick width  (phase, 0..1) */
    double rv_kick_amp_frac;  /**< RV atrial kick amplitude fraction   */
    double rv_kick_center;    /**< RV atrial kick center               */
    double rv_kick_width;     /**< RV atrial kick width                */
    double la_contr_amp_frac; /**< LA contraction amplitude fraction   */
    double la_contr_center;   /**< LA contraction center               */
    double la_contr_width;    /**< LA contraction width                */
    double ra_contr_amp_frac; /**< RA contraction amplitude fraction   */
    double ra_contr_center;   /**< RA contraction center               */
    double ra_contr_width;    /**< RA contraction width                */
} GmpCardiacPhysiology;

/**
 * TissueIntensities — MR/CT intensity values for each tissue class in the
 * torso phantom.  Values are normalised floats (0..1 is typical).
 */
typedef struct {
    double lung;          /**< Lung (default 0.08)           */
    double heart;         /**< Heart muscle (0.65)           */
    double vessels_blood; /**< Blood in vessels (1.0)        */
    double bones;         /**< Bone (0.85)                   */
    double liver;         /**< Liver (0.55)                  */
    double stomach;       /**< Stomach (0.9)                 */
    double body;          /**< General body tissue (0.25)    */
    double lv_blood;      /**< LV blood pool (0.98)          */
    double rv_blood;      /**< RV blood pool (0.99)          */
    double la_blood;      /**< LA blood pool (0.97)          */
    double ra_blood;      /**< RA blood pool (0.96)          */
} GmpTissueIntensities;

/**
 * TubesGeometry — geometric parameters for the tubes phantom.
 */
typedef struct {
    double outer_radius;          /**< Outer cylinder radius (0.4)          */
    double outer_height;          /**< Outer cylinder height (0.8)          */
    double tubes_height_fraction; /**< Tube height as fraction (0.9)        */
    double tube_wall_thickness;   /**< Tube wall thickness (0.025)          */
    double gap_fraction;          /**< Gap fraction between tubes (0.3)     */
} GmpTubesGeometry;

/**
 * TubesIntensities — intensity values for the tubes phantom.
 *
 * tube_fillings points to a caller-owned array of n_tubes doubles that
 * controls the fill intensity of each tube.
 * Use gmp_tubes_intensities_default() to populate with default values.
 */
typedef struct {
    double        outer_cylinder; /**< Outer cylinder intensity (0.25)  */
    double        tube_wall;      /**< Tube wall intensity (0.0)        */
    const double *tube_fillings;  /**< Array of n_tubes filling values  */
    int           n_tubes;        /**< Number of tubes (length of above) */
} GmpTubesIntensities;

/**
 * SheppLoganIntensities — additive intensity increments for the 12 ellipsoids
 * of the Shepp-Logan phantom.  Use gmp_shepp_logan_ct_default() or
 * gmp_shepp_logan_mri_default() for standard presets.
 */
typedef struct {
    double skull;
    double brain;
    double right_big;
    double left_big;
    double top;
    double middle_high;
    double bottom_left;
    double middle_low;
    double bottom_center;
    double bottom_right;
    double extra_1;
    double extra_2;
} GmpSheppLoganIntensities;

/* -------------------------------------------------------------------------
 * Utility
 * ---------------------------------------------------------------------- */

/**
 * gmp_init — initialise the Julia runtime.
 *
 * Must be called once after loading the library and before any other
 * gmp_* function.  Safe to call multiple times (subsequent calls are
 * no-ops).
 *
 * Returns 0 on success, -1 on error.
 */
int gmp_init(void);

/**
 * gmp_cleanup — shut down the Julia runtime.
 *
 * Optional.  Call when the library will no longer be used.  After
 * gmp_cleanup() returns, no gmp_* function may be called.
 */
void gmp_cleanup(void);

/** Returns a null-terminated version string (e.g. "1.0.2").
 *  The pointer is valid for the lifetime of the loaded library. */
const char *gmp_version(void);

/* -------------------------------------------------------------------------
 * Default-filler functions
 *
 * Fill a caller-allocated struct with the library defaults.
 * Modify individual fields after calling these functions.
 * ---------------------------------------------------------------------- */

void gmp_respiratory_physiology_default(GmpRespiratoryPhysiology *out);
void gmp_cardiac_physiology_default(GmpCardiacPhysiology *out);
void gmp_tissue_intensities_default(GmpTissueIntensities *out);
void gmp_tubes_geometry_default(GmpTubesGeometry *out);

/**
 * gmp_tubes_intensities_default — fill *out with default tube intensities.
 *
 * @param out         Destination struct.
 * @param fillings_out Caller-allocated array of at least n_tubes doubles.
 *                     Filled with [0.1, 0.3, 0.5, 0.7, 0.9, 1.0] (or fewer
 *                     if n_tubes < 6).  out->tube_fillings is set to this
 *                     pointer; keep the array alive while using the struct.
 * @param n_tubes     Number of tubes (length of fillings_out).
 */
void gmp_tubes_intensities_default(
    GmpTubesIntensities *out,
    double              *fillings_out,
    int                  n_tubes);

void gmp_shepp_logan_ct_default(GmpSheppLoganIntensities *out);
void gmp_shepp_logan_mri_default(GmpSheppLoganIntensities *out);

/* -------------------------------------------------------------------------
 * Signal length helper
 *
 * Returns the number of samples that gmp_generate_*_signal will write for
 * the given duration and sampling frequency.  Use this to pre-allocate the
 * output buffers.
 * ---------------------------------------------------------------------- */

int gmp_signal_length(double duration, double fs);

/* -------------------------------------------------------------------------
 * Signal generation
 * ---------------------------------------------------------------------- */

/**
 * gmp_generate_respiratory_signal — generate a synthetic breathing signal.
 *
 * @param duration  Total duration in seconds.
 * @param fs        Sampling frequency in Hz.
 * @param rr        Respiratory rate in breaths per minute.
 * @param phys      Physiology parameters (use gmp_respiratory_physiology_default).
 * @param t_out     Output: time vector (seconds), caller-allocated, length n.
 * @param sig_out   Output: respiratory signal (liters), caller-allocated, n.
 * @param n         Buffer length; use gmp_signal_length(duration, fs).
 * @return 0 on success, non-zero on error.
 */
int gmp_generate_respiratory_signal(
    double                          duration,
    double                          fs,
    double                          rr,
    const GmpRespiratoryPhysiology *phys,
    double                         *t_out,
    double                         *sig_out,
    int                             n);

/**
 * gmp_generate_cardiac_signals — generate cardiac chamber volume signals.
 *
 * @param duration  Total duration in seconds.
 * @param fs        Sampling frequency in Hz.
 * @param hr        Heart rate in beats per minute.
 * @param phys      Cardiac physiology parameters.
 * @param t_out     Output: time vector (seconds), length n.
 * @param lv_out    Output: left ventricle volume (mL), length n.
 * @param rv_out    Output: right ventricle volume (mL), length n.
 * @param la_out    Output: left atrium volume (mL), length n.
 * @param ra_out    Output: right atrium volume (mL), length n.
 * @param n         Buffer length; use gmp_signal_length(duration, fs).
 * @return 0 on success, non-zero on error.
 */
int gmp_generate_cardiac_signals(
    double                      duration,
    double                      fs,
    double                      hr,
    const GmpCardiacPhysiology *phys,
    double                     *t_out,
    double                     *lv_out,
    double                     *rv_out,
    double                     *la_out,
    double                     *ra_out,
    int                         n);

/* -------------------------------------------------------------------------
 * Shepp-Logan phantom
 * ---------------------------------------------------------------------- */

/**
 * gmp_create_shepp_logan_phantom_3d — create a 3-D Shepp-Logan phantom.
 *
 * @param nx, ny, nz  Grid dimensions.
 * @param ti          Intensity parameters.
 * @param out         Caller-allocated float buffer, size nx*ny*nz.
 *                    Column-major layout: out[x + nx*(y + ny*z)].
 * @return 0 on success.
 */
int gmp_create_shepp_logan_phantom_3d(
    int                           nx,
    int                           ny,
    int                           nz,
    const GmpSheppLoganIntensities *ti,
    float                         *out);

/**
 * gmp_create_shepp_logan_phantom_2d — create a 2-D Shepp-Logan slice.
 *
 * @param nx, ny     Grid dimensions for the slice.
 * @param axis       Slice orientation (GMP_AXIS_*).
 * @param slice_pos  Slice position in cm.
 * @param ti         Intensity parameters.
 * @param out        Caller-allocated float buffer, size nx*ny.
 * @return 0 on success, -2 for invalid axis.
 */
int gmp_create_shepp_logan_phantom_2d(
    int                            nx,
    int                            ny,
    int                            axis,
    double                         slice_pos,
    const GmpSheppLoganIntensities *ti,
    float                         *out);

/* -------------------------------------------------------------------------
 * Tubes phantom
 * ---------------------------------------------------------------------- */

/**
 * gmp_create_tubes_phantom_3d — create a 3-D tubes phantom.
 *
 * @param nx, ny, nz Grid dimensions.
 * @param tg         Geometry parameters.
 * @param ti         Intensity parameters (tube_fillings must be valid).
 * @param out        Caller-allocated float buffer, size nx*ny*nz.
 * @return 0 on success.
 */
int gmp_create_tubes_phantom_3d(
    int                       nx,
    int                       ny,
    int                       nz,
    const GmpTubesGeometry   *tg,
    const GmpTubesIntensities *ti,
    float                    *out);

/**
 * gmp_create_tubes_phantom_2d — create a 2-D tubes phantom slice.
 *
 * @param nx, ny     Grid dimensions for the slice.
 * @param axis       Slice orientation (GMP_AXIS_*).
 * @param slice_pos  Slice position in cm.
 * @param tg         Geometry parameters.
 * @param ti         Intensity parameters.
 * @param out        Caller-allocated float buffer, size nx*ny.
 * @return 0 on success, -2 for invalid axis.
 */
int gmp_create_tubes_phantom_2d(
    int                       nx,
    int                       ny,
    int                       axis,
    double                    slice_pos,
    const GmpTubesGeometry   *tg,
    const GmpTubesIntensities *ti,
    float                    *out);

/* -------------------------------------------------------------------------
 * Torso phantom
 * ---------------------------------------------------------------------- */

/**
 * gmp_create_torso_phantom_3d — create a 3-D (optionally 4-D) torso phantom.
 *
 * @param nx, ny, nz  Grid dimensions.
 * @param n_frames    Number of time frames.  Pass 0 or 1 with NULL signal
 *                    pointers for a static phantom (1 frame).
 * @param resp        Respiratory signal (liters), length n_frames, or NULL.
 * @param cardiac_lv  LV volume (mL), length n_frames, or NULL.
 * @param cardiac_rv  RV volume (mL), length n_frames, or NULL.
 * @param cardiac_la  LA volume (mL), length n_frames, or NULL.
 * @param cardiac_ra  RA volume (mL), length n_frames, or NULL.
 * @param ti          Tissue intensity parameters.
 * @param out         Float buffer, size nx*ny*nz*max(n_frames,1).
 *                    Layout: out[x + nx*(y + ny*(z + nz*t))].
 * @return 0 on success.
 */
int gmp_create_torso_phantom_3d(
    int                       nx,
    int                       ny,
    int                       nz,
    int                       n_frames,
    const double             *resp,
    const double             *cardiac_lv,
    const double             *cardiac_rv,
    const double             *cardiac_la,
    const double             *cardiac_ra,
    const GmpTissueIntensities *ti,
    float                    *out);

/**
 * gmp_create_torso_phantom_2d — create a 2-D (optionally 3-D) torso slice.
 *
 * @param nx, ny     Grid dimensions for the slice.
 * @param axis       Slice orientation (GMP_AXIS_*).
 * @param slice_pos  Slice position in cm.
 * @param n_frames   Number of time frames (0 or 1 = static).
 * @param resp       Respiratory signal, length n_frames, or NULL.
 * @param cardiac_*  Cardiac volume signals, length n_frames, or NULL.
 * @param ti         Tissue intensity parameters.
 * @param out        Float buffer, size nx*ny*max(n_frames,1).
 *                   Layout: out[x + nx*(y + ny*t)].
 * @return 0 on success, -2 for invalid axis.
 */
int gmp_create_torso_phantom_2d(
    int                       nx,
    int                       ny,
    int                       axis,
    double                    slice_pos,
    int                       n_frames,
    const double             *resp,
    const double             *cardiac_lv,
    const double             *cardiac_rv,
    const double             *cardiac_la,
    const double             *cardiac_ra,
    const GmpTissueIntensities *ti,
    float                    *out);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* GEOMETRIC_MEDICAL_PHANTOMS_H */
