function x1 = lineintersect(l1,l2)
%Calculates 2D lineintersection between two sets of lines, l1 and l2
%
%Inputs:
%      l1  - Implicit lines 3xn array (l = [a b c]', a*x + b*y + c = 0)
%      l2  - Implicit lines 3xn array
%
%Outputs:
%      x1 - Homogenous 2D points in 3xn array
%
%Matti Jukola: 2012-03-26

if size(l1,1) ~= 3 || size(l2,1) ~= 3
    error('Lines l1 and l2 must be in a 3xn array')
end

if size(l1,2) == 1
    %Only one l1 line
    x1 = zeros(size(l2));
    for ii = 1:size(x1,2)
        x1(:,ii) = cross(l1,l2(:,ii));
    end
elseif size(l2,2) == 1
    %Only one l2 line
    x1 = zeros(size(l1));
    for ii = 1:size(x1,2)
        x1(:,ii) = cross(l1(:,ii),l2);
    end
elseif all(size(l2) == size(l1))
    %Same number of lines
    x1 = zeros(size(l1));
    for ii = 1:size(x1,2)
        x1(:,ii) = cross(l1(:,ii),l2(:,ii));
    end
else
    error('Input argument sizes do not match')
end