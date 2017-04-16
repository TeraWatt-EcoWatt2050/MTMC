function [ TurbineNums, Speeds, Directions, Drag ] = fnReadTurbinesDfs0( filename )
%FNREADTURBINESDFS0 Read speeds and directions from Turbine output dfs0
%file.
% Written for MIKE 2012. May work with later versions, but untested. Will
% only work on a machine with MIKE Zero and the DHI Matlab toolbox
% installed (and, in the toolbox's case, on Matlab's search path)
%   Inputs:     filename = filename for .dfs0 turbine output file
%   Outputs:    TurbineNums = 1xn array of turbine numbers included in this
%                           dfs0.
%               Speeds = tsxn array of current speeds (magnitudes of velocities)
%                        where ts = timestep and n = turbine number.
%                        Metres/second.
%               Directions = tsxn array of directions of current flow -
%                           direction that current is flowing *to*, in
%                           radians clockwise from North. (CHECK THIS)
%                           ts = timestep, n = turbine number.
%               Drag = tsxn array of drag force where ts = timestep, n =
%                       turbine number.

% NB Names of turbines must be the default "Turbine 1", "Turbine 2", etc.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

if nargin < 1
    error('Not enough arguments.');
end
if ~exist(filename, 'file')
    error('dfs0 file not found.');
end

%open the file
dfs0  = dfsTSO(filename);
NumTSs = get(dfs0,'NumTimeSteps');  %first "timestep" is initial conditions, and gives us one more timestep here in the dfs0 than in the config files. Remove it to match.

% read the item names into a cell array
caItemnames = get(dfs0, 'itemnames');

tmp = regexp(caItemnames, '^Turbine (\d+): Current speed$', 'tokens');
SpeedItems = find(~cellfun(@isempty, tmp));
% apologies for this being illegible. I couldn't find a more readable way
% to do it in matlab.
tmp2 = cellfun(@(q) [q{:}], tmp(SpeedItems));
TurbineNums = cellfun(@str2num, tmp2);

tmp = regexp(caItemnames, '^Turbine \d+: Current direction$');
DirItems = find(~cellfun(@isempty, tmp));

tmp = regexp(caItemnames, '^Turbine \d+: Drag force$');
DragItems = find(~cellfun(@isempty, tmp));

clear tmp tmp2;

if length(SpeedItems) ~= length(DirItems)
    error('Differnet number of speed and direction data items.');
end
NumTurbines = length(SpeedItems);

%preallocate output matrices
Speeds = nan(NumTSs, NumTurbines);
Directions = nan(NumTSs, NumTurbines);
Drag = nan(NumTSs, NumTurbines);

for n = 1:NumTurbines
    Speeds(:, n) = dfs0(SpeedItems(n), 0:end); 
    Directions(:, n) = dfs0(DirItems(n), 0:end);
    Drag(:, n) = dfs0(DragItems(n), 0:end);
end

close(dfs0);

end

