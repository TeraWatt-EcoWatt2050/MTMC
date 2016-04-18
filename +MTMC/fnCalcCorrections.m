function [ Corrections ] = fnCalcCorrections( angles, NumLayersIntersected, Cts, CSAs, TurbineRadius )
%FNCALCCORRECTIONS Calculates desired correction factors for MTMC
%   Calculates the desired corrections that should be applied to each
%   timestep for a given turbine.

%   Inputs: angles: vector, where values represent different timesteps, of 
%                    angle between the current direction and the turbine
%                    orientation (anticlockwise, in radians)
%           NumLayersIntersected: vector, where values represent different
%                    timesteps, of the number of layers intersected by the
%                    rotor
%           Ct:     vector of thrust coefficients for each timestep
%           CSAs:   vector, where values represent different timesteps, of
%                    cross-sectional areas of the element
%           TurbineRadius: what it says. Scalar, in metres.

%   Outputs:DesiredCorrections: vector, where values represent different
%                                timesteps, of the corrections that should
%                                be applied to the force calculation

% Copyright (C) Simon Waldman / Heriot-Watt University 2016

Ae = pi * TurbineRadius.^2 .* cos(angles);

% calculate nu, which is the proportion of the momentum passing
% through the turbine's element that is removed 
% FIXME WRONG IF MULTIPLE TURBINES IN CELL (but so is so much else)
nu = ( Cts .* Ae ./ NumLayersIntersected ) ./ CSAs;
Corrections = 4 ./ ( 1 + sqrt ( 1 - nu ) ).^2;

end

