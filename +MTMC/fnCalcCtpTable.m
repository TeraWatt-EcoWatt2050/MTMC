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

%the first thing we need to do is convert the u0 values that we have to
%u_cell values. We'll calculate the value of alpha to use for this
%conversion using the value of Ct that corresponds to that u0 value.

u0Values = TurbineStruct.giCd.GridVectors{1};
CtValues = TurbineStruct.giCd.Values;
alphas = MTMC.fnCalcCorrections( 0, modeNumLayersIntersected, CtValues(:,1), meanElementCSA, TurbineStruct.Diameter / 2 );
u_cellValues = u0Values ./ sqrt(alphas');
clear alphas;

% temp stuff - simplifying radically to hopefullysee problem
angles = TurbineStruct.giCd.GridVectors{2};
alphas = MTMC.fnCalcCorrections( 0, modeNumLayersIntersected, CtValues, meanElementCSA, TurbineStruct.Diameter / 2 );
CtpValues = CtValues .* alphas;
giCtp = griddedInterpolant( {u_cellValues, angles}, CtpValues, 'linear', 'nearest' );


% end temp stuff
% 
% %we'll now form a griddedInterpolant of u_cell vs Ct using spline interpolation, which
% %should give us more accurate intermediate values than linear would.
% angles = TurbineStruct.giCd.GridVectors{2};
% 
% giIntermediate = griddedInterpolant( {u_cellValues, angles}, TurbineStruct.giCd.Values, 'spline', 'nearest' );
% 
% % MIKE doesn't do fancy interpolation, it always does linear, so we may
% % want to produce a Ctp table with more rows than the Ct table did to
% % improve accuracy. To allow for this, we *now* produce our actual table
% % from giIntermediate and calculate the Ctp values on this.
% 
% NumCtpSpeeds = length(giIntermediate.GridVectors{1}) * RefineFactor;
% MinCtSpeed = giIntermediate.GridVectors{1}(1);
% MaxCtSpeed = giIntermediate.GridVectors{1}(end);
% CtpTableSpeeds = linspace(MinCtSpeed, MaxCtSpeed, NumCtpSpeeds);
% 
% CtsToCorrect = giIntermediate({CtpTableSpeeds, angles});
% 
% alphas = MTMC.fnCalcCorrections( 0, modeNumLayersIntersected, CtsToCorrect, meanElementCSA, TurbineStruct.Diameter / 2 );
% CtpValues = CtsToCorrect .* alphas;
% 
% % so we now know the u_cell values and the Ct-prime values for our new
% % table. We'll put that into a griddedInterpolant that uses linear
% % interpolation, the same way as MIKE.
% giCtp = griddedInterpolant( {u_cellValues, angles}, CtpValues, 'linear', 'nearest' );

end

