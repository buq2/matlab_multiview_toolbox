function [Q H P f] = makeQAutoCalib2(P)
%This algorithm calculates Q (absolute quadric) and updates Ps (projection
%matrices) using updating 4x4 homography H when cameras P have been
%calibrated, but focal length has been changed (for each camera matrix P).
%
%When to use this function:
%Internal parameters K are partially know for cameras P, only focal length
%f is unknown (each camera has different f). Cameras P are already 
%calibrated using partially incorrect matrix K. 
%This function calculates focal lengths for each camera and
%updates camera matrices P using updating homograpy H.
%
%P is cell containing all P matrices
%Yi Ma et. al. An Invitation to 3-D Vision p. 401
%
%Matti Jukola 2010

warning('Untested');

%2) and 3) Construct matrix X and vector b
X = zeros(numel(P)*4,5);
b = zeros(numel(P)*4,1);
for ii = 1:numel(P)
   u = P{ii}(1,:);
   v = P{ii}(2,:);
   w = P{ii}(3,:);
   X((ii-1)*4+1:ii*4,:) = [...
       u(1)^2+u(2)^2-v(1)^2-v(2)^2,    2*u(4)*u(1)-2*v(1)*v(4),     2*u(4)*u(2)-2*v(2)*v(4),    2*u(4)*u(3)-2*v(3)*v(4)    u(4)^2-v(4)^2;...
       u(1)*v(1)+u(2)*v(2),            u(4)*v(1)+u(1)*v(4),         u(4)*v(2)+u(2)*v(4),        u(4)*v(3)+u(3)*v(4),       u(4)*v(4);...
       u(1)*w(1)+u(2)*w(2),            u(4)*w(1)+u(1)*w(4),         u(4)*w(2)+u(2)*w(4),        u(4)*w(3)+u(3)*w(4),       u(4)*w(4);...
       v(1)*w(1)+v(2)*w(2),            v(4)*w(1)+v(1)*w(4),         v(4)*w(2)+v(2)*w(4),        v(4)*w(3)+v(3)*w(4),       v(4)*w(4)];
   b((ii-1)*4+1:ii*4) = [-u(3)^2+v(3)^2,      -u(3)*v(3),      -u(3)*w(3),     -v(3)*w(3)];
end

%4) Solve Qs
Qs = pinv(X)*b;

%5) Unstack Qs to Q_
Q_ = [Qs(1) 0 0 Qs(2); 0 Qs(1) 0 Qs(3);0 0 1 Qs(4);Qs(2:end)'];

%6) Enforce the rank-3 constraint on Q_
[U S V] = svd(Q_);
S(end) = 0;
Q = U*S*V';

%7) Calculate new focal lengths
f = zeros(size(P));
for ii = 1:numel(f)
   tmp = P{ii}*Q*P{ii}.';
   f(ii) = sqrt(tmp(1));
end

%8)
K1 = [sqrt(Qs(1)) 0 0; 0 sqrt(Qs(1)) 0; 0 0 1];
v = -[Qs(2)/Qs(1) Qs(3)/Qs(1) Qs(4)]';
H = [K1 zeros(3,1);-v'*K1 1];
if nargout > 1
   for ii = 1:numel(P)
      P{ii} = P{ii}*H; 
   end
end