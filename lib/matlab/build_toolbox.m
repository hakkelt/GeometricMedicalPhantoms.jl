function build_toolbox(varargin)
% BUILD_TOOLBOX  Package the GeometricMedicalPhantoms MATLAB toolbox.
%
% USAGE
%   build_toolbox()                   – uses version from Contents.m (1.0.2)
%   build_toolbox('1.2.3')            – override version string
%   build_toolbox('1.2.3', out_dir)  – write .mltbx to out_dir
%
% The toolbox is packaged from lib/matlab/toolbox/.  No CLI binary is bundled.
% Users must install or build the standalone `geomphantoms` CLI separately.
%
% This script is designed to be called from CI:
%   matlab -batch "build_toolbox('1.0.2')"
%
% Toolbox UUID (stable across releases): c297bd51-60f5-42e7-80e4-f985777cb71a

    % ------------------------------------------------------------------ %
    % Arguments                                                            %
    % ------------------------------------------------------------------ %
    version_str = '1.0.2';
    if nargin >= 1
        version_str = char(varargin{1});
    end

    project_root   = fileparts(mfilename('fullpath'));
    toolbox_folder = fullfile(project_root, 'lib', 'matlab', 'toolbox');

    % The toolbox is platform-independent (pure .m files only).
    out_name = 'GeometricMedicalPhantoms-matlab.mltbx';

    if nargin >= 2
        out_dir = char(varargin{2});
    else
        out_dir = project_root;
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
