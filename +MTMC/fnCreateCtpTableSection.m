function [ OutputCA ] = fnCreateCtpTableSection( giCtp )
%FNCREATECTPTABLESECTION Create a "TABLE" Section for a MIKE input file

%   Inputs:     giCtp:  griddedInterpolant object for Ct-prime.

%   Outputs:    OutputCA: nx1 cell array, giving the lines for this section
%                           as rows

% Copyright (C) 2016 Simon Waldman / Heriot-Watt University

assert(nargin==1, 'Incorrect number of arguments.');
assert( isa( giCtp, 'griddedInterpolant' ), 'Argument giCtp must be a griddedInterpolant object.' );

CA = {}; %initialise cell array

function fnAL(line) %the function adds the given line to CA.
    CA = [ CA; {line} ];
end

% how many speeds?
NumAngles = length(giCtp.GridVectors{2});
MinAngle = giCtp.GridVectors{2}(1);
MaxAngle = giCtp.GridVectors{2}(end);
NumSpeeds = length(giCtp.GridVectors{1});
MinSpeed = giCtp.GridVectors{1}(1);
MaxSpeed = giCtp.GridVectors{1}(end);

fnAL( [ '   number_of_directions = ' num2str( NumAngles ) ] );
fnAL( [ '   minimum_direction = ' num2str( radtodeg(MinAngle) ) ] );
fnAL( [ '   maximum_direction = ' num2str( radtodeg(MaxAngle) ) ] );
fnAL( [ '   number_of_speeds = ' num2str( NumSpeeds ) ] );
fnAL( [ '   minimum_speed = ' num2str( MinSpeed ) ] );
fnAL( [ '   maximum_speed = ' num2str( MaxSpeed ) ] );

% produce the actual table.
SpeedsToCalc = linspace(MinSpeed, MaxSpeed, NumSpeeds);
AnglesToCalc = linspace(MinAngle, MaxAngle, NumAngles);
ToCalc = giCtp( { SpeedsToCalc, AnglesToCalc } );

for a = 1:NumSpeeds
    tmp = sprintf( '   cd_%i =', a );
    for b = 1:NumAngles-1
      tmp = [ tmp sprintf( ' %6.4f,', ToCalc(a,b) ) ];
    end
    tmp = [ tmp sprintf( ' %6.4f', ToCalc(a, end) ) ];
    %this way we don't get a comma at the end of the line.
    fnAL( tmp );
end

%FIXME Cl table will just be populated with zeroes for now.
for a = 1:NumSpeeds
    tmp = sprintf( '   cl_%i =', a );
    for b = 1:NumAngles-1
        tmp = [ tmp sprintf( ' %6.4f,', 0 ) ];
    end
    tmp = [ tmp sprintf( ' %6.4f', 0 ) ];
    fnAL( tmp );
end

OutputCA = CA;

end

