classdef GeometricMedicalPhantoms
% GeometricMedicalPhantoms  MATLAB interface to the GeometricMedicalPhantoms
% CLI application.
%
% PREREQUISITES
%   1. The `geomphantoms` CLI executable must be installed or built.
%   2. The executable must either be on the system PATH, live under
%      `<repo>/app/build/bin/`, or be passed to the constructor explicitly.
%
% BASIC USAGE
%   lib = GeometricMedicalPhantoms();
%
% USAGE WITH EXPLICIT CLI LOCATION
%   lib = GeometricMedicalPhantoms('/path/to/geomphantoms');
%   lib = GeometricMedicalPhantoms('/path/to/cli-bundle-root');
%   lib = GeometricMedicalPhantoms('/path/to/repo-root');
%
% EXAMPLES
%   ti = lib.sheppLoganCtDefault();
%   phantom = lib.createSheppLoganPhantom3D(128, 128, 128, ti);
%
%   phys = lib.respiratoryPhysiologyDefault();
%   [t, sig] = lib.generateRespiratorySignal(60.0, 50.0, 15.0, phys);

    properties (Constant)
        AXIS_AXIAL    = 0;
        AXIS_CORONAL  = 1;
        AXIS_SAGITTAL = 2;
    end

    properties (Constant, Access = private)
        RESP_FIELDS = {'minL','maxL','asym_amp','amp_mod_amp','amp_mod_freq', ...
                       'rr_var_amp','rr_var_freq'};

        CARD_FIELDS = {'lv_edv','lv_esv','rv_edv','rv_esv', ...
                       'la_min','la_max','ra_min','ra_max', ...
                       'hr_var_amp','hr_var_freq','v_amp_amp','v_amp_freq', ...
                       'a_amp_amp','a_amp_freq','bw_amp','bw_freq', ...
                       's_frac_base','s_frac_mod_amp','s_frac_mod_freq', ...
                       'ventricular_ejection_power','lv_filling_power', ...
                       'rv_filling_power','atrial_fill_power', ...
                       'atrial_emptying_power','atrial_phase_shift', ...
                       'atrial_bw_coupling','lv_kick_amp_frac', ...
                       'lv_kick_center','lv_kick_width','rv_kick_amp_frac', ...
                       'rv_kick_center','rv_kick_width','la_contr_amp_frac', ...
                       'la_contr_center','la_contr_width','ra_contr_amp_frac', ...
                       'ra_contr_center','ra_contr_width'};

        TISSUE_FIELDS = {'lung','heart','vessels_blood','bones','liver','stomach', ...
                         'body','lv_blood','rv_blood','la_blood','ra_blood'};

        TGEOM_FIELDS  = {'outer_radius','outer_height','tubes_height_fraction', ...
                         'tube_wall_thickness','gap_fraction'};

        SL_FIELDS     = {'skull','brain','right_big','left_big','top','middle_high', ...
                         'bottom_left','middle_low','bottom_center','bottom_right', ...
                         'extra_1','extra_2'};
    end

    properties (Access = private)
        cli_executable
    end

    methods

        function obj = GeometricMedicalPhantoms(cli_location)
            if nargin < 1
                cli_location = [];
            end
            obj.cli_executable = GeometricMedicalPhantoms.resolveCliExecutable(cli_location);
            obj.runCli({'info'});
        end

        function delete(~)
        end

        function ver = version(obj)
            output = obj.runCli({'info'});
            tokens = regexp(output, 'Package version:\s*([^\r\n]+)', 'tokens', 'once');
            if isempty(tokens)
                error('Unable to parse CLI version output: %s', strtrim(output));
            end
            ver = strtrim(tokens{1});
        end

        function n = signalLength(~, duration, fs)
            n = double(round(double(duration) * double(fs)));
        end

        function phys = respiratoryPhysiologyDefault(obj)
            phys = GeometricMedicalPhantoms.vecToStruct([2.4, 3.0, 0.2, 0.15, 0.05, 0.03, 0.03], obj.RESP_FIELDS);
        end

        function phys = cardiacPhysiologyDefault(obj)
            phys = GeometricMedicalPhantoms.vecToStruct([ ...
                130.0, 55.0, 140.0, 65.0, 30.0, 60.0, 30.0, 60.0, ...
                0.03, 0.1, 0.0, 0.08, 0.02, 0.09, 0.0, 0.03, ...
                0.35, 0.08, 0.1, 3.0, 2.2, 2.0, 1.5, 3.0, 0.7, 0.8, ...
                0.07, 0.92, 0.04, 0.06, 0.92, 0.05, 0.15, 0.95, 0.03, ...
                0.12, 0.95, 0.03], obj.CARD_FIELDS);
        end

        function ti = tissueIntensitiesDefault(obj)
            ti = GeometricMedicalPhantoms.vecToStruct([0.08, 0.65, 1.0, 0.85, 0.55, 0.9, 0.25, 0.98, 0.99, 0.97, 0.96], obj.TISSUE_FIELDS);
        end

        function tg = tubesGeometryDefault(obj)
            tg = GeometricMedicalPhantoms.vecToStruct([0.4, 0.8, 0.9, 0.025, 0.3], obj.TGEOM_FIELDS);
        end

        function ti = tubesIntensitiesDefault(~)
            ti.outer_cylinder = 0.25;
            ti.tube_wall = 0.0;
            ti.tube_fillings = [0.1, 0.3, 0.5, 0.7, 0.9, 1.0];
        end

        function ti = sheppLoganCtDefault(obj)
            ti = GeometricMedicalPhantoms.vecToStruct([2.0, -0.98, -0.02, -0.02, 0.01, 0.01, 0.01, 0.01, 0.01, 0.01, 0.02, -0.02], obj.SL_FIELDS);
        end

        function ti = sheppLoganMriDefault(obj)
            ti = GeometricMedicalPhantoms.vecToStruct([1.0, -0.8, -0.2, -0.2, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, -0.1], obj.SL_FIELDS);
        end

        function [t, signal] = generateRespiratorySignal(obj, duration, fs, rr, phys)
            if nargin < 5 || isempty(phys)
                phys = obj.respiratoryPhysiologyDefault();
            end
            out_path = GeometricMedicalPhantoms.tempPath('.json');
            temp_paths = {out_path};
            args = { ...
                'signals', 'respiratory', ...
                '--duration', GeometricMedicalPhantoms.numToCli(duration), ...
                '--fs', GeometricMedicalPhantoms.numToCli(fs), ...
                '--rate', GeometricMedicalPhantoms.numToCli(rr), ...
                '--format', 'json', ...
                '--out', out_path};
            if ~obj.structMatchesFields(phys, obj.respiratoryPhysiologyDefault(), obj.RESP_FIELDS)
                phys_path = GeometricMedicalPhantoms.writeJsonTemp(obj.structToJson(phys, obj.RESP_FIELDS), '.json');
                temp_paths{end + 1} = phys_path; %#ok<AGROW>
                args = [args, {'--physiology', phys_path}]; %#ok<AGROW>
            end
            cleanup = onCleanup(@() GeometricMedicalPhantoms.cleanupPaths(temp_paths)); %#ok<NASGU>
            obj.runCli(args);

            data = GeometricMedicalPhantoms.readJsonFile(out_path);
            t = double(data.t(:)');
            signal = double(data.signal(:)');
        end

        function [t, lv, rv, la, ra] = generateCardiacSignals(obj, duration, fs, hr, phys)
            if nargin < 5 || isempty(phys)
                phys = obj.cardiacPhysiologyDefault();
            end
            out_path = GeometricMedicalPhantoms.tempPath('.json');
            temp_paths = {out_path};
            args = { ...
                'signals', 'cardiac', ...
                '--duration', GeometricMedicalPhantoms.numToCli(duration), ...
                '--fs', GeometricMedicalPhantoms.numToCli(fs), ...
                '--rate', GeometricMedicalPhantoms.numToCli(hr), ...
                '--format', 'json', ...
                '--out', out_path};
            if ~obj.structMatchesFields(phys, obj.cardiacPhysiologyDefault(), obj.CARD_FIELDS)
                phys_path = GeometricMedicalPhantoms.writeJsonTemp(obj.structToJson(phys, obj.CARD_FIELDS), '.json');
                temp_paths{end + 1} = phys_path; %#ok<AGROW>
                args = [args, {'--physiology', phys_path}]; %#ok<AGROW>
            end
            cleanup = onCleanup(@() GeometricMedicalPhantoms.cleanupPaths(temp_paths)); %#ok<NASGU>
            obj.runCli(args);

            data = GeometricMedicalPhantoms.readJsonFile(out_path);
            t = double(data.t(:)');
            lv = double(data.lv(:)');
            rv = double(data.rv(:)');
            la = double(data.la(:)');
            ra = double(data.ra(:)');
        end

        function phantom = createSheppLoganPhantom3D(obj, nx, ny, nz, ti)
            if nargin < 5 || isempty(ti)
                ti = obj.sheppLoganCtDefault();
            end
            phantom = obj.runPhantomCommand('shepp-logan', [nx, ny, nz], ...
                'intensity', obj.sheppLoganIntensityArg(ti));
        end

        function slice = createSheppLoganPhantom2D(obj, nx, ny, axis, slice_pos, ti)
            if nargin < 4 || isempty(axis); axis = obj.AXIS_AXIAL; end
            if nargin < 5 || isempty(slice_pos); slice_pos = 0.0; end
            if nargin < 6 || isempty(ti); ti = obj.sheppLoganCtDefault(); end
            slice = obj.runPhantomCommand('shepp-logan', [nx, ny], ...
                'plane', GeometricMedicalPhantoms.axisToPlane(axis), ...
                'slice_position', slice_pos, ...
                'intensity', obj.sheppLoganIntensityArg(ti));
        end

        function phantom = createTubesPhantom3D(obj, nx, ny, nz, tg, ti)
            if nargin < 5 || isempty(tg); tg = obj.tubesGeometryDefault(); end
            if nargin < 6 || isempty(ti); ti = obj.tubesIntensitiesDefault(); end
            geometry = [];
            intensity = [];
            if ~obj.structMatchesFields(tg, obj.tubesGeometryDefault(), obj.TGEOM_FIELDS)
                geometry = obj.structToJson(tg, obj.TGEOM_FIELDS);
            end
            if ~GeometricMedicalPhantoms.tubesIntensitiesMatch(ti, obj.tubesIntensitiesDefault())
                intensity = GeometricMedicalPhantoms.tubesIntensitiesToJson(ti);
            end
            phantom = obj.runPhantomCommand('tubes', [nx, ny, nz], ...
                'geometry', geometry, ...
                'intensity', intensity);
        end

        function slice = createTubesPhantom2D(obj, nx, ny, axis, slice_pos, tg, ti)
            if nargin < 4 || isempty(axis); axis = obj.AXIS_AXIAL; end
            if nargin < 5 || isempty(slice_pos); slice_pos = 0.0; end
            if nargin < 6 || isempty(tg); tg = obj.tubesGeometryDefault(); end
            if nargin < 7 || isempty(ti); ti = obj.tubesIntensitiesDefault(); end
            geometry = [];
            intensity = [];
            if ~obj.structMatchesFields(tg, obj.tubesGeometryDefault(), obj.TGEOM_FIELDS)
                geometry = obj.structToJson(tg, obj.TGEOM_FIELDS);
            end
            if ~GeometricMedicalPhantoms.tubesIntensitiesMatch(ti, obj.tubesIntensitiesDefault())
                intensity = GeometricMedicalPhantoms.tubesIntensitiesToJson(ti);
            end
            slice = obj.runPhantomCommand('tubes', [nx, ny], ...
                'plane', GeometricMedicalPhantoms.axisToPlane(axis), ...
                'slice_position', slice_pos, ...
                'geometry', geometry, ...
                'intensity', intensity);
        end

        function phantom = createTorsoPhantom3D(obj, nx, ny, nz, varargin)
            p = inputParser;
            addParameter(p, 'resp_signal', []);
            addParameter(p, 'cardiac_lv', []);
            addParameter(p, 'cardiac_rv', []);
            addParameter(p, 'cardiac_la', []);
            addParameter(p, 'cardiac_ra', []);
            addParameter(p, 'tissue', []);
            parse(p, varargin{:});

            ti = p.Results.tissue;
            if isempty(ti)
                ti = obj.tissueIntensitiesDefault();
            end

            phantom = obj.runTorsoCommand([nx, ny, nz], [], 0.0, ...
                p.Results.resp_signal, p.Results.cardiac_lv, p.Results.cardiac_rv, ...
                p.Results.cardiac_la, p.Results.cardiac_ra, ti);
        end

        function phantom = createTorsoPhantom2D(obj, nx, ny, axis, slice_pos, varargin)
            if nargin < 4 || isempty(axis); axis = obj.AXIS_AXIAL; end
            if nargin < 5 || isempty(slice_pos); slice_pos = 0.0; end

            p = inputParser;
            addParameter(p, 'resp_signal', []);
            addParameter(p, 'cardiac_lv', []);
            addParameter(p, 'cardiac_rv', []);
            addParameter(p, 'cardiac_la', []);
            addParameter(p, 'cardiac_ra', []);
            addParameter(p, 'tissue', []);
            parse(p, varargin{:});

            ti = p.Results.tissue;
            if isempty(ti)
                ti = obj.tissueIntensitiesDefault();
            end

            phantom = obj.runTorsoCommand([nx, ny], GeometricMedicalPhantoms.axisToPlane(axis), slice_pos, ...
                p.Results.resp_signal, p.Results.cardiac_lv, p.Results.cardiac_rv, ...
                p.Results.cardiac_la, p.Results.cardiac_ra, ti);
        end

    end

    methods (Access = private)

        function output = runCli(obj, args)
            cmd = GeometricMedicalPhantoms.buildShellCommand(obj.cli_executable, args);
            [status, output] = system(cmd);
            if status ~= 0
                error('geomphantoms CLI failed (%d): %s', status, strtrim(output));
            end
        end

        function value = sheppLoganIntensityArg(obj, ti)
            if obj.structMatchesFields(ti, obj.sheppLoganCtDefault(), obj.SL_FIELDS)
                value = 'ct';
            elseif obj.structMatchesFields(ti, obj.sheppLoganMriDefault(), obj.SL_FIELDS)
                value = 'mri';
            else
                value = obj.structToJson(ti, obj.SL_FIELDS);
            end
        end

        function payload = structToJson(~, st, fields)
            payload = struct();
            for idx = 1:numel(fields)
                payload.(fields{idx}) = double(st.(fields{idx}));
            end
        end

        function tf = structMatchesFields(~, lhs, rhs, fields)
            tf = true;
            for idx = 1:numel(fields)
                field = fields{idx};
                if ~isequal(double(lhs.(field)), double(rhs.(field)))
                    tf = false;
                    return;
                end
            end
        end

        function phantom = runPhantomCommand(obj, phantom_type, size_vec, varargin)
            p = inputParser;
            addParameter(p, 'plane', '');
            addParameter(p, 'slice_position', []);
            addParameter(p, 'intensity', []);
            addParameter(p, 'geometry', []);
            parse(p, varargin{:});

            out_path = GeometricMedicalPhantoms.tempPath('.mat');
            temp_paths = {out_path};
            args = {'phantom', phantom_type, '--size', GeometricMedicalPhantoms.sizeToCli(size_vec), '--format', 'mat', '--no-meta', '--out', out_path};

            if ~isempty(p.Results.plane)
                args = [args, {'--plane', p.Results.plane}]; %#ok<AGROW>
            end
            if ~isempty(p.Results.slice_position)
                args = [args, {'--slice-position', GeometricMedicalPhantoms.numToCli(p.Results.slice_position)}]; %#ok<AGROW>
            end
            if ~isempty(p.Results.intensity)
                if ischar(p.Results.intensity) || (isstring(p.Results.intensity) && isscalar(p.Results.intensity))
                    args = [args, {'--intensity', char(p.Results.intensity)}]; %#ok<AGROW>
                else
                    intensity_path = GeometricMedicalPhantoms.writeJsonTemp(p.Results.intensity, '.json');
                    temp_paths{end+1} = intensity_path; %#ok<AGROW>
                    args = [args, {'--intensity', intensity_path}]; %#ok<AGROW>
                end
            end
            if ~isempty(p.Results.geometry)
                geometry_path = GeometricMedicalPhantoms.writeJsonTemp(p.Results.geometry, '.json');
                temp_paths{end+1} = geometry_path; %#ok<AGROW>
                args = [args, {'--geometry', geometry_path}]; %#ok<AGROW>
            end

            cleanup = onCleanup(@() GeometricMedicalPhantoms.cleanupPaths(temp_paths)); %#ok<NASGU>
            obj.runCli(args);
            phantom = GeometricMedicalPhantoms.readPhantomOutput(out_path);
        end

        function phantom = runTorsoCommand(obj, size_vec, plane, slice_pos, resp_signal, cardiac_lv, cardiac_rv, cardiac_la, cardiac_ra, tissue)
            out_path = GeometricMedicalPhantoms.tempPath('.mat');
            temp_paths = {out_path};
            args = {'phantom', 'torso', '--size', GeometricMedicalPhantoms.sizeToCli(size_vec), '--format', 'mat', '--no-meta', '--out', out_path};

            if ~obj.structMatchesFields(tissue, obj.tissueIntensitiesDefault(), obj.TISSUE_FIELDS)
                tissue_path = GeometricMedicalPhantoms.writeJsonTemp(obj.structToJson(tissue, obj.TISSUE_FIELDS), '.json');
                temp_paths{end + 1} = tissue_path; %#ok<AGROW>
                args = [args, {'--intensity', tissue_path}]; %#ok<AGROW>
            end

            if ~isempty(plane)
                args = [args, {'--plane', plane, '--slice-position', GeometricMedicalPhantoms.numToCli(slice_pos)}]; %#ok<AGROW>
            end

            if ~isempty(resp_signal)
                resp_path = GeometricMedicalPhantoms.writeJsonTemp(double(resp_signal(:)'), '.json');
                temp_paths{end+1} = resp_path; %#ok<AGROW>
                args = [args, {'--resp-signal', resp_path}]; %#ok<AGROW>
            end

            cardiac = GeometricMedicalPhantoms.makeCardiacPayload(cardiac_lv, cardiac_rv, cardiac_la, cardiac_ra);
            if ~isempty(cardiac)
                card_path = GeometricMedicalPhantoms.writeJsonTemp(cardiac, '.json');
                temp_paths{end+1} = card_path; %#ok<AGROW>
                args = [args, {'--cardiac-signal', card_path}]; %#ok<AGROW>
            end

            cleanup = onCleanup(@() GeometricMedicalPhantoms.cleanupPaths(temp_paths)); %#ok<NASGU>
            obj.runCli(args);
            phantom = GeometricMedicalPhantoms.readPhantomOutput(out_path);
        end

    end

    methods (Static, Access = private)

        function st = vecToStruct(v, fields)
            v = double(v(:)');
            st = struct();
            for i = 1:numel(fields)
                st.(fields{i}) = v(i);
            end
        end

        function payload = tubesIntensitiesToJson(ti)
            payload = struct();
            payload.outer_cylinder = double(ti.outer_cylinder);
            payload.tube_wall = double(ti.tube_wall);
            payload.tube_fillings = double(ti.tube_fillings(:)');
        end

        function tf = tubesIntensitiesMatch(lhs, rhs)
            tf = isequal(double(lhs.outer_cylinder), double(rhs.outer_cylinder)) && ...
                 isequal(double(lhs.tube_wall), double(rhs.tube_wall)) && ...
                 isequal(double(lhs.tube_fillings(:)'), double(rhs.tube_fillings(:)'));
        end

        function payload = makeCardiacPayload(lv, rv, la, ra)
            parts = {lv, rv, la, ra};
            present = cellfun(@(x) ~isempty(x), parts);
            if ~any(present)
                payload = [];
                return;
            end
            if ~all(present)
                error('cardiac_lv, cardiac_rv, cardiac_la, and cardiac_ra must either all be provided or all be empty.');
            end
            lengths = [numel(lv), numel(rv), numel(la), numel(ra)];
            if numel(unique(lengths)) ~= 1
                error('Cardiac volume inputs must all have the same length.');
            end
            payload = struct('lv', double(lv(:)'), 'rv', double(rv(:)'), 'la', double(la(:)'), 'ra', double(ra(:)'));
        end

        function output = readPhantomOutput(path)
            loaded = load(path, 'phantom');
            if ~isfield(loaded, 'phantom')
                error('MATLAB CLI output file %s does not contain a phantom variable.', path);
            end
            output = loaded.phantom;
            output = GeometricMedicalPhantoms.squeezeTrailingSingleton(output);
        end

        function output = squeezeTrailingSingleton(output)
            if ndims(output) >= 4 && size(output, ndims(output)) == 1
                output = output(:, :, :, 1);
            elseif ndims(output) == 3 && size(output, 3) == 1
                output = output(:, :, 1);
            end
        end

        function obj = readJsonFile(path)
            obj = jsondecode(fileread(path));
        end

        function path = writeJsonTemp(value, extension)
            path = GeometricMedicalPhantoms.tempPath(extension);
            GeometricMedicalPhantoms.writeJsonFile(path, value);
        end

        function writeJsonFile(path, value)
            fid = fopen(path, 'w');
            if fid < 0
                error('Unable to open temporary file for writing: %s', path);
            end
            cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
            fwrite(fid, jsonencode(value), 'char');
        end

        function path = tempPath(extension)
            path = [tempname, extension];
        end

        function cleanupPaths(paths)
            for i = 1:numel(paths)
                if exist(paths{i}, 'file')
                    delete(paths{i});
                end
            end
        end

        function text = sizeToCli(size_vec)
            values = arrayfun(@(v) sprintf('%d', round(double(v))), double(size_vec(:)'), 'UniformOutput', false);
            text = strjoin(values, ',');
        end

        function text = numToCli(value)
            text = sprintf('%.17g', double(value));
        end

        function plane = axisToPlane(axis)
            axis = double(axis);
            if axis == 0
                plane = 'axial';
            elseif axis == 1
                plane = 'coronal';
            elseif axis == 2
                plane = 'sagittal';
            else
                error('Unsupported axis value: %g', axis);
            end
        end

        function exe = resolveCliExecutable(cli_location)
            exe_name = GeometricMedicalPhantoms.executableName();
            candidates = {};

            if nargin >= 1 && ~isempty(cli_location)
                cli_location = char(cli_location);
                if isfolder(cli_location)
                    candidates = [candidates, { ...
                        fullfile(cli_location, 'bin', exe_name), ...
                        fullfile(cli_location, 'app', 'build', 'bin', exe_name), ...
                        fullfile(cli_location, exe_name)}]; %#ok<AGROW>
                else
                    candidates{end+1} = cli_location; %#ok<AGROW>
                end
            end

            toolbox_dir = fileparts(mfilename('fullpath'));
            repo_root = fullfile(toolbox_dir, '..', '..', '..');
            candidates = [candidates, {fullfile(repo_root, 'app', 'build', 'bin', exe_name)}]; %#ok<AGROW>

            for i = 1:numel(candidates)
                if exist(candidates{i}, 'file')
                    exe = char(candidates{i});
                    return;
                end
            end

            exe = GeometricMedicalPhantoms.findExecutableOnPath(exe_name);
            if ~isempty(exe)
                return;
            end

            error(['Unable to locate the geomphantoms CLI executable. ', ...
                   'Build the CLI in app/build, add it to PATH, or pass its location to GeometricMedicalPhantoms(...).']);
        end

        function exe = findExecutableOnPath(exe_name)
            if ispc
                lookup_cmd = ['where ', GeometricMedicalPhantoms.shellQuote(exe_name)];
            else
                lookup_cmd = ['command -v ', GeometricMedicalPhantoms.shellQuote(exe_name)];
            end
            [status, output] = system(lookup_cmd);
            if status == 0
                lines = regexp(strtrim(output), '\r?\n', 'split');
                exe = strtrim(lines{1});
            else
                exe = '';
            end
        end

        function exe_name = executableName()
            if ispc
                exe_name = 'geomphantoms.exe';
            else
                exe_name = 'geomphantoms';
            end
        end

        function cmd = buildShellCommand(executable, args)
            quoted = cell(1, numel(args) + 1);
            quoted{1} = GeometricMedicalPhantoms.shellQuote(executable);
            for i = 1:numel(args)
                quoted{i + 1} = GeometricMedicalPhantoms.shellQuote(char(args{i}));
            end
            cmd = [GeometricMedicalPhantoms.runtimeEnvPrefix(executable), strjoin(quoted, ' ')];
        end

        function prefix = runtimeEnvPrefix(executable)
            prefix = '';
            if ispc
                return;
            end

            bin_dir = fileparts(executable);
            lib_dir = fullfile(fileparts(bin_dir), 'lib');
            julia_lib_dir = fullfile(lib_dir, 'julia');
            lib_paths = {};
            if isfolder(julia_lib_dir)
                lib_paths{end + 1} = julia_lib_dir; %#ok<AGROW>
            end
            if isfolder(lib_dir)
                lib_paths{end + 1} = lib_dir; %#ok<AGROW>
            end
            if isempty(lib_paths)
                return;
            end

            if ismac
                env_name = 'DYLD_LIBRARY_PATH';
            else
                env_name = 'LD_LIBRARY_PATH';
            end

            current = getenv(env_name);
            if isempty(current)
                joined = strjoin(lib_paths, ':');
            else
                joined = [strjoin(lib_paths, ':'), ':', current];
            end
            prefix = [env_name, '=', GeometricMedicalPhantoms.shellQuote(joined), ' '];
        end

        function value = shellQuote(value)
            value = char(value);
            if ispc
                value = ['"', strrep(value, '"', '""'), '"'];
            else
                value = ['''', strrep(value, '''', '''"''"'''), ''''];
            end
        end

    end

end
