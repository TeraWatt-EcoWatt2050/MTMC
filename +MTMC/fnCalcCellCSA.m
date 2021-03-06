function [ CSA ] = fnCalcCellCSA( trMesh, ElementNo, CurrentDir, deltaZ )
%FNCALCCELLCSA Calculates the cross-sectional area of a mesh cell 
%              on a plane passing through the centroid of the triangle and
%              perpendicular to CurrentDir. Also returns the bathymetry for the cell and
%              the vertical height of a sigma layer.
%               Requires Mapping Toolbox due to use of polyxpoly function.
%
% Inputs:   trMesh: Triangulation object containing the model mesh
%           ElementNo: Element number (in trMesh) to consider
%           CurrentDir: Direction that the current is flowing *towards*,
%                       in radians clockwise from north.
%           deltaZ: Height of vertical layers. Assumes equally spaced layers.
% Outputs:  CSA: Nominal cross-sectional area, in m^2.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

% get coordinates of the corners of the element

vertices = trMesh.ConnectivityList(ElementNo,:);
vX = trMesh.Points(vertices, 1);
vY = trMesh.Points(vertices, 2);
%  vZ = trMesh.Points(vertices, 3); not actually using this!
clear vertices;


%% %% method using width at the centroid

% % find the coordinates of the centroid by taking the mean of the vertices
% cx = mean(vX);
% cy = mean(vY);
% 

% % find the gradient of the line that we want, perpendicular to CurrentDir
% g = 1/tan(CurrentDir + pi/2);  %1 over tan because we're measuring from north, not from "east".
% if abs(g) > 1e6 %if CUrrentDir was -pi/2 or pi/2, then g is inf. That causes problems later, so set it to a  big number instead.
%     g = 1e6;    % that's quite big for the gradient of a line. *Really* big (~realmax()) values cause trouble later.
% end
% 
% % so y = gx + c. Let's find c, using the point on this line that we know.
% c = cy - (g*cx);
% 
% % We can use this to find a couple of points on this line
% % well beyond the mesh element
% lineX = [(cx - 100000) (cx + 100000)]; % This should get us well outside the element edges.
% lineY = lineX .* g + c;
% 
% % now find the points where this line intersects the edges of the triangle.
% % Call these points int. This bit is the reason that we require the
% % mapping toolbox.
% % We need to add an extra row to vX, vY, so that it describes a closed
% % polygon and so the line can intersect any edge of the triangle.
% vX(end+1) = vX(1);
% vY(end+1) = vY(1);
% [intX, intY] = polyxpoly(vX, vY, lineX, lineY);
% 
% % The length of the line between the two int points will give us the
% % "width" of the mesh element.
% width = sqrt((diff(intX))^2 + (diff(intY))^2);
% 
% % We assume that the depth of the cell is z-coordinate for our calculated
% % centroid. FIXME could interpolate better, but more importantly could take
% % account of changing water level! At present this is for MSL.
% depth = -cz;  % negative because cz was an elevation rather than a depth, thus itself negative
% deltaZ = depth / NumLayers;  
% CSA = deltaZ * width;
% 


%% %% method calculating area using Heron's Formula and then dividing it by the distance between the extremes of the vertices when projected onto a line parallel to the current direction (and then rooted)
% 
% % we need to add an extra row to vX and vY, to close the triangle. 
% vX(end+1) = vX(1);
% vY(end+1) = vY(1);
% 
% %first, find the length of each side of the triangle, by pythagoras
% sl = sqrt(diff(vX).^2 + diff(vY).^2);  %this will give a 3x1 matrix of lengths.
% % find half of the perimeter
% sp = sum(sl) / 2;
% %Heron's formula for area of a triangle
% TriangleArea = sqrt( sp * (sp - sl(1)) * (sp - sl(2)) * (sp - sl(3)));
% 
% % projection onto a line based on https://en.wikibooks.org/wiki/Linear_Algebra/Orthogonal_Projection_Onto_a_Line
% % gradient of line of current direction
% g = 1/tan(CurrentDir);
% if abs(g) > 1e6 %if CUrrentDir was -pi/2 or pi/2, then g is inf. That causes problems later, so set it to a  big number instead.
%     g = 1e6;    % that's quite big for the gradient of a line. *Really* big (~realmax()) values cause trouble later.
% end
% c = cy - (g*cx);    %now we have eqn of the line
% 
% % let s be a vector parallel to the current direction
% s = [1; g];
% % let vv be a matrix whose columns are vectors from the origin to each
% % vertex
% vv(1,:) = vX(1:3);  % 1:3 because we created that duplicate 4th row earlier.
% vv(2,:) = vY(1:3);
% 
% for a = 1:3 %loop over vertices
%     vproj(:,a) = ( dot(vv(:,a), s) / dot(s, s) ) * s;
% end
% 
% %now need to find the maximum distance between any of these projected
% %points. With 3 vertices, there are 3 combinations (3Comb2). We'll use
% %nchoosek to work this out, though it's trivial, because it's neat :-)
% 
% combs = nchoosek(1:3,2);
% for a = 1:length(combs)
%     difference = vproj(:,combs(a,1)) - vproj(:,combs(a,2));
%     dist(a) = norm(difference); %norm gives us the magnitude
% end
% 
% TriangleLength = max(dist);
% 
% % We have the area and the "length", so the "width" must be,
% TriangleWidth = (TriangleArea / TriangleLength);
% 
% depth = -cz;  % negative because cz was an elevation rather than a depth, thus itself negative
% deltaZ = depth / NumLayers;  
% CSA = deltaZ * TriangleWidth;

% %% method averaging width measured by 100 lines normal to the flow, throughout the triangle.
% %(Method 4)
% 
% NumLines = 100;  % number of places through triangle to average.
% 
% % we need to add an extra row to vX and vY, to close the triangle, so we
% % can treat it as a polygon later.
% vX(end+1) = vX(1);
% vY(end+1) = vY(1);
% 
% % to make this comprehensible by somebody of little brain such as myself,
% % we'll rotate the vertices such that the flow is parallel to the y axis.
% 
% % find the gradient of a line perpendicular to the flow
% g = tan(CurrentDir);
% if abs(g) > 1e6 %if CurrentDir was -pi/2 or pi/2, then g is inf. That causes problems later, so set it to a  big number instead.
%     g = 1e6;    % that's quite big for the gradient of a line. *Really* big (~realmax()) values cause trouble later.
% end
% 
% R = [ cos(CurrentDir) -sin(CurrentDir); sin(CurrentDir) cos(CurrentDir) ]; %rotating matrix
% 
% % let vv be a matrix whose columns are vectors from the origin to each
% % vertex
% vv(1,:) = vX;
% vv(2,:) = vY;
% 
% vvR = R * vv;
% 
% %find the extremes of the new coordinates
% minXR = min(vvR(1,:));
% maxXR = max(vvR(1,:));
% minYR = min(vvR(2,:));
% maxYR = max(vvR(2,:));
% 
% % matrices for coords of lines to use; Row 1 is start coords, row 2 is end.
% LineCoordsXR = nan(2,NumLines);
% LineCoordsYR = nan(2,NumLines);
% 
% %divide up the y-extents into the right number of steps
% LineCoordsYR(1,:) = linspace(minYR, maxYR, NumLines);
% LineCoordsYR(2,:) = LineCoordsYR(1,:);
% 
% %initially, set the x coords at the furthest extents of the triangle
% LineCoordsXR(1,:) = minXR;
% LineCoordsXR(2,:) = maxXR;
% 
% %find the intersections between these lines and the (rotated) triangle
% intXR = nan(2,NumLines);
% intYR = nan(2,NumLines);
% for n = 1:NumLines
%     [intXR(:,n), intYR(:,n)] = polyxpoly(vvR(1,:), vvR(2,:), LineCoordsXR(:,n), LineCoordsYR(:,n)); %we know what intYR will be, but hey
% end
% 
% %find the mean lenght of line inside the triangle. We know the lines align
% %with the x-axes, so can just use one dimension. The first and last lines
% %will always have length zero (they are at vertices), and these will have
% %no effect on the model, so exclude these. abs is needed because diff()
% %makes things negative in rather odd circumstances.
% 
% TriangleWidth = mean(abs(diff(intXR(:,2:end-1),1)));
% depth = -cz;  % negative because cz was an elevation rather than a depth, thus itself negative
% deltaZ = depth / NumLayers;  
% CSA = deltaZ * TriangleWidth;

%% method weighted averaging width measured by 100 lines normal to the flow, throughout the triangle, weighting each line by its own length
%(Method 5)

NumLines = 100;  % number of places through triangle to average.

% we need to add an extra row to vX and vY, to close the triangle, so we
% can treat it as a polygon later.
vX(end+1) = vX(1);
vY(end+1) = vY(1);

% to make this comprehensible by somebody of little brain such as myself,
% we'll rotate the vertices such that the flow is parallel to the y axis.

R = [ cos(CurrentDir) -sin(CurrentDir); sin(CurrentDir) cos(CurrentDir) ]; %rotating matrix

% let vv be a matrix whose columns are vectors from the origin to each
% vertex
vv(1,:) = vX;
vv(2,:) = vY;

vvR = R * vv;

%find the extremes of the new coordinates
minXR = min(vvR(1,:));
maxXR = max(vvR(1,:));
minYR = min(vvR(2,:));
maxYR = max(vvR(2,:));

% matrices for coords of lines to use; Row 1 is start coords, row 2 is end.
LineCoordsXR = nan(2,NumLines);
LineCoordsYR = nan(2,NumLines);

%divide up the y-extents into the right number of steps
LineCoordsYR(1,:) = linspace(minYR, maxYR, NumLines);
LineCoordsYR(2,:) = LineCoordsYR(1,:);

%initially, set the x coords at the furthest extents of the triangle
LineCoordsXR(1,:) = minXR;
LineCoordsXR(2,:) = maxXR;

%find the intersections between these lines and the (rotated) triangle
intXR = nan(2,NumLines);
intYR = nan(2,NumLines);
for n = 1:NumLines
    [intXR(:,n), intYR(:,n)] = polyxpoly(vvR(1,:), vvR(2,:), LineCoordsXR(:,n), LineCoordsYR(:,n)); %we know what intYR will be, but hey
end

%find the lengths of the lines. abs is needed because diff()
%makes things negative in rather odd circumstances.
LineLengths = abs(diff(intXR,1));

%Now the weighted mean, where the weights are the lengths themselves
TriangleWidth = sum(LineLengths.^2) / sum(LineLengths);

CSA = deltaZ * TriangleWidth;


end

