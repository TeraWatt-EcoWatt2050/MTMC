function [ NumLayersIntersected ] = fnFindLayersForTurbine( HubElevation, Diameter, SeabedElevation, NumLayers, DeltaZ )
%FNFINDLAYERSFORTURBINE Finds how many sigma layers of a model a turbine rotor
%intersects.
%   HubElevation is the elevation of the centre of the turbine with respect
%   to mean sea level. Metres. Should be negative.
%   Diameter is the rotor diameter in metres.
%   SeabedElevation: Elevation of seabed with respect MSL. (i.e. depth, but
%                   negative)
%   NumLayers: Number of equal-spaced sigma layers in the model
%   DeltaZ: Vertical height of each layer. NB not the same as
%       -SeabedElevation/NumLayers, because water level may not be at MSL.
%
%   Output: LayersIntersected: Scalar giving the number of layers that are
%           intersected.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

if nargin < 5
    error('Not enough arguments.');
end
if Diameter <= 0
    error('Diameter must be positive');
end
if SeabedElevation >= 0
    error('SeabedElevation must be negative. Unless you''re trying to put turbines on land.');
end
if NumLayers < 1 | round(NumLayers) ~= NumLayers
    error('NumLayers must be a positive integer');
end
if DeltaZ <= 0
    error('DeltaZ must be positive.');
end
if HubElevation + Diameter / 2 > SeabedElevation + DeltaZ*NumLayers
    error('Turbine will stick out of the water!');
end
if HubElevation - Diameter / 2 < SeabedElevation
    error('Turbine will hit the seabed!');
end

SurfaceElevation = SeabedElevation + DeltaZ * NumLayers;
LayerBoundaries = SurfaceElevation:-DeltaZ:SeabedElevation;
% So the boundaries of layer n will be boundaries n and n+1. (top & bottom
% respectively)

TopLB = max(find(LayerBoundaries > (HubElevation + Diameter / 2) + 2*eps(SeabedElevation))); % have to worry about floating-point issues here - so adding tolerance to definitely include equalities in the comparator. From experiment, this seems to be how MIKE works.
BottomLB = min(find(LayerBoundaries < (HubElevation - Diameter / 2) - 2*eps(SeabedElevation)));

% So which layer is TopLB the top of, and which is BottomLB the bottom of?
TopL = TopLB;
BottomL = BottomLB - 1;

%output
NumLayersIntersected = BottomL - TopL + 1;  % +1 because we want the number of layers *including* TopL and BottomL.

end

