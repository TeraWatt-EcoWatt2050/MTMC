function [ caLines ] = fnExtractM3FMSection( inputname, section_name, multiple )
%FNEXTRACTM3FMSECTION Read a specified section of a .m3fm (or similar) file.
%   These are the model definition files for MIKE3 by DHI models. This will
%   probably also work for MIKE21 files and MIKE21/3 coupled files, but has
%   not been tested with them.
%   Inputs: inputname is a char with the path and filename of the file to
%           read, *OR* an existing nx1 cell array of lines from
%           which a subsection should be extracted.
%           section_name is a char with the name of the section to extract, not
%           including the square brackets. Case-sensitive (should be all caps).
%           multiple - optional: If this flag is set to 'multiple' then instead
%           of giving an error when there are multiple sections with the
%           same name, the function will create a multi-column cell array
%           with one section per column.
%   Output: caLines is a column (nx1) cell array where each cell contains
%           one line from the section. The section opening and closing
%           lines will not be included. If the "multiple" keyword is used,
%           it will be a nxm cell array, where m is the number of sections
%           with the right name.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

if nargin < 2
    error('Not enough arguments.');
end
if ~ischar(section_name)
    error('section_name must be a char.');
end

if nargin == 3
    multiflag = (strcmp(multiple, 'multiple'));
else
    multiflag = false;
end

if iscell(inputname)        %it's a cell array
    caFile = inputname;
    
elseif exist(inputname) == 2    %it's a normal file, not a folder or anything special
    %Read the whole file
    FID = fopen(inputname, 'r');
    if FID == -1
        error('Failed to open file to read');
    end
    tmp = textscan(FID, '%s', 'Delimiter', '\n'); %this gives us a 1x1 cell with a cell array inside it. The inner one is what we want.
    caFile = tmp{1};    % so here's the inner one extracted.
    clear tmp;
    fclose(FID);
    
else
    error('Inputname does not appear to be a cell array or a filename that exists.');
    
end

%find the start and end of the section we want.
StartLine = find(strcmp([ '[' section_name ']' ], caFile));    %NB case-sensitive
if isempty(StartLine)    %section wasn't found.
    error('Section not found');
elseif length(StartLine) > 1 && ~multiflag;
    error('Multiple sections with desired name, no multiple flag set.');
end

EndLine = find(strcmp([ 'EndSect  // ' section_name ], caFile));
if isempty(EndLine)    %section end wasn't found.
    error('Section end not found');
elseif length(EndLine) > 1 && ~multiflag;
    error('Multiple section ends with desired name, no multiple flag set.');
end

if length(StartLine) ~= length(EndLine)
    error('Number of starts and ends of sections with this name do not match.');
end

% return the lines between these points
MaxLines = max(EndLine - StartLine - 1);    % -1 to allow for not including header
caLines = cell(MaxLines, length(StartLine));
for col = 1:length(StartLine)
    rows = EndLine(col) - StartLine(col) - 1;   % number of rows in this section. -1 to allow for not including header.
    caLines(1:rows,col) = caFile((StartLine(col) + 1):(EndLine(col) - 1));    %+1/-1 to remove the section delimiters.
end

end

