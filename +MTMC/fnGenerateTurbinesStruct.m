function [ Turbines ] = fnGenerateTurbinesStruct( caTurbineSection, NumTSs, trMesh2D )
%FNGENERATETURBINESSTRUCT Generate the Turbines structure from the .m3fm
%file contents, for the first iteration
%   Inputs: caTurbineSection: nx1 cell array of lines of the TURBINES
%           section of the model definition file.
%           NumTSs: Number of timesteps in the model.
%           trMesh: Matlab "triangulation" object containing the model
%                   mesh, *without z values* (because it's really a 2D mesh with
%                   prisms.
%
%   Outputs: Turbines. Structure array with turbine info.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

NumTurbines = str2num(MTMC.fnReadDHIValue( caTurbineSection, 'number_of_turbines' ));

% Set up & preallocate data structures:
% struct Turbines: x, y, orientation, Ct/Cl curve (matrix),
%                       diameter, element #, alpha (correction factor -
%                       TSs x Iterations), force (TS x iterations)
Turbines = struct;
Turbines.x = nan;  % do NOT try using spherical coordinates here.
Turbines.y = nan;
Turbines.z = nan;   % elevation of hub.
Turbines.o = nan;  %orientation
Turbines.Diameter = nan;
Turbines.ElementNo = nan;   %the mesh element that each turbine is in.
Turbines.Alpha = nan(NumTSs, 1);    % first iteration.
Turbines.Force = nan(NumTSs, 1);    % first iteration. We don't actually need force for this calculation, but it'll be nice to be able to plot it.
Turbines = repmat(Turbines, NumTurbines, 1);
%still need fields for Ct and Cl matrices, but can't preallocate those
%without knowing the number of speeds and directions, which may vary by
%turbine.

for t = 1:NumTurbines   %for each turbine
    caTurb = MTMC.fnExtractM3FMSection( caTurbineSection, [ 'TURBINE_' num2str(t) ] );
    % get the basic info that's simply a matter of reading the file
    Turbines(t).x = str2num(MTMC.fnReadDHIValue( caTurb, 'x' ));
    Turbines(t).y = str2num(MTMC.fnReadDHIValue( caTurb, 'y' ));
    Turbines(t).z = str2num(MTMC.fnReadDHIValue( caTurb, 'centroid' ));
    Turbines(t).o = str2num(MTMC.fnReadDHIValue( caTurb, 'orientation' )) * 2*pi / 360; %convert to radians
    Turbines(t).Diameter = str2num(MTMC.fnReadDHIValue( caTurb, 'diameter' ));
    
    %Now the ct/cl stuff
    NumDirs = str2num( MTMC.fnReadDHIValue( caTurb, 'number_of_directions' ));
    MinDir = str2num( MTMC.fnReadDHIValue( caTurb, 'minimum_direction' ));
    MaxDir = str2num( MTMC.fnReadDHIValue( caTurb, 'maximum_direction' ));
    NumSpeeds = str2num( MTMC.fnReadDHIValue( caTurb, 'number_of_speeds' ));
    MinSpeed = str2num( MTMC.fnReadDHIValue( caTurb, 'minimum_speed' ));
    MaxSpeed = str2num( MTMC.fnReadDHIValue( caTurb, 'maximum_speed' ));
    
    Dirs = linspace(MinDir, MaxDir, NumDirs) .* (2*pi/360); %convert to radians
    Speeds = linspace(MinSpeed, MaxSpeed, NumSpeeds);
    %So we have the directions and speeds for Cd/Cl tables, but now we need
    % the actual Cd/Cl values.
    CdTable = nan(NumSpeeds, NumDirs);  % rows speeds, cols dirs
    ClTable = nan(NumSpeeds, NumDirs);
    for n = 1:NumSpeeds
        tmp = MTMC.fnReadDHIValue( caTurb, [ 'cd_' num2str(n) ] );    %this gives us a comma-seperated list of values for a speed
        CdTable(n,:) = str2num(tmp);    %should fill in the row of the matrix.
        tmp = MTMC.fnReadDHIValue( caTurb, [ 'cl_' num2str(n) ] );
        ClTable(n,:) = str2num(tmp);
    end
    
    % What we actually want to store is not these raw values, but a matlab
    % griddedInterpolant object for each of Cd and Cl for each turbine.
    % This will make it fast & easy to query in the future.
    
    %The linear and nearest
    % flags mean linear interpolation within the matrix, but extrapolation beyond it by
    % using the nearest value given. This matches how MIKE works.
    
    Turbines(t).giCd = griddedInterpolant({Speeds, Dirs}, CdTable, 'linear', 'nearest');
    Turbines(t).giCl = griddedInterpolant({Speeds, Dirs}, ClTable, 'linear', 'nearest');
        
end
    
% now find which mesh element each turbine lies in
els = pointLocation(trMesh2D, [Turbines.x]', [Turbines.y]');
%and now I need a way to put the resulting 950x1 array into a new field of
%the struct. This is a horrific MATLABism: first convert to a cell array,
%then convert that cell array to a comma-seperated list, and make a
%comma-seperated list of the target array equal to that.
tmp = num2cell(els);
[Turbines.ElementNo] = tmp{:};
clear tmp;

end

