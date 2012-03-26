function x2 = projectXtoLine(x1,l1)
%Project x1 to line l1 such that the resulting x2 is the closest point on
%l1 to x1.
%
%Inputs:
%      x1 - Homogenous 2D points 3xn matrix
%      l1 - Implicit lines 3xn matrix
%
%Outputs:
%      x2 - Homogenous 2D points 3xn matrix
%
%Matti Jukola: 2012-03-26

%Rotate line 90 deg
l2 = makeLinePerpendicular(l1);
%Make them go trough x1
l2 = makeLineGoTroughPoint(l2,x1);
%Calculate intersencion between l1 and l2
x2 = lineintersect(l1,l2);