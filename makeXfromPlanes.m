function X = makePlaneFromX(pi1,pi2,pi3)
%Create planes pi from three planes pi1, pi2, pi3 which intersect at point
%X
%
%Inputs:
%      pi1, pi2, pi3 - Planes intersecting at X. 4xn where n is number of
%                      resulting intersection points
%
%Outpus:
%      X - Plane. 4xn. pi(1)*x+pi(2)*y+pi(3)*z+pi(4) = 0
%
%HZ2 3.2 (3.5) p. 67
%
%Matti Jukola 2011.10.11

%Exactly same algorithm as for defining plane from three points.
%Homogenous planes and points are duals in 3D.

if size(pi1,1) ~= 4 || size(pi2,1) ~= 4 || size(pi3,1) ~= 4
    error('Planes pi1, pi2 and pi3 should be homogenous 3D planes')
end

X = zeros(4,size(pi1,2));

for ii = 1:size(pi,2)
    mat = [pi1(:,ii)';
           pi2(:,ii)';
           pi3(:,ii)'];
    X(:,ii) = null(mat);
end