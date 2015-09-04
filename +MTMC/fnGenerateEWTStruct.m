function [ EWT ] = fnGenerateEWTStruct( Turbines, NumTSs, trMesh )
%FNGENERATEEWTSTRUCT Generate the EWT (Elements With Turbines) data
%structure on the first iteration.
%   Inputs: caTurbineSection: nx1 cell array of lines of the TURBINES
%           section of the model definition file.
%           NumTSs: Number of timesteps in the model.
%           trMesh: Matlab "triangulation" object containing the model
%                   mesh, *without z values* (because it's really a 2D mesh with
%                   prisms.
%
%   Outputs: Turbines. Structure array with turbine info.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

ElementNos = unique([Turbines.ElementNo]);
NumEs = length(ElementNos);        %how many elements have turbines in? May be fewer than number of turbines if an element has more than one.

EWT = struct;
EWT.ElementNo = nan;
EWT.TinE = nan;                     % list of which turbines are in this element.
EWT.CurrentSpeed = nan(NumTSs,1);   % TS x iteration
EWT.CurrentDirection = nan(NumTSs,1);
EWT.CSA = nan(NumTSs,1);  %element CSA, TS x iteration
EWT.SeabedElevation = nan;  %seabed elevation wrt MSL. This doesn't change.
EWT.Depth = nan(NumTSs, 1);    %Depth of water in this element at this TS (positive numbers). Will be -SeabedElevation when water is at MSL, but may change with surface elevation in future.
EWT.DeltaZ = nan(NumTSs, 1);   %vertical height of sigma layer.
EWT = repmat(EWT, NumEs, 1);

for e = 1:NumEs
    EWT(e).ElementNo = ElementNos(e);  
    EWT(e).TinE = find([Turbines.ElementNo] == EWT(e).ElementNo);   %which turbines are in this element?
    
    % what's the seabed elevation in this element? FIXME We'll just take the mean
    % of the vertices for now; a more sophisticated interpolation taking wider info
    % may be possible. Worthwhile???
    vertices = trMesh.ConnectivityList(ElementNos(e),:);
    vZ = trMesh.Points(vertices, 3);    % this gives the z-values for the 3 (or 4?) vertices that define this element.
    cz = mean(vZ);
    EWT(e).SeabedElevation = cz;
end

end

