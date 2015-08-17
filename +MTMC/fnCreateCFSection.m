function [ outputCA ] = fnCreateCFSection( Alphadfs0Filename, TurbineNo )

%FNCREATECFSECTION Create a Correction Factor MIKE model file section
%   Inputs: Alphadfs0Filename = filename for the dfs0 file with
%                   time-varying correction factors. Item number should
%                   correspond to turbine number.
%           TurbineNo = Turbine number for this section.
%
%   Outputs: outputCA = 11x1 cell array, giving the lines for this section
%                   as rows.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

CA = {}; %initialise cell array

%I don't like nested functions fiddling with variables in their parents'
%scope, but here it does save a lot of typing.
    function fnAL(line) %the function adds the given line to CA.
        CA = [ CA; {line} ];
    end

fnAL( '   Touched = 1' );
fnAL( '   type = 1' );
fnAL( '   format = 1' ); %this is what specifies the time-varying CF - NOT the next line...
fnAL( '   constant_value = 1' ); %does this do anything at all?

fnAL( [ '   file_name = |' Alphadfs0Filename '|' ] );
fnAL( [ '   item_number = ' num2str(TurbineNo) ] );
fnAL( [ '   item_name = ''Turbine ' num2str(TurbineNo) ' correction factor''' ] );
fnAL( '   type_of_sort_start = 2' );
fnAL( '   soft_time_interval = 0' );
fnAL( '   reference_value = 0' );
fnAL( '   type_of_time_interpolation = 1') ;

outputCA = CA;

end

