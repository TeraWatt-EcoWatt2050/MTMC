function [ retReplaced ] = fnReplaceM3FMSection( filename, section_name, caLines, multiple )
%FNREPLACEM3FMSECTION Find and replace a specified section in a .m3fm file.
%   Find and replace a specified section in a MIKE by DHI .m3fm file.
%   Inputs: filename is a char with the path & filename of the .m3fm file.
%   section_name is a char with the name of the section, not
%   including the square brackets. Case-sensitive (should be all caps).
%   caLines is a column (nx1) cell array containing the lines that the section should be
%   replaced with. These should not include the opening and closing of the
%   section.
%   multiple - optional: If this flag is set to 'multiple' then instead
%   of giving an error when there are multiple sections with the
%   same name, the function will expect a multi-column cell array
%   with one section per column. The order of columns will be the order in which they are replaced in the file..
%   Ouputs: retReplaced gives the number of sections replaced. If the
%   function failed (likely because it couldn't find the section) it will
%   be -1.
%   retEndLine gives the last line(s) of the new section.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

% read the file into memory as a cell array
FID = fopen(filename, 'r');
if FID == -1
    error('Failed to open file to read');
end
tmp = textscan(FID, '%s', 'Delimiter', '\n'); %this gives us a 1x1 cell with a cell array inside it. The inner one is what we want.
caFile = tmp{1};    % so here's the inner one extracted.
clear tmp;

fclose(FID);

NumSects = size(caLines, 2);    % how many columns in our input?
if NumSects > 1 & multiple ~= 'multiple'
    error('Multiple columns provided in caLines, but ''multiple'' flag not set.');
end

%find the start(s) and end(s) of the section(s) we want.
OrigStartLine = find(strcmp([ '[' section_name ']' ], caFile));    %NB case-sensitive
if isempty(OrigStartLine)    %section wasn't found.
    retReplaced = -1;
    return;
elseif length(OrigStartLine) ~= NumSects
    error('Number of sections in the file with section_name does not match number of columns passed in caLines.');
end

OrigEndLine = find(strcmp([ 'EndSect  // ' section_name ], caFile));
if isempty(OrigEndLine)    %section end wasn't found.
    error('Section end not found');
elseif length(OrigEndLine) ~= NumSects
    error('Number of section ends in the file with section_name does not match number of section starts.');
end

% replace the old with the new section(s) in a new file. If multiple
% sections, we need to work from the end backwards, in order to preserve
% line numbers for the later substitutions.
caNewFile = caFile;
for n = NumSects:-1:1
    caNewFile = [ caNewFile(1:OrigStartLine(n)); caLines(:,n); caNewFile(OrigEndLine(n):end) ];
end

% write the revised file
FID = fopen(filename, 'w');
if FID == -1
    error('Failed to open file to write');
end

fprintf(FID, '%s\n', caNewFile{:});

fclose(FID);

retReplaced = NumSects;

end

