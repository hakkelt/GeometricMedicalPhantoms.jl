function build_toolbox(varargin)
% BUILD_TOOLBOX  Package the GeometricMedicalPhantoms MATLAB toolbox.
%
% USAGE
%   build_toolbox()                   – uses version from Project.toml
%   build_toolbox('1.2.3')            – override version string
%   build_toolbox('1.2.3', out_dir)  – write .mltbx to out_dir
%
% The toolbox is packaged from lib/matlab/toolbox/.  No CLI binary is bundled.
% Users must install or build the standalone `geomphantoms` CLI separately.
%
% This script is designed to be called from CI:
%   matlab -batch "build_toolbox('1.0.3')"
%
% Toolbox UUID (stable across releases): c297bd51-60f5-42e7-80e4-f985777cb71a

    % ------------------------------------------------------------------ %
    % Arguments                                                            %
    % ------------------------------------------------------------------ %
    default_version = read_project_version();
    version_str = default_version;
    if nargin >= 1
        version_str = normalize_toolbox_version(char(varargin{1}), default_version);
    end

    toolbox_root   = fileparts(mfilename('fullpath'));
    toolbox_folder = fullfile(toolbox_root, 'toolbox');

    % The toolbox is platform-independent (pure .m files only).
    out_name = 'GeometricMedicalPhantoms-matlab.mltbx';

    if nargin >= 2
        out_dir = char(varargin{2});
    else
        out_dir = toolbox_root;
    end
    output_file = fullfile(out_dir, out_name);

    % ------------------------------------------------------------------ %
    % Package                                                              %
    % ------------------------------------------------------------------ %
    toolbox_id = 'c297bd51-60f5-42e7-80e4-f985777cb71a';
    opts = matlab.addons.toolbox.ToolboxOptions(toolbox_folder, toolbox_id);

    opts.ToolboxName    = 'GeometricMedicalPhantoms';
    opts.ToolboxVersion = version_str;
    opts.AuthorName     = 'Tamás Hakkel';
    opts.AuthorEmail    = '';
    opts.Summary        = 'Geometric medical phantoms for MRI/CT simulation';
    opts.Description    = [ ...
        'MATLAB interface to the GeometricMedicalPhantoms CLI. ' ...
        'Provides Shepp-Logan, Tubes, and Torso phantoms (2-D and 3-D) ' ...
        'with realistic respiratory and cardiac motion signals. ' ...
        'Requires the standalone geomphantoms CLI executable to be ' ...
        'installed or built locally.'];
    opts.OutputFile     = output_file;

    matlab.addons.toolbox.packageToolbox(opts);
    fprintf('Toolbox packaged: %s\n', output_file);
end

function version_str = normalize_toolbox_version(raw_version, default_version)
    version_str = strtrim(raw_version);
    if isempty(version_str)
        version_str = default_version;
        return;
    end

    if ~isempty(regexp(version_str, '^\d+\.\d+(\.\d+){0,2}$', 'once'))
        return;
    end

    numeric_prefix = regexp(version_str, '\d+\.\d+(\.\d+){0,2}', 'match', 'once');
    if ~isempty(numeric_prefix)
        version_str = numeric_prefix;
    else
        version_str = default_version;
    end
end

function version_str = read_project_version()
    version_str = '1.0.3';

    project_toml = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'Project.toml');
    if ~isfile(project_toml)
        return;
    end

    fid = fopen(project_toml, 'r');
    if fid == -1
        return;
    end

    cleaner = onCleanup(@() fclose(fid));
    while ~feof(fid)
        line = strtrim(fgetl(fid));
        tokens = regexp(line, '^version\s*=\s*"([^"]+)"$', 'tokens', 'once');
        if isempty(tokens)
            continue;
        end

        version_str = normalize_toolbox_version(tokens{1}, version_str);
        return;
    end
end
