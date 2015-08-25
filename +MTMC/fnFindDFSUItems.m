function [ OutputMap ] = fnFindDFSUItems( dfsu, ItemNames )
%fnFindDFSUItems Finds item numbers in a MIKE DFSU file
%   dfsu should be a .NET object referring to a MIKE by DHI dfsu file.
%   ItemNames (optional) may be a cell array containing the names of the items that
%   are desired.
%   If ItemNames is not supplied, then a container.map of all items will be
%   returned.
%    FIXME allow a string rather than a cell array if only one item OutputMap will be a
%   containers.Map object where item names are the keys and item numbers
%   are the values. If ItemNumber is NaN, that item name wasn't found.
%   e.g. to access the item number for U velocity, use OutputMap('U
%   velocity').

% Obviously, this will only work on a PC with MIKE by DHI installed. But
% you won't be able to create the dfsu object without that anyway.

% Function by Simon Waldman, Oct 2014.

if (nargin < 1)
    error('Missing arguments');
end
if (nargin > 2)
    error('Too many arguments');
end
% if ~isa(dfsu, 'DHI.Generic.MikeZero.DFS.dfsu.DfsuFile')
%     error('First input variable does not appear to be a MIKE dfsu.');
% end
%commented out the above as it works perfectly well for dfs1,2,3 as well,
%and I can'be arsed checking for all.
if nargin==2 && ~isa(ItemNames, 'cell')
    error('Second input variable does not appear to be a cell array.');
end
if nargin==2 && length(ItemNames) < 1
    error('Second input variable is empty cell array.');
end

% loop through each item in the dfsu. Within that, loop through each name
% that we're looking for, and compare.
switch nargin
    
    case 1  %if we're getting all items
        ItemNames = cell(1,dfsu.ItemInfo.Count);
        ItemNumbers = nan(1,dfsu.ItemInfo.Count);
        for i=0:(dfsu.ItemInfo.Count - 1)
            ItemNames(i+1) = { char(dfsu.ItemInfo.Item(i).Name) };
            ItemNumbers(i+1) = i+1;  % the +1 is because the functions for reading dfsus start their indexing at 1, wheras the stuff here starts it at 0.
        end
        
    case 2  %if there are particular items to search for
        ItemNumbers = nan(1,length(ItemNames));
        for i=0:(dfsu.ItemInfo.Count - 1)
            for c = 1:length(ItemNames)
                if (dfsu.ItemInfo.Item(i).Name == ItemNames{c})
                    ItemNumbers(c) = i + 1;    % the +1 is because the functions for reading dfsus start their indexing at 1, wheras the stuff here starts it at 0.
                end
            end
        end
        end

% if any WorkingStruct.ItemNumber values are NaN, that means we're missing a
% value. Return it as such.

OutputMap = containers.Map(ItemNames,ItemNumbers);      %to return

end

