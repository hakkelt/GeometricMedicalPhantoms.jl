% smoke_test_matlab.m — minimal smoke test for the GeometricMedicalPhantoms MATLAB wrapper.
%
% Usage (from lib/test/):
%   matlab -batch "smoke_test_matlab"
%
% Usage with explicit Julia project path:
%   matlab -batch "smoke_test_matlab('/path/to/GeometricMedicalPhantoms')"
%
% Prerequisites:
%   - Julia installed and on PATH
%   - GeometricMedicalPhantoms.jl installed in the Julia environment
%   - Mex.jl installed (run lib/matlab/setup.jl once)

function smoke_test_matlab(julia_project)

    if nargin < 1; julia_project = []; end

    % Locate the MATLAB toolbox relative to this file.
    test_dir    = fileparts(mfilename('fullpath'));
    toolbox_dir = fullfile(test_dir, '..', 'matlab', 'toolbox');
    addpath(toolbox_dir);

    failures = {};

    function ok = chk(cond, name, detail)
        if nargin < 3; detail = ''; end
        if cond
            fprintf('[PASS] %s\n', name);
            ok = true;
        else
            if isempty(detail)
                fprintf(2, '[FAIL] %s\n', name);
            else
                fprintf(2, '[FAIL] %s: %s\n', name, detail);
            end
            failures{end+1} = name; %#ok<AGROW>
            ok = false;
        end
    end

    % ----------------------------------------------------------------
    % Construct wrapper
    % ----------------------------------------------------------------
    try
        lib = GeometricMedicalPhantoms(julia_project);
    catch ME
        fprintf(2, '[FAIL] GeometricMedicalPhantoms constructor: %s\n', ME.message);
        error('Constructor failed — cannot continue smoke tests.');
    end

    % ----------------------------------------------------------------
    % Version
    % ----------------------------------------------------------------
    ver = lib.version();
    fprintf('[version] %s\n', ver);
    chk(ischar(ver) && ~isempty(ver), 'version returns non-empty string');

    % ----------------------------------------------------------------
    % Shepp-Logan 3-D
    % ----------------------------------------------------------------
    sl3d = lib.createSheppLoganPhantom3D(16, 16, 16);
    nonzero = nnz(sl3d);
    fprintf('[shepp_logan_3d] %d / %d non-zero voxels\n', nonzero, numel(sl3d));
    chk(isequal(size(sl3d), [16 16 16]), 'shepp_logan_3d shape', ...
        sprintf('got %s', mat2str(size(sl3d))));
    chk(nonzero > 0, 'shepp_logan_3d has non-zero voxels');

    % ----------------------------------------------------------------
    % Shepp-Logan 2-D
    % ----------------------------------------------------------------
    sl2d = lib.createSheppLoganPhantom2D(32, 32, lib.AXIS_AXIAL);
    fprintf('[shepp_logan_2d] first value: %f\n', sl2d(1,1));
    chk(isequal(size(sl2d), [32 32]), 'shepp_logan_2d shape', ...
        sprintf('got %s', mat2str(size(sl2d))));

    % ----------------------------------------------------------------
    % Tubes 3-D
    % ----------------------------------------------------------------
    tg = lib.tubesGeometryDefault();
    ti = lib.tubesIntensitiesDefault();
    tubes3d = lib.createTubesPhantom3D(16, 16, 16, tg, ti);
    nonzero_t = nnz(tubes3d);
    fprintf('[tubes_3d] %d / %d non-zero voxels\n', nonzero_t, numel(tubes3d));
    chk(isequal(size(tubes3d), [16 16 16]), 'tubes_3d shape', ...
        sprintf('got %s', mat2str(size(tubes3d))));
    chk(nonzero_t > 0, 'tubes_3d has non-zero voxels');

    % ----------------------------------------------------------------
    % Signal length
    % ----------------------------------------------------------------
    n = lib.signalLength(10.0, 50.0);
    fprintf('[signal_length] 10 s @ 50 Hz -> %d samples\n', n);
    chk(n == 500, 'signal_length', sprintf('expected 500, got %d', n));

    % ----------------------------------------------------------------
    % Respiratory signal
    % ----------------------------------------------------------------
    [t_resp, sig] = lib.generateRespiratorySignal(10.0, 50.0, 15.0);
    sig_min = min(sig);  sig_max = max(sig);
    fprintf('[respiratory] range [%.3f, %.3f] L\n', sig_min, sig_max);
    chk(numel(t_resp) == n && numel(sig) == n, 'respiratory signal length');
    chk(sig_min >= 1.0 && sig_max <= 5.0, 'respiratory signal in expected range [1,5] L', ...
        sprintf('got [%.3f, %.3f]', sig_min, sig_max));

    % ----------------------------------------------------------------
    % Cardiac signals
    % ----------------------------------------------------------------
    [~, lv, rv, la, ra] = lib.generateCardiacSignals(5.0, 200.0, 70.0);
    fprintf('[cardiac] lv(1)=%.1f mL, rv(1)=%.1f mL, la(1)=%.1f mL, ra(1)=%.1f mL\n', ...
            lv(1), rv(1), la(1), ra(1));
    chk(lv(1) >= 10.0 && lv(1) <= 300.0, 'cardiac LV volume in range', ...
        sprintf('lv(1)=%.1f', lv(1)));

    % ----------------------------------------------------------------
    % Static torso 3-D
    % ----------------------------------------------------------------
    tissue = lib.tissueIntensitiesDefault();
    torso  = lib.createTorsoPhantom3D(16, 16, 16, 'tissue', tissue);
    nonzero_tor = nnz(torso);
    fprintf('[torso_3d] %d / %d non-zero voxels (1 frame)\n', nonzero_tor, 16*16*16);
    chk(size(torso, 1) == 16 && size(torso, 2) == 16 && size(torso, 3) == 16, ...
        'torso_3d spatial shape', sprintf('got %s', mat2str(size(torso))));
    chk(nonzero_tor > 0, 'torso_3d has non-zero voxels');

    % ----------------------------------------------------------------
    % Result
    % ----------------------------------------------------------------
    if isempty(failures)
        fprintf('\n=== All MATLAB smoke tests passed ===\n');
    else
        fprintf(2, '\n=== %d smoke test(s) FAILED ===\n', numel(failures));
        error('GeometricMedicalPhantoms:smokeTestFailed', ...
              '%d smoke test(s) failed', numel(failures));
    end
end
