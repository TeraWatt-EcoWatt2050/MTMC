function [ output ] = fnMIKEReadElementAllTS( dfsu, item, StartElementNo, StartTS, EndTS )
%FNMIKEREADELEMENTALLTS Reads all timesteps for a given point from a dfsu
% Requires the DHI Toolbox, and requires that either MIKE Zero or the MIKE 
% SDK be installed.
% The function will extract all time steps for a given mesh element from a
% MIKE unstructured dfsu output file. If the dfsu file is a 3D one, all
% layers for that horizontal element will be extracted.
%   Inputs: dfsu is a .NET object representing a dfsu file.
%           item is the item number to be extracted
%               NB item here is indexed from 1. BEWARE that if you've been
%               looking at iteminfo, that is indexed from 0, and you'll
%               need to add one to the item number. (but if you've used my FindDFSUItems
%               function, then the number should be correct). The Item may not be the
%               hidden "Z coordidate" value, as this operates differently
%               to other items because it is recorded for nodes rather than
%               elements. To read Z coordinates, use the similar function
%               fnMIKERealZCoords.
%           StartElementNo is an integer specifying a horizontally aligned series of elements 
%               to return the time series for. It should be equal to the
%               element number of the *first* element at this horizontal
%               location (which will be the bottom layer). StartElementNo
%               can be an array, in which case all of the listed horizontal
%               locations will be returned. This does not take
%               significantly longer, and so is much more efficient than calling 
%               this function many times, but there must be sufficient RAM
%               to hold the output matrix!
%           StartTS and EndTS (optional) specify the first and last time steps that
%               are wanted. If one of these is specified, then both must be
%               specified. If neither is specified then all timesteps will be 
%               returned.
%   Outputs:output is a matrix containing the desired item of dimensions
%               StartElementNo x layers x timesteps, where the bottom layer is
%               first (i.e. (:,1,:))
%
% Note that extracting a complete time series for a single point requires
% this function to read every point and discard all others. Consequently,
% it may be slow, and it must have sufficient RAM to hold a complete
% single-TS snapshot of the domain in memory in addition to the
% single-point time series.

%	Copyright(C): Simon Waldman / Heriot-Watt University, April 2015

assert( isa(dfsu, 'DHI.Generic.MikeZero.DFS.dfsu.DfsuFile'), 'First argument does not appear to be a MIKE dfsu object.');
assert( length(item) & floor(item) == item , 'Item must be a single positive integer.');
assert( all(StartElementNo > 0) && all(floor(StartElementNo)==StartElementNo), 'StartElementNos must consist only of positive integers.');
assert( all(StartElementNo <= dfsu.NumberOfElements), 'An element was requested whose number is greater than the number of elements in the file.');
assert( item <= dfsu.ItemInfo.Count, 'Item %i requested, but file only contains %i items. Check the comment at the start of this function about item indexing.', item, dfsu.ItemInfo.Count);

switch nargin
    case 3  % if no start and end timesteps are specified, set these to the first and last in the dfsu.
        StartTS = 1;    
        EndTS = double(dfsu.NumberOfTimeSteps);
    case 5  % if they are specified, do some sanity-checking on them.
        assert( length(StartTS) == 1 && StartTS > 0 && floor(StartTS)==StartTS, 'StartTS must be a single positive integer.');
        assert( length(EndTS) == 1 && EndTS > 0 && floor(EndTS)==EndTS, 'StartTS must be a single positive integer.');
        assert( EndTS >= StartTS, 'EndTS must be equal to or greater than StartTS!');
        assert( EndTS <= double(dfsu.NumberOfTimeSteps), 'EndTS is beyond the number of timesteps in the DFSU object.');
    otherwise
        error('fnMIKEReadElementAllTS expects either 3 or 5 arguments.');
end

NumTS = EndTS - StartTS;
NumPoints = length(StartElementNo);

NumLayers = single(dfsu.NumberOfLayers); 
if NumLayers == 0   %if it's a 2D file, it reports having zero layers rather than 1.
    NumLayers = 1;  % if we just change it to 1, then the rest of the logic here should work fine.
end

%check that StartElementNo is in the bottom layer
assert( all( mod( StartElementNo - 1, NumLayers ) == 0 ), 'StartElementNo does not appear to refer to an element in the bottom layer.');



% we can figure out the elements that we want because we know that all layers
% at a given horizontal point are in sequence
for e = 1:NumPoints
    ElementScope(e,:) = StartElementNo(e) : ( StartElementNo(e) + NumLayers -1 );  % -1 because it's NumLayers *including* StartElementNo.
end

TSOffset = StartTS - 1;
for ts = (StartTS):(EndTS)
    FullTS = double(dfsu.ReadItemTimeStep(item, ts - 1).Data); % timestep is indexed from zero when using ReadItemTimeStep. Item is indexed from 1, though....
    for e=1:NumPoints
        output(e,:,ts - TSOffset) = FullTS(ElementScope(e,:));
    end
    clear FullTS;    %throw away the data for other points.
end

% MIKE uses a "Magic number" to signify missing data. Check what this is,
% and replace any occurances in output with NaN.
NAValue = double(dfsu.DeleteValueFloat);
output(output==NAValue) = NaN;

end

