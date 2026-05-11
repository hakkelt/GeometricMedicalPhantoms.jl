classdef GeometricMedicalPhantoms
% GeometricMedicalPhantoms  MATLAB interface to the GeometricMedicalPhantoms
% Julia package, bridged via Mex.jl.
%
% PREREQUISITES
%   1. Julia must be installed and on the system PATH.
%   2. The GeometricMedicalPhantoms Julia package must be installed:
%        julia -e 'import Pkg; Pkg.add("GeometricMedicalPhantoms")'
%   3. Mex.jl must be installed (builds and registers mexjulia automatically):
%        julia -e 'import Pkg; Pkg.add("Mex")'
%      Run lib/matlab/setup.jl to do steps 2-3 in one go.
%
% BASIC USAGE
%   lib = GeometricMedicalPhantoms();
%
% USAGE WITH EXPLICIT JULIA PROJECT
%   lib = GeometricMedicalPhantoms('/path/to/GeometricMedicalPhantoms');
%
% EXAMPLES
%   % Shepp-Logan 3-D phantom with CT intensities
%   ti = lib.sheppLoganCtDefault();
%   phantom = lib.createSheppLoganPhantom3D(128, 128, 128, ti);
%   % phantom is a 128x128x128 single array (column-major)
%
%   % Respiratory signal
%   phys = lib.respiratoryPhysiologyDefault();
%   [t, sig] = lib.generateRespiratorySignal(60.0, 50.0, 15.0, phys);
%
%   % Dynamic torso (50 frames of respiratory motion)
%   ti_torso = lib.tissueIntensitiesDefault();
%   torso = lib.createTorsoPhantom3D(64, 64, 64, ...
%               'resp_signal', sig(1:50), 'tissue', ti_torso);
%
% DATA LAYOUT
%   All phantom arrays use column-major (Fortran/Julia) memory order, which
%   is the native MATLAB layout.
%
% AXIS CONSTANTS
%   lib.AXIS_AXIAL    = 0
%   lib.AXIS_CORONAL  = 1
%   lib.AXIS_SAGITTAL = 2

    properties (Constant)
        AXIS_AXIAL    = 0;
        AXIS_CORONAL  = 1;
        AXIS_SAGITTAL = 2;
    end

    % Field-order constants — must match the decoder order in GmpBridge.jl.
    properties (Constant, Access = private)
        RESP_FIELDS = {'minL','maxL','asym_amp','amp_mod_amp','amp_mod_freq', ...
                       'rr_var_amp','rr_var_freq'};

        CARD_FIELDS = {'lv_edv','lv_esv','rv_edv','rv_esv', ...
                       'la_min','la_max','ra_min','ra_max', ...
                       'hr_var_amp','hr_var_freq','v_amp_amp','v_amp_freq', ...
                       'a_amp_amp','a_amp_freq','bw_amp','bw_freq','s_frac_base', ...
                       'lv_kick_amp_frac','lv_kick_center','lv_kick_width', ...
                       'rv_kick_amp_frac','rv_kick_center','rv_kick_width', ...
                       'la_contr_amp_frac','la_contr_center','la_contr_width', ...
                       'ra_contr_amp_frac','ra_contr_center','ra_contr_width'};

        TISSUE_FIELDS = {'lung','heart','vessels_blood','bones','liver','stomach', ...
                         'body','lv_blood','rv_blood','la_blood','ra_blood'};

        TGEOM_FIELDS  = {'outer_radius','outer_height','tubes_height_fraction', ...
                         'tube_wall_thickness','gap_fraction'};

        SL_FIELDS     = {'skull','brain','right_big','left_big','top','middle_high', ...
                         'bottom_left','middle_low','bottom_center','bottom_right', ...
                         'extra_1','extra_2'};
    end

    % =====================================================================
    methods
    % =====================================================================

        function obj = GeometricMedicalPhantoms(julia_project)
        % Constructor.
        %
        %   julia_project (optional) – path to a Julia project directory to
        %   activate before loading the bridge.  Omit to use the default
        %   Julia environment.
        %
        % The Mex.jl mexjulia function must be on the MATLAB path.
        % Run lib/matlab/setup.jl once to install all required Julia packages.

            % Optionally activate a specific Julia project.
            if nargin >= 1 && ~isempty(julia_project)
                safe = strrep(julia_project, '\', '/');
                jl.eval(sprintf( ...
                    'import Pkg; Pkg.activate("%s"; io=devnull)', safe));
            end

            % Load the bridge — idempotent, only runs once per MATLAB session.
            bridge_file = fullfile(fileparts(mfilename('fullpath')), ...
                                   'GmpBridge.jl');
            safe_bridge = strrep(bridge_file, '\', '/');
            jl.eval(sprintf( ...
                'isdefined(Main, :gmp_version) || include("%s")', safe_bridge));
        end

        function delete(~)
        % Julia lives for the lifetime of the MATLAB session; no teardown.
        end

        % -----------------------------------------------------------------
        % Utility
        % -----------------------------------------------------------------

        function ver = version(~)
        % Return the library version string (e.g. "1.0.2").
            ver = jl.mex('gmp_version');
        end

        function n = signalLength(~, duration, fs)
        % Number of samples for a signal of the given duration and sample rate.
            n = double(jl.mex('gmp_signal_length', ...
                               double(duration), double(fs)));
        end

        % -----------------------------------------------------------------
        % Default-parameter factory methods
        % -----------------------------------------------------------------

        function phys = respiratoryPhysiologyDefault(obj)
        % Struct with default RespiratoryPhysiology values.
            v = double(jl.mex('gmp_resp_physiology_default'));
            phys = GeometricMedicalPhantoms.vecToStruct(v, obj.RESP_FIELDS);
        end

        function phys = cardiacPhysiologyDefault(obj)
        % Struct with default CardiacPhysiology values.
            v = double(jl.mex('gmp_cardiac_physiology_default'));
            phys = GeometricMedicalPhantoms.vecToStruct(v, obj.CARD_FIELDS);
        end

        function ti = tissueIntensitiesDefault(obj)
        % Struct with default TissueIntensities values.
            v = double(jl.mex('gmp_tissue_intensities_default'));
            ti = GeometricMedicalPhantoms.vecToStruct(v, obj.TISSUE_FIELDS);
        end

        function tg = tubesGeometryDefault(obj)
        % Struct with default TubesGeometry values.
            v = double(jl.mex('gmp_tubes_geometry_default'));
            tg = GeometricMedicalPhantoms.vecToStruct(v, obj.TGEOM_FIELDS);
        end

        function ti = tubesIntensitiesDefault(~)
        % Struct with default TubesIntensities values.
        %   ti.outer_cylinder – scalar double
        %   ti.tube_wall      – scalar double
        %   ti.tube_fillings  – 1xn double row-vector (6 tubes by default)
            v = double(jl.mex('gmp_tubes_intensities_default'));
            ti.outer_cylinder = v(1);
            ti.tube_wall      = v(2);
            ti.tube_fillings  = v(3:end);
        end

        function ti = sheppLoganCtDefault(obj)
        % Shepp-Logan CT intensity values (Shepp & Logan 1974).
            v = double(jl.mex('gmp_shepp_logan_ct_default'));
            ti = GeometricMedicalPhantoms.vecToStruct(v, obj.SL_FIELDS);
        end

        function ti = sheppLoganMriDefault(obj)
        % Shepp-Logan MRI intensity values (Toft).
            v = double(jl.mex('gmp_shepp_logan_mri_default'));
            ti = GeometricMedicalPhantoms.vecToStruct(v, obj.SL_FIELDS);
        end

        % -----------------------------------------------------------------
        % Signal generation
        % -----------------------------------------------------------------

        function [t, signal] = generateRespiratorySignal(obj, duration, fs, rr, phys)
        % Generate a synthetic respiratory signal.
        %
        %   [t, signal] = lib.generateRespiratorySignal(duration, fs, rr)
        %   [t, signal] = lib.generateRespiratorySignal(duration, fs, rr, phys)
        %
        %   t      – time vector (s), 1xn double
        %   signal – lung volume (liters), 1xn double
            if nargin < 5 || isempty(phys)
                phys = obj.respiratoryPhysiologyDefault();
            end
            phys_v = obj.encodeStruct(phys, obj.RESP_FIELDS);
            [t, signal] = jl.mex('gmp_generate_respiratory_signal', ...
                double(duration), double(fs), double(rr), phys_v);
        end

        function [t, lv, rv, la, ra] = generateCardiacSignals(obj, duration, fs, hr, phys)
        % Generate cardiac chamber volume signals.
        %
        %   [t, lv, rv, la, ra] = lib.generateCardiacSignals(duration, fs, hr)
        %   [t, lv, rv, la, ra] = lib.generateCardiacSignals(duration, fs, hr, phys)
        %
        %   t  – time vector (s); lv/rv/la/ra – volumes (mL), each 1xn double
            if nargin < 5 || isempty(phys)
                phys = obj.cardiacPhysiologyDefault();
            end
            phys_v = obj.encodeStruct(phys, obj.CARD_FIELDS);
            [t, lv, rv, la, ra] = jl.mex('gmp_generate_cardiac_signals', ...
                double(duration), double(fs), double(hr), phys_v);
        end

        % -----------------------------------------------------------------
        % Shepp-Logan phantom
        % -----------------------------------------------------------------

        function phantom = createSheppLoganPhantom3D(obj, nx, ny, nz, ti)
        % 3-D Shepp-Logan phantom.  phantom is nx x ny x nz single array.
            if nargin < 5 || isempty(ti)
                ti = obj.sheppLoganCtDefault();
            end
            ti_v = obj.encodeStruct(ti, obj.SL_FIELDS);
            phantom = jl.mex('gmp_shepp_logan_3d', ...
                double(nx), double(ny), double(nz), ti_v);
        end

        function slice = createSheppLoganPhantom2D(obj, nx, ny, axis, slice_pos, ti)
        % 2-D Shepp-Logan slice.  slice is nx x ny single array.
            if nargin < 4 || isempty(axis);      axis      = obj.AXIS_AXIAL; end
            if nargin < 5 || isempty(slice_pos); slice_pos = 0.0; end
            if nargin < 6 || isempty(ti);        ti        = obj.sheppLoganCtDefault(); end
            ti_v = obj.encodeStruct(ti, obj.SL_FIELDS);
            slice = jl.mex('gmp_shepp_logan_2d', ...
                double(nx), double(ny), double(axis), double(slice_pos), ti_v);
        end

        % -----------------------------------------------------------------
        % Tubes phantom
        % -----------------------------------------------------------------

        function phantom = createTubesPhantom3D(obj, nx, ny, nz, tg, ti)
        % 3-D tubes phantom.  phantom is nx x ny x nz single array.
            if nargin < 5 || isempty(tg); tg = obj.tubesGeometryDefault(); end
            if nargin < 6 || isempty(ti); ti = obj.tubesIntensitiesDefault(); end
            tg_v = obj.encodeStruct(tg, obj.TGEOM_FIELDS);
            ti_v = GeometricMedicalPhantoms.encodeTubesIntensities(ti);
            phantom = jl.mex('gmp_tubes_3d', ...
                double(nx), double(ny), double(nz), tg_v, ti_v);
        end

        function slice = createTubesPhantom2D(obj, nx, ny, axis, slice_pos, tg, ti)
        % 2-D tubes phantom slice.  slice is nx x ny single array.
            if nargin < 4 || isempty(axis);      axis      = obj.AXIS_AXIAL; end
            if nargin < 5 || isempty(slice_pos); slice_pos = 0.0; end
            if nargin < 6 || isempty(tg);        tg        = obj.tubesGeometryDefault(); end
            if nargin < 7 || isempty(ti);        ti        = obj.tubesIntensitiesDefault(); end
            tg_v = obj.encodeStruct(tg, obj.TGEOM_FIELDS);
            ti_v = GeometricMedicalPhantoms.encodeTubesIntensities(ti);
            slice = jl.mex('gmp_tubes_2d', ...
                double(nx), double(ny), double(axis), double(slice_pos), tg_v, ti_v);
        end

        % -----------------------------------------------------------------
        % Torso phantom
        % -----------------------------------------------------------------

        function phantom = createTorsoPhantom3D(obj, nx, ny, nz, varargin)
        % 3-D (or 4-D) torso phantom.
        %
        %   phantom = lib.createTorsoPhantom3D(nx, ny, nz)
        %   phantom = lib.createTorsoPhantom3D(nx, ny, nz, ...
        %               'resp_signal', resp, ...
        %               'cardiac_lv',  lv, 'cardiac_rv', rv, ...
        %               'cardiac_la',  la, 'cardiac_ra', ra, ...
        %               'tissue',      ti)
        %
        %   phantom – single array, nx x ny x nz (static) or
        %             nx x ny x nz x n_frames (dynamic)
            p = inputParser;
            addParameter(p, 'resp_signal', []);
            addParameter(p, 'cardiac_lv',  []);
            addParameter(p, 'cardiac_rv',  []);
            addParameter(p, 'cardiac_la',  []);
            addParameter(p, 'cardiac_ra',  []);
            addParameter(p, 'tissue',      []);
            parse(p, varargin{:});

            ti = p.Results.tissue;
            if isempty(ti); ti = obj.tissueIntensitiesDefault(); end
            ti_v = obj.encodeStruct(ti, obj.TISSUE_FIELDS);

            nf = max(max(cellfun(@numel, {p.Results.resp_signal, ...
                p.Results.cardiac_lv, p.Results.cardiac_rv, ...
                p.Results.cardiac_la, p.Results.cardiac_ra})), 1);

            mex_args = {double(nx), double(ny), double(nz), double(nf), ti_v};
            if nf > 1
                mex_args{end+1} = double(p.Results.resp_signal(:)');
                mex_args{end+1} = double(p.Results.cardiac_lv(:)');
                mex_args{end+1} = double(p.Results.cardiac_rv(:)');
                mex_args{end+1} = double(p.Results.cardiac_la(:)');
                mex_args{end+1} = double(p.Results.cardiac_ra(:)');
            end
            phantom = jl.mex('gmp_torso_3d', mex_args{:});
        end

        function phantom = createTorsoPhantom2D(obj, nx, ny, axis, slice_pos, varargin)
        % 2-D (or 3-D) torso phantom slice.
        %
        %   phantom = lib.createTorsoPhantom2D(nx, ny, axis, slice_pos)
        %   phantom = lib.createTorsoPhantom2D(nx, ny, axis, slice_pos, ...)
        %
        %   phantom – single array, nx x ny (static) or nx x ny x n_frames
            if nargin < 4 || isempty(axis);      axis      = obj.AXIS_AXIAL; end
            if nargin < 5 || isempty(slice_pos); slice_pos = 0.0; end

            p = inputParser;
            addParameter(p, 'resp_signal', []);
            addParameter(p, 'cardiac_lv',  []);
            addParameter(p, 'cardiac_rv',  []);
            addParameter(p, 'cardiac_la',  []);
            addParameter(p, 'cardiac_ra',  []);
            addParameter(p, 'tissue',      []);
            parse(p, varargin{:});

            ti = p.Results.tissue;
            if isempty(ti); ti = obj.tissueIntensitiesDefault(); end
            ti_v = obj.encodeStruct(ti, obj.TISSUE_FIELDS);

            nf = max(max(cellfun(@numel, {p.Results.resp_signal, ...
                p.Results.cardiac_lv, p.Results.cardiac_rv, ...
                p.Results.cardiac_la, p.Results.cardiac_ra})), 1);

            mex_args = {double(nx), double(ny), double(axis), double(slice_pos), ...
                        double(nf), ti_v};
            if nf > 1
                mex_args{end+1} = double(p.Results.resp_signal(:)');
                mex_args{end+1} = double(p.Results.cardiac_lv(:)');
                mex_args{end+1} = double(p.Results.cardiac_rv(:)');
                mex_args{end+1} = double(p.Results.cardiac_la(:)');
                mex_args{end+1} = double(p.Results.cardiac_ra(:)');
            end
            phantom = jl.mex('gmp_torso_2d', mex_args{:});
        end

    end % public methods

    % =====================================================================
    methods (Access = private)
    % =====================================================================

        function v = encodeStruct(obj, st, fields) %#ok<INUSL>
        % Encode a MATLAB struct as a flat double row-vector (field order
        % must match the corresponding decoder in GmpBridge.jl).
            v = zeros(1, numel(fields));
            for i = 1:numel(fields)
                v(i) = double(st.(fields{i}));
            end
        end

    end % private methods

    % =====================================================================
    methods (Static, Access = private)
    % =====================================================================

        function st = vecToStruct(v, fields)
        % Convert a flat double row-vector from jl.mex to a MATLAB struct.
            v  = double(v(:)');
            st = struct();
            for i = 1:numel(fields)
                st.(fields{i}) = v(i);
            end
        end

        function v = encodeTubesIntensities(ti)
        % Encode a TubesIntensities struct as [outer_cylinder, tube_wall, fillings...].
            v = [double(ti.outer_cylinder), double(ti.tube_wall), ...
                 double(ti.tube_fillings(:)')];
        end

    end % static private methods

end % classdef
