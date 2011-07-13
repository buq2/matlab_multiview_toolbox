function P = constructP(t,r,xy,a,s)
%t = [x y z] (transform)
%r = [rx ry rz]
%xy = [x y] (principal point)
%a = [ax ay] or [a] (scale parameters / focal length)
%s = [s] (skew)
%
%HZ2 6.1 and 6.2 pp.155-161
%MASKS 3.3.1 and 3.3.2 pp.52-57
%
%Matti Jukola 2010
if nargin < 1; t = [0 0 0]; end
if nargin < 2; r = [0 0 0]; end
if nargin < 3; xy = [100 100]; end
if nargin < 4; a = [1 1]; end
if nargin < 5; s = 0; end;
if numel(a) == 1
    a = [a a];
end
K =[a(1)  s     xy(1);...
    0     a(2)  xy(2);...
    0     0     1   ];
%Rx = eye(3); Rx(2:3,2:3) = [cos(r(1)) -sin(r(1));sin(r(1)) cos(r(1))];
%Ry = eye(3); Ry(1,1) = cos(r(2)); Ry(1,3) = sin(r(1)); Ry(3,1) = -sin(r(1)); Ry(end) = cos(r(1));
%Rz = eye(3); Rz(1:2,1:2) = [cos(r(3)) -sin(r(3));sin(r(3)) cos(r(3))];
%R = Rx*Ry*Rz;
R = rodrigues(r);
Rt = [R t(:)];
P = K*Rt;