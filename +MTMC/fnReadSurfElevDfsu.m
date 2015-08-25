function [ SurfElevs ] = fnReadSurfElevDfsu( filename, EWTList )
%FNREADTURBINESDFS0 Read surface elevations at turbine locations from dfsu
%file.
% Written for MIKE 2012. May work with later versions, but untested. Will
% only work on a machine with MIKE Zero and the DHI Matlab toolbox
% installed (and, in the toolbox's case, on Matlab's search path)
%   Inputs:     filename = filename for .dfsu file containing the "Surface
%                       Elevation" item and covering area of turbines.
%               EWTList = vector of element numbers to look at
%   Outputs:    SurfElevs = 2D matrix of surface elevations in metres,
%                       where columns are elements and rows are timesteps.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

assert(nargin==2, 'Incorrect number of arguments');
assert(exist(filename, 'file'), 'dfs0 file not found.');

% Set things up for reading dfs files. This requires MIKE Zero to be
% installed.
NET.addAssembly('DHI.Generic.MikeZero.DFS');
import DHI.Generic.MikeZero.DFS.*;

% open the file
dfsu = DfsFileFactory.DfsuFileOpen(filename);
assert(isa(dfsu, 'DHI.Generic.MikeZero.DFS.dfsu.DfsuFile'), 'Failed to open dfsu file');

Items = fnFindDFSUItems(dfsu);
ItemNo = Items('Surface Elevation');
%FIXME check for itemno being nan, or empty, or whatever one gets if it
%isn't there.

results = fnMIKEReadElementAllTS(dfsu, ItemNo, EWTList);    %this will be a 3D matrix where the middle dimension is a singleton because it accounts for multiple layers but we only have one.
SurfElevs = reshape(results, size(results,1), size(results,3)); %doing this rather than squeeze means it doesn't break if there's only one element or only one TS.

end

