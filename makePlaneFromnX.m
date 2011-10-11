function pi = makePlaneFromnX(n,X)
%Create planes from normal vectors and points on the plane
%
%Inputs:
%      n - Normal vectors of of the planes 4xn_ where n_ is number of
%           planes/normal vectors
%      X - Points on the plane corresponding to normal vectors n. 4xn_
%
%Outputs:
%      pi - Planes defined by n and X. pi(1)*x+pi(2)*y+pi(3)*z+pi(4) = 0
%
%http://en.wikipedia.org/wiki/Plane_(geometry)#Definition_with_a_point_and_a_normal_vector
%n(1)*(x-x(1))+n(2)*(y-x(2))+n(3)*(z-n(3)) = 0
%
%Matti Jukola 2011.10.11

if size(X,1) ~= 4 || size(n,1) ~= 4
    error('Points X, and normal vectors n should be homogenous 3D coordinates')
end

X = wnorm(X);
pi = wnorm(n);

pi(4,:) = -sum(X(1:3,:).*pi(1:3,:));