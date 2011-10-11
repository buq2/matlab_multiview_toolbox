function pi = makePlaneFromX(X1,X2,X3)
%Create planes pi from three points X1, X2 and X3 which are on the plane
%
%Inputs:
%      X1, X2, X3 - Points on the plane pi. 4xn where n is number of planes
%
%Outpus:
%      pi - Plane. 4xn. pi(1)*x+pi(2)*y+pi(3)*z+pi(4) = 0
%
%HZ2 3.2 (3.3) p. 66
%
%Matti Jukola 2011.10.11

if size(X1,1) ~= 4 || size(X2,1) ~= 4 || size(X3,1) ~= 4
    error('Points X1, X2 and X3 should be homogenous 3D coordinates')
end

pi = zeros(4,size(X1,2));

for ii = 1:size(pi,2)
    mat = [X1(:,ii)';
           X2(:,ii)';
           X3(:,ii)'];
    pi(:,ii) = null(mat);
end