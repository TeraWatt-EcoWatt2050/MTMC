function [ OutputValue ] = fnReadDHIValue( caLines, key )
%FNREADDHIVALUE Takes a cell array of lines from a DHI config file and
%   returns the value corresponding to a particular key.
%   Inputs: caLines is a cell array of lines in the file.
%           key is a char of the key to look for.
%   Outputs: OutputValue is the requested value. It may be empty either if
%              the key was not found, or if the value is blank.

%FIXME: Future: Allow key to be a cell array of desired keys, with a cell
%array of values returned.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

if nargin < 2
    error('Not enough arguments.');
end
if ~iscell(caLines)
    error('caLines must be a cell array');
end
if ~ischar(key)
    error('key must be a char');
end

expression = [ key '\s+=\s+(.+)' ]; %search for the key followed by space(s), =, space(s), and grab anything after that.
caOut = regexp(caLines, expression, 'tokens');   %this will give us a cell array of matches, one per item in caLines.
line = find(~cellfun(@isempty, caOut)); % gives us the index of a non-empty cell. NB more than one match = more than one answer.
if length(line) > 1
    error('More than one match');   % FIXME should do something more useful/intelligent here. Will need to think about it.
end

% catch case where the line isn't there:
if isempty(line)
    OutputValue = [];
    return;
end

% even once we've found the right line, we'll find that caOut{line}
% contains another 1x1 cell array (presumably in case more than one regexp
% match, which shouldn't happen with the way we're doing things), containing
% *another* 1x1 cell array (god knows why). So,

OutputValue = caOut{line}{1}{1};


end

