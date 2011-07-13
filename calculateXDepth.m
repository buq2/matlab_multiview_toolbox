function depth = calculateXDepth(P,X)
%Calculates depth of point X ([X Y Z T]) in front of the pricipal plane of
%the camera. Depth will be negative if point is behind the camera.
%
%X can be 4xn
%
%HZ2 6.2.3 and Result 6.1 pp.162-163
%
%Matti Jukola 2010.12.24

warning('Not tested')

M = P(1:3,1:3);
T = X(4,:);
x = P*X;
w = x(3,:);
%depth = sign(det(M)).*w./(T.*norm(M(:,3)));
depth = sign(det(M)).*w./(T.*norm(M(3,:)));