function l2 = makeLinePerpendicular(l1)
%Creates new line 'l2' which is perpendicular to line 'l1'.
%
%Inputs:
%      l1  - Implicit lines 3xn array (l = [a b c]', a*x + b*y + c = 0)
%Outputs:
%      l2  - Implicit line perpendicular to 'l1' suvh that dot(l1,l2) = 0
%
%NOTE: The point in which the lines cross is not defined. Use function 
%      makeLineGoTroughPoint to force the output lines to travel trough
%      certain points in space.
%
%Matti Jukola: 2012-03-26

%Constraints
%cross(l1,l2) ~= zeros(3,1) (output lines not on top of each other)
%cross(l1,l2) does not have zero last coordinate (lines not parallel)
%l2 ~= zeros(3,1)
%dot(l1,l2) = 0

%For points x1 on the line
%dot(l1,x1) = 0
%or
%l1'*x1 = 0
%Now if we rotate the points 90 deg and compare them to l2
%l2'*R*x2 = 0
%So we simply multiply l1 with 90 degree rotation matrix from the right

%[cos(pi/2) sin(pi/2);-sin(pi/2) cos(pi/2)]
%== [0 1 0;
%   -1 0 0;
%    0 0 1]

if size(l1,1) ~= 3
    error('This function expects line to be implicit and in 3xn matrix')
end

%(Rotate points 90 degrees)
l2 = l1([2 1 3],:);
l2(1,:) = -l2(1,:);