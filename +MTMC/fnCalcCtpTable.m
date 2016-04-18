function [ giCtp ] = fnCalcCtpTable( TurbineStruct, meanElementCSA, modeNumLayersIntersected, RefineFactor )
%FNCALCCTPTABLE Produces a table of corrected thrust coefficients, called
%   Ct-prime (Ctp)
%
%   Inputs: TurbineStruct: A Turbines(n) structure from MTMC.
%           meanElementCSA:The mean CSA for the element in question
%                           (averaged over timesteps)
%           modeNumLayersIntersected: The modal value for the number of
%                           layers intersected by the rotor
%           RefineFactor: Scalar. If this is 1, the number of speeds in the Ctp
%                           table is the same as the number in the Ct
%                           table. If this is 2, there are twice as many
%                           speeds, etc. Increase to increase correction
%                           accuracy (because MIKE's linear interpolation 
%                           isn't great for this application), at the 
%                           expense of .m3fm file size.

%   Outputs:    giCtp:  A griddedInterpolant object with the Ct-prime
%                        values


% Copyright (C) Simon Waldman / Heriot-Watt University 2016

%FIXME check inputs.

NumCtpSpeeds = length(TurbineStruct.giCd.GridVectors{1}) * RefineFactor;
MinCtSpeed = TurbineStruct.giCd.GridVectors{1}(1);
MaxCtSpeed = TurbineStruct.giCd.GridVectors{1}(end);
CtpTableSpeeds = linspace(MinCtSpeed, MaxCtSpeed, NumCtpSpeeds);

NumCtpAngles = length(TurbineStruct.giCd.GridVectors{2});
MinCtAngle = TurbineStruct.giCd.GridVectors{2}(1);
MaxCtAngle = TurbineStruct.giCd.GridVectors{2}(end);
CtpTableAngles = linspace(MinCtAngle, MaxCtAngle, NumCtpAngles);

[ CtpTableX, CtpTableY ] = meshgrid( CtpTableAngles, CtpTableSpeeds );

%FIXME the above is messy and probably slow. Can it be optimised, maybe
%using the griddedInterpolant more directly instead of the meshgrid step?

CtValues = TurbineStruct.giCd(CtpTableY, CtpTableX);

corrections = MTMC.fnCalcCorrections( 0, modeNumLayersIntersected, CtValues, meanElementCSA, TurbineStruct.Diameter / 2 );
%FIXME this currently assumes weathervaning turbine - same corrections
%applied to all directions.
CtpValues = CtValues .* corrections; %yes, Ctp values *can* be > 1.

giCtp = griddedInterpolant( {CtpTableSpeeds, CtpTableAngles}, CtpValues, 'linear', 'nearest' ); %not the best way of interpolating for this data, but it's what MIKE will do.

end

