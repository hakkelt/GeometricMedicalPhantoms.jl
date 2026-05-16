% GeometricMedicalPhantoms Toolbox
% Version 1.0.2
%
% CLASSES
%   GeometricMedicalPhantoms - MATLAB interface to GeometricMedicalPhantoms
%                              via the geomphantoms CLI
%
% INSTALLATION
%   1. Install or build the geomphantoms CLI executable.
%   2. Add this toolbox directory to the MATLAB path:
%
%       addpath('/path/to/toolbox')
%
%   Then in MATLAB:
%       lib = GeometricMedicalPhantoms('/path/to/geomphantoms');
%
% USAGE
%   lib = GeometricMedicalPhantoms();   % auto-detects app/build/bin or PATH
%
%   Create phantoms:
%       phantom = lib.createSheppLoganPhantom3D(128, 128, 128);
%       [t, sig] = lib.generateRespiratorySignal(60, 50, 15);
%
% For more information see:
%   https://hakkelt.github.io/GeometricMedicalPhantoms.jl

% Copyright (c) hakkelt
