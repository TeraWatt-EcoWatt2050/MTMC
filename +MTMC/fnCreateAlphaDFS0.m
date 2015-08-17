function [ ] = fnCreateAlphaDFS0( Turbines, filename, NumTSs, TSLength, StartTime, IterationNo )
%FNCREATEALPHADFS0 Creates .dfs0 file with correction factors ("alpha") for
%turbines. It will have many Items, each a time series of alpha values.
%Item number should correspond to turbine number. Requires the DHI Matlab
%toolbox.
%   Inputs: Turbines is the Turbines struct used elsewhere.
%           filename is a char with the path/filename of the dfs0 to
%           create. If the file already exists, it will be overwritten.
%           IterationNo is scalar.
%           NumTSs is obvious.
%           TSLength is timestep length in seconds.
%           StartTime is the time of the first timestep in datevec format.
%   Output: No output. If it fails there should be errors.
%
% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

if nargin < 5
    error('Not enough arguments.');
end
if ~ischar(filename)
    error('filename nust be a char.');
    %FIXME test whether valid filename? Is there a fn for this?
end
if exist(filename, 'file')
    error('File already exists.');
end

%create the dfs0 object
dfs0 = dfsTSO(filename, 1); % the '1' indicates it should create a new one.

%set up time axis
set(dfs0,'timeaxistype','Equidistant_Calendar');
set(dfs0,'startdate', StartTime );
set(dfs0, 'timestep', [ 0 0 0 0 0 TSLength] );
addTimesteps(dfs0, NumTSs);

%create and fill a data Item for each turbine
for t = 1:length(Turbines)
    addItem(dfs0,[ 'Turbine ' num2str(t) ' correction factor' ],'Dimensionless factor','()');
    dfs0(t) = single(Turbines(t).Alpha(:,IterationNo)); %put all timesteps into this item number in the dfs0. Apparently dfs0 files are single precision?
end


%write the file to disc and close it.
save(dfs0);
close(dfs0);

end

