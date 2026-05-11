% GeometricMedicalPhantoms Toolbox
% Version 1.0.2
%
% CLASSES
%   GeometricMedicalPhantoms - MATLAB interface to GeometricMedicalPhantoms
%                              via Julia (Mex.jl)
%
% INSTALLATION
%   1. Install Julia and add to PATH.
%   2. Run lib/matlab/setup.jl to install Julia dependencies.
%   3. Add this toolbox directory to the MATLAB path:
%
%       addpath('/path/to/toolbox')
%
%   Then in MATLAB:
%       lib = GeometricMedicalPhantoms();
%
% USAGE
%   lib = GeometricMedicalPhantoms();   % toolbox install (recommended)
%
%   Create phantoms:
%       phantom = lib.createSheppLoganPhantom3D(128, 128, 128);
%       [t, sig] = lib.generateRespiratorySignal(60, 50, 15);
%
% For more information see:
%   https://hakkelt.github.io/GeometricMedicalPhantoms.jl

% Copyright (c) hakkelt
